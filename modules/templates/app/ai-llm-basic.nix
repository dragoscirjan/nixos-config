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
  # behavior.
  ollamaModelsDirNixos = "/var/lib/ollama/models";
  # Home Manager contexts (Linux + Darwin) don't have a writable /var/lib —
  # that path is owned by the NixOS ollama systemd service, not the user.
  # Use a per-user location instead so a user-invoked `ollama` CLI has a
  # single, consistent, writable cache regardless of host OS.
  ollamaModelsDirHome = "$HOME/.ollama/models";

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
  # See ollamaModelsDirHome comment above — user-writable path, not the
  # NixOS-service-owned /var/lib/ollama/models.
  home.sessionVariables.OLLAMA_MODELS = ollamaModelsDirHome;
} else {
  environment.systemPackages = sharedPackages;

  # ── Ollama service ─────────────────────────────────────────────────────────
  services.ollama.enable = true;
  services.ollama.modelsDir = ollamaModelsDirNixos;
}
