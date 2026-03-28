# HW: Tower template — performance CPU governor
{ config, lib, ... }:

{
  host.hw.tower = true;

  powerManagement.cpuFreqGovernor = "performance";
}
