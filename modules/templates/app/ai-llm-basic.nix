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

  # Ollama's own cache is a content-addressed manifest+blobs store (no
  # .gguf extension/model name in the filename) and isn't practically
  # shareable with the other local-LLM tools below, so it stays separate
  # (see ollamaModelsDir* above).
  #
  # llama-cpp, koboldcpp (a llama.cpp fork), and LM Studio's default
  # (non-MLX) downloads all use the plain .gguf format and CAN share one
  # folder on disk:
  #   - llama-cpp honors the LLAMA_CACHE env var for its --hf-repo
  #     auto-download feature (falls back to ~/.cache/llama.cpp /
  #     ~/Library/Caches/llama.cpp otherwise) — wired below.
  #   - koboldcpp doesn't auto-download; point its --model flag at this
  #     same folder manually.
  #   - LM Studio has no env var/CLI override for its model directory —
  #     it must be changed manually via its GUI ("My Models" tab) to
  #     point at this same folder; cannot be automated via Nix.
  # NixOS: config.users.users.dragosc.home is a real, pre-expanded
  # absolute path (no shell expansion available in environment.variables).
  llamaModelsDirNixos = config.users.users.dragosc.home + "/Models/gguf";
  # Home Manager: $HOME is expanded correctly since home.sessionVariables
  # generates a real shell script (hm-session-vars.sh), unlike NixOS's
  # environment.sessionVariables which is PAM-based and does NOT expand.
  llamaModelsDirHome = "$HOME/Models/gguf";

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
  home.sessionVariables.LLAMA_CACHE = llamaModelsDirHome;
  # Pre-create the shared GGUF folder so llama-cpp doesn't fail on first
  # run against a missing directory. Never touches OLLAMA's own cache dir.
  home.activation.ensureLlamaModelsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${llamaModelsDirHome}"
  '';
} else {
  environment.systemPackages = sharedPackages;
  environment.variables.LLAMA_CACHE = llamaModelsDirNixos;

  # ── Ollama service ─────────────────────────────────────────────────────────
  services.ollama.enable = true;
  services.ollama.modelsDir = ollamaModelsDirNixos;

  # Pre-create the shared GGUF folder (owned by the user) so llama-cpp
  # doesn't fail on first run against a missing directory.
  systemd.tmpfiles.rules = [
    "d ${llamaModelsDirNixos} 0755 ${config.users.users.dragosc.name} users -"
  ];
}
