{ pkgs, ... }:

let
  physical-vm = pkgs.writeShellApplication {
    name = "physical-vm";
    runtimeInputs = with pkgs; [
      libvirt
      python3
      systemd
      util-linux
      virt-manager
    ];
    text = ''
      output_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/physical-vm"
      exec ${pkgs.python3}/bin/python3 ${./vm.py} \
        --config-dir ${./hosts} \
        --output-dir "$output_dir" \
        "$@"
    '';
  };
in
{
  virtualisation.libvirtd.enable = true;

  environment.systemPackages = [
    physical-vm
    pkgs.usbutils
  ];
}
