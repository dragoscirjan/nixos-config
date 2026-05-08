# AI MCP Servers Template
# Installs FastCode and other MCP servers system-wide
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = import ../common/ai-mcps.nix { inherit pkgs; };
}
