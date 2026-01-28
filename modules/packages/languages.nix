# Programming language packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.languages;
in
{
  options.modules.packages.languages = {
    enable = mkEnableOption "Programming language packages";

    basic = mkOption {
      type = types.bool;
      default = true;
      description = "Install basic set of languages (golang, nodejs, bun, rust, python, uv, lua)";
    };

    extended = mkOption {
      type = types.bool;
      default = false;
      description = "Install additional languages (deno, clang toolchain, php, lua)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Basic Languages
      optionals cfg.basic [
        go
        gopls
        nodejs_24
        bun
        rustc
        cargo
        rust-analyzer
        python311
        uv
        lua
      ]
      ++
      # Extended clang toolchain 
      optionals cfg.extended [
        deno
        clang
        clang-tools
        llvmPackages.lld
        zig
      ]
      ++
      # Build tools for basic install
      [ gcc gnumake ];
  };
}
