# Physical-disk VMs

This directory contains a data-driven launcher for libvirt VMs that boot directly
from physical disks. Host-specific device identities live in `hosts/*.toml`; the
Python launcher contains no machine-specific disk paths.

## Safety

The guest receives direct write access to its configured physical disk. Before a
VM starts, the launcher verifies that:

- the configured path is a stable `/dev/disk/by-id/` whole-disk path;
- the disk and its partitions are not mounted on the host;
- the domain is not already running;
- no other running libvirt domain uses the disk;
- a selected Ventoy device and its partitions are not mounted or attached to
  another running domain.

Launcher runs are serialized and device checks are repeated immediately before
startup to reduce the chance of a concurrent launch or automount racing the checks.

Do not mount a VM disk on the host while its guest is running. Shut down the guest
cleanly before booting the same installation directly on hardware. Operating
systems with hibernation or fast startup enabled must be fully shut down first.

## NixOS installation

`tw-nixos` imports `nixos-module.nix`. After applying the NixOS configuration, the
launcher is available as `physical-vm`:

```bash
./rebuild-nixos.sh switch
physical-vm list
```

The repository script can also be run directly:

```bash
./libvirt/vm.py list
```

The installed command stores generated domain XML under
`${XDG_CACHE_HOME:-$HOME/.cache}/physical-vm`. Direct repository runs use
`libvirt/generated/`, which is ignored by Git.

## Commands

Validate the disk and generated XML without defining or starting a domain:

```bash
physical-vm validate fedora
physical-vm validate omarchy
```

Start a VM. Without a flag, the command asks whether to attach Ventoy:

```bash
physical-vm run fedora
physical-vm run omarchy
```

After a successful start, the command reports the domain state and SPICE URI and
opens its graphical console in `virt-manager`. Use `--no-console` for a headless
launch.

For automation, answer the Ventoy question explicitly:

```bash
physical-vm run fedora --ventoy
physical-vm run fedora --no-ventoy --no-console
```

Inspect state or request a clean ACPI shutdown:

```bash
physical-vm status fedora
physical-vm stop fedora
physical-vm console fedora
physical-vm logs fedora
```

The launcher starts the configured libvirt network automatically if it is
currently inactive. `logs` shows recent libvirt journal entries and identifies the
root-readable per-domain QEMU log.

## Ventoy

Ventoy is detected dynamically by the filesystem label configured in the host
TOML file. The default label is `Ventoy`. The USB bus and device numbers are read
from sysfs each time, so reconnecting the stick does not require a config change.

The USB stick belongs exclusively to the selected guest until that guest stops.
It cannot be attached to both VMs simultaneously. When attached, Ventoy receives
boot order 1 and the physical SSD receives boot order 2.

## Adding hosts or VMs

Create `hosts/<hostname>.toml` and add one table per VM:

```toml
[defaults]
memory_mib = 8192
vcpus = 8
network = "default"
machine = "q35"
disk_bus = "sata"
video = "virtio"

[ventoy]
volume_label = "Ventoy"

[vms.example]
disk = "/dev/disk/by-id/ata-example-serial"
```

Per-VM values can override any default. Use `--host <name>` to select a different
host file or `--config <path>` for an explicit TOML file.

## Tests

```bash
python3 -m unittest discover -s libvirt/tests -v
```
