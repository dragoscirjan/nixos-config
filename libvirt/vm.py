#!/usr/bin/env python3
"""Safely launch libvirt VMs backed by physical disks."""

from __future__ import annotations

import argparse
from contextlib import contextmanager
import fcntl
import hashlib
import json
import os
from dataclasses import dataclass
from pathlib import Path
import socket
import stat
import subprocess
import sys
import tomllib
from typing import Any, Sequence
import uuid
import xml.etree.ElementTree as ET


LIBVIRT_URI = "qemu:///system"
UUID_NAMESPACE = uuid.UUID("d43fa9a9-00ad-4ee0-9bd6-4fb72b661482")


class VmError(RuntimeError):
    """Raised when a VM operation cannot be performed safely."""


@dataclass(frozen=True)
class VmConfig:
    """Configuration for one physical-disk VM."""

    name: str
    domain_name: str
    disk: Path
    memory_mib: int
    vcpus: int
    network: str
    machine: str
    disk_bus: str
    video: str


@dataclass(frozen=True)
class HostConfig:
    """VM and Ventoy configuration for one host."""

    hostname: str
    ventoy_label: str
    vms: dict[str, VmConfig]


@dataclass(frozen=True)
class UsbDevice:
    """Runtime address of a USB block device."""

    block_path: Path
    vendor_id: str
    product_id: str
    bus: int
    device: int
    description: str


