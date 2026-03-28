# AI template — local LLM inference + GPU acceleration
# Reads host.hw.gpuAmd / host.hw.gpuNvidia to set ollama acceleration and GPU packages
{ config, pkgs, lib, ... }:

let
  cfg = config.host.hw;
in
{
  # ── Ollama service ─────────────────────────────────────────────────────────
  # ollama-rocm/ollama-cuda are aliases for the unified ollama package in current
  # nixpkgs-unstable; just use pkgs.ollama for all variants.
  services.ollama.enable = true;

  # ── AI packages (always) ──────────────────────────────────────────────────
  environment.systemPackages = with pkgs;
    [
      koboldcpp
      llama-cpp
      lmstudio
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
}
