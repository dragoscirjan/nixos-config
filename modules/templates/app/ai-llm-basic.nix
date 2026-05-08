# AI template — basic local LLM inference CLI tools + GPU acceleration
{ config, pkgs, lib, isHomeManager ? false, ... }:

let
  # Hardware config is only evaluated natively on NixOS
  cfg = if isHomeManager then { gpuAmd = false; gpuNvidia = false; } else config.host.hw;

  sharedPackages = with pkgs; [
    koboldcpp
    llama-cpp
    ollama
    whisper-cpp
  ]
  # AMD GPU extras: ROCm runtime + OpenCL (clr = Common Language Runtime)
  ++ lib.optionals cfg.gpuAmd [
    rocmPackages.rocm-runtime
    rocmPackages.clr
  ]
  # Nvidia GPU extras
  ++ lib.optionals cfg.gpuNvidia [
    cudaPackages.cudatoolkit
  ];
in
if isHomeManager then {
  home.packages = sharedPackages;
} else {
  environment.systemPackages = sharedPackages;

  # ── Ollama service ─────────────────────────────────────────────────────────
  services.ollama.enable = true;
}
