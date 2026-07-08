# AI template — basic local LLM inference CLI tools + GPU acceleration
{ config, pkgs, lib, isHomeManager ? false, ... }:

let
  # Hardware config is only evaluated natively on NixOS
  cfg = if isHomeManager then { gpuAmd = false; gpuNvidia = false; } else config.host.hw;

  # Single, consistent per-machine model storage location for every local LLM
  # runner (ollama, llama-cpp, koboldcpp all honor OLLAMA_MODELS /
  # HOME-relative conventions differently — pinning one directory here stops
  # each tool/context from silently re-downloading multi-GB models into its
  # own default cache path and quietly eating disk space).
  # NixOS (services.ollama) already defaults to this exact path; it is set
  # explicitly below for documentation/consistency rather than to change
  # behavior. Home Manager contexts (Linux + Darwin) get the equivalent via
  # OLLAMA_MODELS so a user-invoked `ollama` CLI shares the same cache as the
  # system service would, instead of falling back to `~/.ollama/models`.
  ollamaModelsDir = "/var/lib/ollama/models";

  sharedPackages = with pkgs; [
    koboldcpp
    llama-cpp
    ollama
    (lib.lowPrio whisper-cpp)
  ]
  # AMD GPU extras: ROCm runtime + OpenCL (clr = Common Language Runtime)
  ++ lib.optionals cfg.gpuAmd [
    rocmPackages.rocm-runtime
    rocmPackages.clr
    amdgpu_top
  ]
  # Nvidia GPU extras
  ++ lib.optionals cfg.gpuNvidia [
    cudaPackages.cudatoolkit
  ];
in
if isHomeManager then {
  home.packages = sharedPackages;
  # NOTE: on Darwin this still points at a Linux-style /var/lib path since
  # ollama itself defaults the same way cross-platform; if this ever needs to
  # differ per-OS, override OLLAMA_MODELS in the consuming host file instead
  # of editing this shared template.
  home.sessionVariables.OLLAMA_MODELS = ollamaModelsDir;
} else {
  environment.systemPackages = sharedPackages;

  # ── Ollama service ─────────────────────────────────────────────────────────
  services.ollama.enable = true;
  services.ollama.modelsDir = ollamaModelsDir;
}
