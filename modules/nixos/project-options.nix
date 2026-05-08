{ lib, ... }:

{
  options.devProjects = {
    mcpTuikit = lib.mkEnableOption "GUI tools and headless display servers required for mcp-tuikit development";
  };
}
