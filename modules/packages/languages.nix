# Programming language packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.languages;
in
{
  options.modules.packages.languages = {
    enable = mkEnableOption "Programming language packages";

    golang = mkOption {
      type = types.bool;
      default = true;
      description = "Install Go programming language";
    };

    nodejs = mkOption {
      type = types.bool;
      default = true;
      description = "Install Node.js 24 (latest patch)";
    };

    bun = mkOption {
      type = types.bool;
      default = true;
      description = "Install Bun JavaScript runtime";
    };

    rust = mkOption {
      type = types.bool;
      default = true;
      description = "Install Rust programming language";
    };

    python = mkOption {
      type = types.bool;
      default = true;
      description = "Install Python 3.11+";
    };

    uv = mkOption {
      type = types.bool;
      default = true;
      description = "Install uv Python package manager";
    };

    lua = mkOption {
      type = types.bool;
      default = true;
      description = "Install Lua programming language";
    };

    full = mkOption {
      type = types.bool;
      default = false;
      description = "Install additional languages (deno, clang toolchain, php, lua)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      optionals cfg.golang [ go gopls ]
      ++ optionals cfg.nodejs [ nodejs_24 ]  # Node.js 24 latest patch
      ++ optionals cfg.bun [ bun ]
      ++ optionals cfg.rust [ rustc cargo rust-analyzer ]
       ++ optionals cfg.python [ python311 ]
       ++ optionals cfg.uv [ uv ]
       ++ optionals cfg.lua [ lua ]
       ++ optionals cfg.full [ deno clang clang-tools llvmPackages.lld ]  # Full clang toolchain
      ++ [ gcc gnumake ];  # Build tools for minimal install
  };
}
