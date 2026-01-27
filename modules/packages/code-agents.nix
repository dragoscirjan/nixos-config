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

    claude-code = mkOption {
      type = types.bool;
      default = false;
      description = "Install Claude Code AI assistant";
    };

    gemini-cli = mkOption {
      type = types.bool;
      default = false;
      description = "Install Gemini CLI AI assistant";
    };

    codex = mkOption {
      type = types.bool;
      default = false;
      description = "Install Codex AI assistant";
    };

    copilot-cli = mkOption {
      type = types.bool;
      default = false;
      description = "Install GitHub Copilot CLI";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      (optionals cfg.opencode [ opencode ]) ++
      (optionals cfg.claude-code [ claude-code ]) ++
      (optionals cfg.gemini-cli [ gemini-cli ]) ++
      (optionals cfg.codex [ codex ]) ++
      (optionals cfg.copilot-cli [ copilot-cli ]);
  };
}
