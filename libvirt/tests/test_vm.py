"""Unit tests for the physical VM launcher."""

from __future__ import annotations

import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock
import xml.etree.ElementTree as ET


MODULE_PATH = Path(__file__).parents[1] / "vm.py"
SPEC = importlib.util.spec_from_file_location("physical_vm", MODULE_PATH)
assert SPEC and SPEC.loader
vm_module = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = vm_module
SPEC.loader.exec_module(vm_module)


class ConfigTest(unittest.TestCase):
    def test_loads_defaults_and_vm_overrides(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_path = Path(temporary_directory) / "host.toml"
            config_path.write_text(
                """
[defaults]
memory_mib = 4096
vcpus = 2

[ventoy]
volume_label = "MY_VENTOY"

[vms.fedora]
disk = "/dev/disk/by-id/example"
vcpus = 6
""",
                encoding="utf-8",
            )
            config = vm_module.load_config(config_path, "test-host")

        self.assertEqual(config.ventoy_label, "MY_VENTOY")
        self.assertEqual(config.vms["fedora"].memory_mib, 4096)
        self.assertEqual(config.vms["fedora"].vcpus, 6)

    def test_rejects_unstable_disk_path(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_path = Path(temporary_directory) / "host.toml"
            config_path.write_text(
                '[vms.fedora]\ndisk = "/dev/sda"\n', encoding="utf-8"
            )
            with self.assertRaisesRegex(vm_module.VmError, "/dev/disk/by-id"):
                vm_module.load_config(config_path, "test-host")


class DeviceTest(unittest.TestCase):
    def setUp(self) -> None:
        self.devices = [
            {
                "path": "/dev/sdz",
                "type": "disk",
                "tran": "usb",
                "rm": True,
                "mountpoints": [],
                "children": [
                    {
                        "path": "/dev/sdz1",
                        "type": "part",
                        "label": "Ventoy",
                        "mountpoints": ["/run/media/user/Ventoy"],
                    }
                ],
            }
        ]

    def test_finds_ventoy_by_partition_label(self) -> None:
        candidates = vm_module.find_ventoy_candidates(self.devices, "ventoy")
        self.assertEqual(candidates[0]["path"], "/dev/sdz")

    def test_reports_nested_mounts(self) -> None:
        self.assertEqual(
            vm_module.mounted_paths(self.devices),
            [("/dev/sdz1", "/run/media/user/Ventoy")],
        )

    def test_rejects_ventoy_attached_to_running_domain(self) -> None:
        ventoy = vm_module.UsbDevice(
            block_path=Path("/dev/sdz"),
            vendor_id="abcd",
            product_id="1234",
            bus=1,
            device=7,
            description="Ventoy",
        )
        domain = ET.fromstring(
            """
<domain>
  <devices>
    <hostdev type="usb"><source><address bus="1" device="7"/></source></hostdev>
  </devices>
</domain>
"""
        )
        with (
            mock.patch.object(vm_module, "active_domains", return_value=["other"]),
            mock.patch.object(vm_module, "domain_xml", return_value=domain),
            self.assertRaisesRegex(vm_module.VmError, "running domain other"),
        ):
            vm_module.validate_usb_not_in_use(ventoy, "fedora")


class DomainXmlTest(unittest.TestCase):
    def setUp(self) -> None:
        self.vm = vm_module.VmConfig(
            name="fedora",
            domain_name="fedora",
            disk=Path("/dev/disk/by-id/example"),
            memory_mib=8192,
            vcpus=8,
            network="default",
            machine="q35",
            disk_bus="sata",
            video="virtio",
        )

    def test_builds_physical_disk_domain(self) -> None:
        domain = vm_module.build_domain_xml(self.vm, "test-host", None)
        self.assertEqual(domain.findtext("name"), "fedora")
        self.assertEqual(domain.find("./os").get("firmware"), "efi")
        self.assertEqual(
            domain.find("./devices/disk/source").get("dev"),
            "/dev/disk/by-id/example",
        )
        self.assertEqual(domain.find("./devices/disk/target").get("bus"), "sata")
        self.assertEqual(domain.find("./devices/disk/boot").get("order"), "1")

    def test_puts_ventoy_first_in_boot_order(self) -> None:
        ventoy = vm_module.UsbDevice(
            block_path=Path("/dev/sdz"),
            vendor_id="abcd",
            product_id="1234",
            bus=1,
            device=7,
            description="Ventoy",
        )
        domain = vm_module.build_domain_xml(self.vm, "test-host", ventoy)
        hostdev = domain.find("./devices/hostdev")
        self.assertIsNotNone(hostdev)
        assert hostdev is not None
        self.assertEqual(hostdev.find("./source/address").get("device"), "7")
        self.assertEqual(hostdev.find("boot").get("order"), "1")
        self.assertEqual(domain.find("./devices/disk/boot").get("order"), "2")

    def test_domain_identity_is_stable(self) -> None:
        first = ET.tostring(vm_module.build_domain_xml(self.vm, "host", None))
        second = ET.tostring(vm_module.build_domain_xml(self.vm, "host", None))
        self.assertEqual(first, second)


class ConsoleTest(unittest.TestCase):
    def setUp(self) -> None:
        self.vm = vm_module.VmConfig(
            name="omarchy",
            domain_name="omarchy",
            disk=Path("/dev/disk/by-id/example"),
            memory_mib=8192,
            vcpus=8,
            network="default",
            machine="q35",
            disk_bus="sata",
            video="virtio",
        )

    def test_opens_running_domain_console(self) -> None:
        with (
            mock.patch.object(vm_module, "domain_state", return_value="running"),
            mock.patch.object(vm_module, "run_command") as run_command,
        ):
            vm_module.launch_console(self.vm)

        run_command.assert_called_once_with(
            [
                "virt-manager",
                "--fork",
                "--connect",
                vm_module.LIBVIRT_URI,
                "--show-domain-console",
                "omarchy",
            ]
        )

    def test_rejects_console_for_stopped_domain(self) -> None:
        with (
            mock.patch.object(vm_module, "domain_state", return_value="shut off"),
            self.assertRaisesRegex(vm_module.VmError, "is shut off"),
        ):
            vm_module.launch_console(self.vm)


if __name__ == "__main__":
    unittest.main()
