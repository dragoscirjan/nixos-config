{ pkgs }:

let
  # Create an FHS environment so `uv` and PyPI binary wheels run seamlessly
  fastcode-fhs = pkgs.buildFHSEnv {
    name = "fastcode-fhs";
    targetPkgs = pkgs: with pkgs; [
      python312
      git
      curl
      # C/C++ libraries needed by Python ML binary wheels
      stdenv.cc.cc.lib
      zlib
      glib
    ];
    runScript = "bash";
  };

  # The launcher script that gets added to the system PATH
  fastcode-launcher = pkgs.writeShellScriptBin "fastcode-mcp" ''
    FASTCODE_DIR="''${FASTCODE_DIR:-$HOME/.local/lib/fastcode}"
    
    # Auto-clone on first run if missing
    if [ ! -d "$FASTCODE_DIR" ]; then
      echo "FastCode not found at $FASTCODE_DIR. Cloning..."
      ${pkgs.git}/bin/git clone --depth 1 https://github.com/HKUDS/FastCode.git "$FASTCODE_DIR"
    fi

    # Create a default .env file ONLY if it doesn't exist.
    if [ ! -f "$FASTCODE_DIR/.env" ]; then
      echo "Creating default .env at $FASTCODE_DIR/.env"
      cat << 'ENVEOF' > "$FASTCODE_DIR/.env"
OPENAI_API_KEY=ollama
MODEL=qwen3-coder-30b_fastcode
BASE_URL=http://localhost:11434/v1
ENVEOF
      echo "Please edit $FASTCODE_DIR/.env with your preferred API keys and models."
    fi

    # Execute the FastCode MCP server via uv INSIDE the FHS environment
    cd "$FASTCODE_DIR"
    exec ${fastcode-fhs}/bin/fastcode-fhs -c "uv run python mcp_server.py"
  '';

  # The web launcher script that gets added to the system PATH
  fastcode-web = pkgs.writeShellScriptBin "fastcode-web" ''
    FASTCODE_DIR="''${FASTCODE_DIR:-$HOME/.local/lib/fastcode}"
    
    if [ ! -d "$FASTCODE_DIR" ]; then
      echo "FastCode not found. Please run fastcode-mcp first to initialize it."
      exit 1
    fi

    HOST="''${FASTCODE_WEB_HOST:-0.0.0.0}"
    PORT="''${FASTCODE_WEB_PORT:-5000}"

    # Parse optional flags
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --host) HOST="$2"; shift 2 ;;
        --port) PORT="$2"; shift 2 ;;
        -h|--help)
          echo "Usage: fastcode-web [--host HOST] [--port PORT]"
          echo "  --host HOST   Bind address (default: 0.0.0.0; env: FASTCODE_WEB_HOST)"
          echo "  --port PORT   Port number  (default: 5000;   env: FASTCODE_WEB_PORT)"
          exit 0
          ;;
        *) echo "Unknown option: $1  (use --help)" >&2; exit 1 ;;
      esac
    done

    # Execute the FastCode Web UI via uv INSIDE the FHS environment
    cd "$FASTCODE_DIR"
    echo "Starting FastCode Web UI at http://$HOST:$PORT"
    exec ${fastcode-fhs}/bin/fastcode-fhs -c "uv run python web_app.py --host $HOST --port $PORT"
  '';

in [
  fastcode-launcher
  fastcode-web
]
