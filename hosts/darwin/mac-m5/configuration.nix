# mac-m5 — leans toward "LLM server" duty (per user intent). Identical
# modules/darwin/*.nix payload as mac-m1 for now (v2 scope); only host
# identity differs here. Add LLM-serving-specific packages/services here
# once that role is fleshed out (deferred — see LLD non-goals).
{ ... }:

{
  imports = [ ../../../modules/darwin/common.nix ];

  networking.hostName = "mac-m5";
  networking.computerName = "mac-m5";
  system.primaryUser = "dragosc";
}
