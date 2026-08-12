# mac-m1 — portable "do-it-all" MacBook. Identical modules/darwin/*.nix
# payload as mac-m5 for now (v2 scope); only host identity differs here.
# Customize per-host packages/services later if the two roles diverge.
{ ... }:

{
  imports = [ ../../../modules/darwin/common.nix ];

  networking.hostName = "mac-m1";
  networking.computerName = "mac-m1";
  system.primaryUser = "dragosc";
}
