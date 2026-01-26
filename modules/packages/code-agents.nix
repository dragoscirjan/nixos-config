# AI coding agent packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.code-agents;
in
{
  options.modules.packages.code-agents = {
    enable = mkEnableOption "AI coding agent packages";

    opencode = mkOption {
      type = types.bool;
      default = true;
      description = "Install OpenCode AI coding assistant";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      optionals cfg.opencode [
        opencode
      ];
  };
}
