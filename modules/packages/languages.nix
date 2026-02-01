# Programming language packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.languages;
in
{
  options.modules.packages.languages = {
    enable = mkEnableOption "Programming language packages";

    extended = mkEnableOption "Extended languages (deno, clang toolchain, zig)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Basic languages (always installed when enabled)
      [
        # Build tools
        gcc
        gnumake

        # Go
        go
        gopls

        # JavaScript/TypeScript
        bun
        nodejs_24

        # Lua
        lua

        # Python
        python311
        uv

        # Rust
        cargo
        rust-analyzer
        rustc
      ]
      ++
      # Extended languages
      optionals cfg.extended [
        clang
        clang-tools
        deno
        llvmPackages.lld
        zig
      ];
  };
}