def run_command(
    arguments: Sequence[str], *, check: bool = True
) -> subprocess.CompletedProcess[str]:
    """Run a command and convert failures to actionable errors."""
    try:
        result = subprocess.run(
            arguments,
            check=False,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError as error:
        raise VmError(f"Required command is not installed: {arguments[0]}") from error

    if check and result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise VmError(f"Command failed: {' '.join(arguments)}\n{detail}")
    return result


def _positive_int(value: Any, field: str) -> int:
    if not isinstance(value, int) or isinstance(value, bool) or value <= 0:
        raise VmError(f"{field} must be a positive integer")
    return value


def _nonempty_string(value: Any, field: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise VmError(f"{field} must be a non-empty string")
    return value.strip()


def load_config(config_path: Path, hostname: str) -> HostConfig:
    """Load and validate a host TOML file."""
    try:
        with config_path.open("rb") as config_file:
            raw = tomllib.load(config_file)
    except FileNotFoundError as error:
        raise VmError(f"Host configuration does not exist: {config_path}") from error
    except tomllib.TOMLDecodeError as error:
        raise VmError(f"Invalid TOML in {config_path}: {error}") from error

    defaults = raw.get("defaults", {})
    raw_vms = raw.get("vms")
    ventoy = raw.get("ventoy", {})
    if not isinstance(defaults, dict) or not isinstance(raw_vms, dict):
        raise VmError("Configuration requires [defaults] and [vms.*] tables")
    if not raw_vms:
        raise VmError("Configuration must define at least one VM")
    if not isinstance(ventoy, dict):
        raise VmError("[ventoy] must be a table")

    default_memory = _positive_int(defaults.get("memory_mib", 8192), "memory_mib")
    default_vcpus = _positive_int(defaults.get("vcpus", 4), "vcpus")
    default_network = _nonempty_string(defaults.get("network", "default"), "network")
    default_machine = _nonempty_string(defaults.get("machine", "q35"), "machine")
    default_disk_bus = _nonempty_string(defaults.get("disk_bus", "sata"), "disk_bus")
    default_video = _nonempty_string(defaults.get("video", "virtio"), "video")
    ventoy_label = _nonempty_string(
        ventoy.get("volume_label", "Ventoy"), "volume_label"
    )

    vms: dict[str, VmConfig] = {}
    for name, raw_vm in raw_vms.items():
        if not isinstance(raw_vm, dict):
            raise VmError(f"[vms.{name}] must be a table")
        disk = Path(_nonempty_string(raw_vm.get("disk"), f"vms.{name}.disk"))
        if not str(disk).startswith("/dev/disk/by-id/"):
            raise VmError(f"vms.{name}.disk must use a stable /dev/disk/by-id path")
        vms[name] = VmConfig(
            name=name,
            domain_name=_nonempty_string(
                raw_vm.get("domain_name", name), "domain_name"
            ),
            disk=disk,
            memory_mib=_positive_int(
                raw_vm.get("memory_mib", default_memory), "memory_mib"
            ),
            vcpus=_positive_int(raw_vm.get("vcpus", default_vcpus), "vcpus"),
            network=_nonempty_string(raw_vm.get("network", default_network), "network"),
            machine=_nonempty_string(raw_vm.get("machine", default_machine), "machine"),
            disk_bus=_nonempty_string(
                raw_vm.get("disk_bus", default_disk_bus), "disk_bus"
            ),
            video=_nonempty_string(raw_vm.get("video", default_video), "video"),
        )

    return HostConfig(hostname=hostname, ventoy_label=ventoy_label, vms=vms)


def load_block_devices(device: Path | None = None) -> list[dict[str, Any]]:
    """Return lsblk data, optionally limited to one device tree."""
    arguments = [
        "lsblk",
        "--json",
        "--output",
        "PATH,NAME,TYPE,TRAN,RM,LABEL,MOUNTPOINTS,MODEL,SERIAL",
    ]
    if device is not None:
        arguments.append(str(device))
    result = run_command(arguments)
    try:
        data = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise VmError("lsblk returned invalid JSON") from error
    devices = data.get("blockdevices")
    if not isinstance(devices, list):
        raise VmError("lsblk did not return a block device list")
    return devices


def walk_devices(devices: list[dict[str, Any]]):
    """Yield every node in one or more lsblk device trees."""
    for device in devices:
        yield device
        children = device.get("children", [])
        if isinstance(children, list):
            yield from walk_devices(children)


def mounted_paths(devices: list[dict[str, Any]]) -> list[tuple[str, str]]:
    """Return all mounted paths in lsblk trees."""
    mounted: list[tuple[str, str]] = []
    for device in walk_devices(devices):
        path = str(device.get("path", "unknown"))
        mountpoints = device.get("mountpoints") or []
        for mountpoint in mountpoints:
            if mountpoint:
                mounted.append((path, str(mountpoint)))
    return mounted


def validate_unmounted(device: Path, description: str) -> None:
    """Refuse devices mounted anywhere on the host."""
    mounts = mounted_paths(load_block_devices(device))
    if mounts:
        details = ", ".join(f"{path} at {mountpoint}" for path, mountpoint in mounts)
        raise VmError(f"{description} is mounted on the host: {details}")


def validate_disk(disk: Path) -> None:
    """Ensure a configured VM disk exists and is a whole block device."""
    if not disk.exists():
        raise VmError(f"Configured disk does not exist: {disk}")
    if not stat.S_ISBLK(disk.stat().st_mode):
        raise VmError(f"Configured disk is not a block device: {disk}")
    devices = load_block_devices(disk)
    if not devices or devices[0].get("type") != "disk":
        raise VmError(f"Configured path is not a whole disk: {disk}")
    validate_unmounted(disk, f"Disk {disk}")


def root_block_name(device: Path) -> str:
    """Resolve a disk or partition to its parent whole-disk kernel name."""
    resolved = device.resolve()
    sys_device = Path("/sys/class/block") / resolved.name
    if not sys_device.exists():
        return resolved.name
    real_sys_device = sys_device.resolve()
    if (real_sys_device / "partition").exists():
        return real_sys_device.parent.name
    return real_sys_device.name


def virsh(
    arguments: Sequence[str], *, check: bool = True
) -> subprocess.CompletedProcess[str]:
    """Run virsh against the system libvirt daemon."""
    return run_command(["virsh", "--connect", LIBVIRT_URI, *arguments], check=check)


def domain_state(domain_name: str) -> str | None:
    """Return a domain state, or None when it is not defined."""
    result = virsh(["domstate", domain_name], check=False)
    if result.returncode != 0:
        return None
    return result.stdout.strip().lower()


def active_domains() -> list[str]:
    result = virsh(["list", "--name"])
    return [name for name in result.stdout.splitlines() if name]


def domain_xml(domain: str) -> ET.Element:
    """Return the parsed XML definition for a domain."""
    xml_result = virsh(["dumpxml", domain])
    try:
        return ET.fromstring(xml_result.stdout)
    except ET.ParseError as error:
        raise VmError(
            f"libvirt returned invalid XML for running domain {domain}"
        ) from error


def validate_disk_not_in_use(disk: Path, own_domain: str) -> None:
    """Refuse a disk already attached to another running libvirt domain."""
    target_root = root_block_name(disk)
    for domain in active_domains():
        if domain == own_domain:
            continue
        root = domain_xml(domain)
        for source in root.findall("./devices/disk/source"):
            source_device = source.get("dev")
            if source_device and root_block_name(Path(source_device)) == target_root:
                raise VmError(f"Disk {disk} is already used by running domain {domain}")


def _contains_label(device: dict[str, Any], label: str) -> bool:
    return any(
        str(node.get("label", "")).casefold() == label.casefold()
        for node in walk_devices([device])
    )


def find_ventoy_candidates(
    devices: list[dict[str, Any]], label: str
) -> list[dict[str, Any]]:
    """Find removable USB disks containing the configured Ventoy label."""
    return [
        device
        for device in devices
        if device.get("type") == "disk"
        and (device.get("tran") == "usb" or bool(device.get("rm")))
        and _contains_label(device, label)
    ]


def usb_identity(block_path: Path, description: str) -> UsbDevice:
    """Resolve a USB block device to its current host USB address."""
    sys_device = Path("/sys/class/block") / block_path.resolve().name
    if not sys_device.exists():
        raise VmError(f"Cannot inspect USB device in sysfs: {block_path}")

    current = sys_device.resolve()
    for parent in (current, *current.parents):
        required = ["idVendor", "idProduct", "busnum", "devnum"]
        if all((parent / field).exists() for field in required):
            return UsbDevice(
                block_path=block_path,
                vendor_id=(parent / "idVendor").read_text(encoding="ascii").strip(),
                product_id=(parent / "idProduct").read_text(encoding="ascii").strip(),
                bus=int((parent / "busnum").read_text(encoding="ascii").strip()),
                device=int((parent / "devnum").read_text(encoding="ascii").strip()),
                description=description,
            )
    raise VmError(f"Cannot resolve USB address for {block_path}")


def select_ventoy(config: HostConfig) -> UsbDevice:
    """Discover and select the Ventoy stick."""
    candidates = find_ventoy_candidates(load_block_devices(), config.ventoy_label)
    if not candidates:
        raise VmError(
            f"No removable USB disk with volume label {config.ventoy_label!r} was found"
        )

    if len(candidates) > 1:
        if not sys.stdin.isatty():
            raise VmError(
                "Multiple Ventoy devices found; run interactively to select one"
            )
        print("Multiple Ventoy devices found:")
        for index, candidate in enumerate(candidates, start=1):
            print(
                f"  {index}. {candidate.get('path')} "
                f"{candidate.get('model') or ''} {candidate.get('serial') or ''}".rstrip()
            )
        try:
            selected_index = int(input("Select Ventoy device: ")) - 1
            candidate = candidates[selected_index]
        except (ValueError, IndexError) as error:
            raise VmError("Invalid Ventoy selection") from error
    else:
        candidate = candidates[0]

    block_path = Path(str(candidate["path"]))
    validate_unmounted(block_path, "Ventoy device")
    description = " ".join(
        value
        for value in (
            str(candidate.get("model") or ""),
            str(candidate.get("serial") or ""),
        )
        if value
    )
    return usb_identity(block_path, description or str(block_path))


def validate_usb_not_in_use(usb: UsbDevice, own_domain: str) -> None:
    """Refuse a USB address attached to another running libvirt domain."""
    for domain in active_domains():
        if domain == own_domain:
            continue
        root = domain_xml(domain)
        for address in root.findall("./devices/hostdev[@type='usb']/source/address"):
            try:
                bus = int(address.get("bus", ""), 0)
                device = int(address.get("device", ""), 0)
            except ValueError:
                continue
            if bus == usb.bus and device == usb.device:
                raise VmError(
                    f"Ventoy USB device is already used by running domain {domain}"
                )


def validate_ventoy(usb: UsbDevice, own_domain: str) -> None:
    """Recheck a selected Ventoy device immediately before VM startup."""
    validate_unmounted(usb.block_path, "Ventoy device")
    current = usb_identity(usb.block_path, usb.description)
    expected_identity = (usb.vendor_id, usb.product_id, usb.bus, usb.device)
    current_identity = (
        current.vendor_id,
        current.product_id,
        current.bus,
        current.device,
    )
    if current_identity != expected_identity:
        raise VmError("Ventoy USB address changed; rerun the command")
    validate_usb_not_in_use(usb, own_domain)


@contextmanager
def launch_lock():
    """Serialize launcher runs so device checks and startup cannot overlap."""
    runtime_dir = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
    if not runtime_dir.is_dir():
        raise VmError(f"Runtime directory does not exist: {runtime_dir}")
    lock_path = runtime_dir / "physical-vm-launch.lock"
    with lock_path.open("a+", encoding="utf-8") as lock_file:
        try:
            fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            raise VmError(
                "Another physical-vm launch is already in progress"
            ) from error
        yield


def deterministic_uuid(hostname: str, domain_name: str) -> str:
    return str(uuid.uuid5(UUID_NAMESPACE, f"{hostname}:{domain_name}"))


def deterministic_mac(hostname: str, domain_name: str) -> str:
    digest = hashlib.sha256(f"{hostname}:{domain_name}".encode()).digest()
    return "52:54:00:" + ":".join(f"{byte:02x}" for byte in digest[:3])


def add_text_element(
    parent: ET.Element, tag: str, text: str, **attributes: str
) -> ET.Element:
    element = ET.SubElement(parent, tag, attributes)
    element.text = text
    return element


def build_domain_xml(
    vm: VmConfig, hostname: str, ventoy: UsbDevice | None
) -> ET.Element:
    """Build a complete persistent libvirt domain definition."""
    domain = ET.Element("domain", {"type": "kvm"})
    add_text_element(domain, "name", vm.domain_name)
    add_text_element(domain, "uuid", deterministic_uuid(hostname, vm.domain_name))
    add_text_element(domain, "memory", str(vm.memory_mib), unit="MiB")
    add_text_element(domain, "currentMemory", str(vm.memory_mib), unit="MiB")
    add_text_element(domain, "vcpu", str(vm.vcpus), placement="static")

    os_element = ET.SubElement(domain, "os", {"firmware": "efi"})
    firmware = ET.SubElement(os_element, "firmware")
    ET.SubElement(firmware, "feature", {"enabled": "no", "name": "secure-boot"})
    add_text_element(os_element, "type", "hvm", arch="x86_64", machine=vm.machine)
    ET.SubElement(os_element, "nvram")
    ET.SubElement(os_element, "bootmenu", {"enable": "yes", "timeout": "5000"})

    features = ET.SubElement(domain, "features")
    ET.SubElement(features, "acpi")
    ET.SubElement(features, "apic")
    ET.SubElement(domain, "cpu", {"mode": "host-passthrough", "check": "none"})
    ET.SubElement(domain, "clock", {"offset": "utc"})
    add_text_element(domain, "on_poweroff", "destroy")
    add_text_element(domain, "on_reboot", "restart")
    add_text_element(domain, "on_crash", "destroy")

    devices = ET.SubElement(domain, "devices")
    disk = ET.SubElement(devices, "disk", {"type": "block", "device": "disk"})
    ET.SubElement(
        disk,
        "driver",
        {"name": "qemu", "type": "raw", "cache": "none", "io": "native"},
    )
    ET.SubElement(disk, "source", {"dev": str(vm.disk)})
    ET.SubElement(disk, "target", {"dev": "sda", "bus": vm.disk_bus})
    ET.SubElement(disk, "boot", {"order": "2" if ventoy else "1"})

    ET.SubElement(devices, "controller", {"type": "usb", "model": "qemu-xhci"})
    if ventoy:
        hostdev = ET.SubElement(
            devices,
            "hostdev",
            {"mode": "subsystem", "type": "usb"},
        )
        source = ET.SubElement(hostdev, "source")
        ET.SubElement(source, "vendor", {"id": f"0x{ventoy.vendor_id}"})
        ET.SubElement(source, "product", {"id": f"0x{ventoy.product_id}"})
        ET.SubElement(
            source,
            "address",
            {"bus": str(ventoy.bus), "device": str(ventoy.device)},
        )
        ET.SubElement(hostdev, "boot", {"order": "1"})

    interface = ET.SubElement(devices, "interface", {"type": "network"})
    ET.SubElement(
        interface, "mac", {"address": deterministic_mac(hostname, vm.domain_name)}
    )
    ET.SubElement(interface, "source", {"network": vm.network})
    ET.SubElement(interface, "model", {"type": "virtio"})
    ET.SubElement(devices, "graphics", {"type": "spice", "autoport": "yes"})
    video = ET.SubElement(devices, "video")
    ET.SubElement(video, "model", {"type": vm.video, "primary": "yes"})
    ET.SubElement(devices, "input", {"type": "tablet", "bus": "usb"})
    ET.SubElement(devices, "sound", {"model": "ich9"})
    channel = ET.SubElement(devices, "channel", {"type": "spicevmc"})
    ET.SubElement(channel, "target", {"type": "virtio", "name": "com.redhat.spice.0"})
    rng = ET.SubElement(devices, "rng", {"model": "virtio"})
    add_text_element(rng, "backend", "/dev/urandom", model="random")
    ET.SubElement(devices, "memballoon", {"model": "virtio"})
    return domain


def write_domain_xml(
    vm: VmConfig,
    hostname: str,
    ventoy: UsbDevice | None,
    output_dir: Path,
) -> Path:
    """Write generated XML and validate it against libvirt's schema."""
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{hostname}-{vm.domain_name}.xml"
    domain = build_domain_xml(vm, hostname, ventoy)
    ET.indent(domain, space="  ")
    xml = ET.tostring(domain, encoding="unicode", xml_declaration=True)
    output_path.write_text(xml + "\n", encoding="utf-8")
    run_command(["virt-xml-validate", str(output_path), "domain"])
    return output_path


def ensure_network(network: str) -> None:
    """Start the configured persistent libvirt network when needed."""
    result = virsh(["net-info", network], check=False)
    if result.returncode != 0:
        raise VmError(f"Libvirt network is not defined: {network}")
    active_line = next(
        (line for line in result.stdout.splitlines() if line.startswith("Active:")), ""
    )
    if active_line.split(":", maxsplit=1)[-1].strip().lower() != "yes":
        virsh(["net-start", network])


def validate_vm(vm: VmConfig) -> None:
    """Perform all non-mutating physical disk safety checks."""
    state = domain_state(vm.domain_name)
    if state and state not in {"shut off", "shutoff"}:
        raise VmError(f"Domain {vm.domain_name} is already {state}")
    validate_disk(vm.disk)
    validate_disk_not_in_use(vm.disk, vm.domain_name)


def ask_for_ventoy() -> bool:
    try:
        answer = input("Attach the Ventoy USB device? [y/N]: ").strip().casefold()
    except EOFError as error:
        raise VmError(
            "Use --ventoy or --no-ventoy when running non-interactively"
        ) from error
    return answer in {"y", "yes"}


def resolve_ventoy_choice(arguments: argparse.Namespace) -> bool:
    if arguments.ventoy:
        return True
    if arguments.no_ventoy:
        return False
    return ask_for_ventoy()


def get_vm(config: HostConfig, name: str) -> VmConfig:
    try:
        return config.vms[name]
    except KeyError as error:
        available = ", ".join(sorted(config.vms))
        raise VmError(f"Unknown VM {name!r}; available VMs: {available}") from error


def command_list(config: HostConfig) -> None:
    for vm in config.vms.values():
        print(f"{vm.name:12} {vm.disk}")


def command_validate(config: HostConfig, name: str, output_dir: Path) -> None:
    vm = get_vm(config, name)
    validate_vm(vm)
    xml_path = write_domain_xml(vm, config.hostname, None, output_dir)
    print(f"Validated {vm.name}: {vm.disk}")
    print(f"Generated domain XML: {xml_path}")


def command_run(
    config: HostConfig,
    name: str,
    output_dir: Path,
    arguments: argparse.Namespace,
) -> None:
    vm = get_vm(config, name)
    with launch_lock():
        validate_vm(vm)
        attach_ventoy = resolve_ventoy_choice(arguments)
        ventoy = select_ventoy(config) if attach_ventoy else None
        if ventoy:
            validate_usb_not_in_use(ventoy, vm.domain_name)
        xml_path = write_domain_xml(vm, config.hostname, ventoy, output_dir)

        print(f"VM: {vm.name}")
        print(f"Physical disk: {vm.disk}")
        print(f"Ventoy: {ventoy.description if ventoy else 'not attached'}")
        print("WARNING: The guest has direct write access to the physical disk.")
        ensure_network(vm.network)
        validate_vm(vm)
        if ventoy:
            validate_ventoy(ventoy, vm.domain_name)
        virsh(["define", "--validate", str(xml_path)])
        virsh(["start", vm.domain_name])
        print(f"Started {vm.domain_name}")

    print_domain_status(vm)
    if arguments.no_console:
        print(f"Console: physical-vm console {vm.name}")
    elif os.environ.get("DISPLAY") or os.environ.get("WAYLAND_DISPLAY"):
        try:
            launch_console(vm)
        except VmError as error:
            print(f"Warning: VM started, but the console did not open: {error}")
            print(f"Open it with: physical-vm console {vm.name}")
    else:
        print(
            f"No graphical session detected. Open with: physical-vm console {vm.name}"
        )


def domain_display(domain_name: str) -> str | None:
    """Return the active graphical display URI when available."""
    result = virsh(["domdisplay", domain_name], check=False)
    if result.returncode != 0:
        return None
    return result.stdout.strip() or None


def print_domain_status(vm: VmConfig) -> None:
    """Print concise domain state and display information."""
    state = domain_state(vm.domain_name) or "undefined"
    print(f"State: {state}")
    display = domain_display(vm.domain_name)
    if display:
        print(f"Display: {display}")


def launch_console(vm: VmConfig) -> None:
    """Open a domain's graphical console in virt-manager."""
    state = domain_state(vm.domain_name)
    if state is None:
        raise VmError(f"Domain {vm.domain_name} is not defined")
    if state in {"shut off", "shutoff"}:
        raise VmError(f"Domain {vm.domain_name} is shut off")
    run_command(
        [
            "virt-manager",
            "--fork",
            "--connect",
            LIBVIRT_URI,
            "--show-domain-console",
            vm.domain_name,
        ]
    )
    print(f"Opened console for {vm.domain_name}")


def command_status(config: HostConfig, name: str) -> None:
    vm = get_vm(config, name)
    print_domain_status(vm)


def command_console(config: HostConfig, name: str) -> None:
    launch_console(get_vm(config, name))


def command_logs(config: HostConfig, name: str, lines: int) -> None:
    """Show recent libvirt service logs and the per-domain log location."""
    vm = get_vm(config, name)
    print(f"QEMU log: /var/log/libvirt/qemu/{vm.domain_name}.log (root-readable)")
    result = run_command(
        [
            "journalctl",
            "--no-pager",
            "--unit",
            "libvirtd",
            "--unit",
            "virtqemud",
            "--lines",
            str(lines),
        ]
    )
    print(result.stdout, end="")


def command_stop(config: HostConfig, name: str) -> None:
    vm = get_vm(config, name)
    state = domain_state(vm.domain_name)
    if state is None:
        raise VmError(f"Domain {vm.domain_name} is not defined")
    if state in {"shut off", "shutoff"}:
        print(f"{vm.domain_name} is already shut off")
        return
    virsh(["shutdown", vm.domain_name])
    print(f"Shutdown requested for {vm.domain_name}")


def build_parser() -> argparse.ArgumentParser:
    default_config_dir = Path(__file__).resolve().parent / "hosts"
    default_output_dir = Path(__file__).resolve().parent / "generated"
    parser = argparse.ArgumentParser(
        description="Manage libvirt VMs backed by physical disks"
    )
    parser.add_argument(
        "--host", help="host config name; defaults to the local hostname"
    )
    parser.add_argument("--config", type=Path, help="explicit host TOML path")
    parser.add_argument("--config-dir", type=Path, default=default_config_dir)
    parser.add_argument("--output-dir", type=Path, default=default_output_dir)
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("list", help="list configured VMs")
    for command in ("validate", "status", "stop", "console"):
        command_parser = subparsers.add_parser(command)
        command_parser.add_argument("name")

    logs_parser = subparsers.add_parser("logs", help="show recent libvirt logs")
    logs_parser.add_argument("name")
    logs_parser.add_argument("--lines", type=_positive_cli_int, default=100)

    run_parser = subparsers.add_parser("run", help="define and start a VM")
    run_parser.add_argument("name")
    ventoy_group = run_parser.add_mutually_exclusive_group()
    ventoy_group.add_argument("--ventoy", action="store_true")
    ventoy_group.add_argument("--no-ventoy", action="store_true")
    run_parser.add_argument(
        "--no-console", action="store_true", help="do not open virt-manager"
    )
    return parser


def _positive_cli_int(value: str) -> int:
    try:
        parsed = int(value)
    except ValueError as error:
        raise argparse.ArgumentTypeError("must be an integer") from error
    if parsed <= 0:
        raise argparse.ArgumentTypeError("must be greater than zero")
    return parsed


def main() -> int:
    parser = build_parser()
    arguments = parser.parse_args()
    hostname = (arguments.host or socket.gethostname()).split(".", maxsplit=1)[0]
    config_path = arguments.config or arguments.config_dir / f"{hostname}.toml"

    try:
        config = load_config(config_path, hostname)
        if arguments.command == "list":
            command_list(config)
        elif arguments.command == "validate":
            command_validate(config, arguments.name, arguments.output_dir)
        elif arguments.command == "run":
            command_run(config, arguments.name, arguments.output_dir, arguments)
        elif arguments.command == "status":
            command_status(config, arguments.name)
        elif arguments.command == "stop":
            command_stop(config, arguments.name)
        elif arguments.command == "console":
            command_console(config, arguments.name)
        elif arguments.command == "logs":
            command_logs(config, arguments.name, arguments.lines)
        else:
            parser.error(f"Unknown command: {arguments.command}")
    except (VmError, OSError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
