# AI coding agent packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.code-agents;
in
{
  options.modules.packages.code-agents = {
    enable = mkEnableOption "AI coding agent packages";

    extended = mkEnableOption "Extended code agents (claude-code, codex, opencode)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Basic code agents (always installed when enabled)
      [
        copilot-cli
        gemini-cli
      ]
      ++
      # Extended code agents
      optionals cfg.extended [
        claude-code
        codex
        opencode
      ];
  };
}
