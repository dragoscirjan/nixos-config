# AI template — local LLM inference + GPU acceleration
# Reads host.hw.gpuAmd / host.hw.gpuNvidia to set ollama acceleration and GPU packages
{ config, pkgs, lib, ... }:

let
  cfg = config.host.hw;
in
{
  # ── Ollama service ─────────────────────────────────────────────────────────
  # services.ollama.acceleration was removed in nixos-unstable; select the
  # appropriate package variant instead.
  services.ollama = {
    enable = true;
    package =
      if cfg.gpuAmd then pkgs.ollama-rocm
      else if cfg.gpuNvidia then pkgs.ollama-cuda
      else pkgs.ollama;
  };

  # ── AI packages (always) ──────────────────────────────────────────────────
  environment.systemPackages = with pkgs;
    [
      koboldcpp
      llama-cpp
      lmstudio
      ollama
      whisper-cpp
    ]
    # AMD GPU extras
    ++ lib.optionals cfg.gpuAmd [
      rocmPackages.rocm-runtime
      rocmPackages.rocm-opencl-runtime
    ]
    # Nvidia GPU extras
    ++ lib.optionals cfg.gpuNvidia [
      cudaPackages.cudatoolkit
    ];
}
