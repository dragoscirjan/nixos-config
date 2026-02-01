#!/usr/bin/env bash
#
# Audio Recovery Script for NixOS with PipeWire
# Force kills and restarts audio - no systemctl waits
#
# Usage: fix-audio.sh [--usb-reset] [--alsa]
#

set -uo pipefail

echo "=== NixOS Audio Recovery ==="

# Step 1: Force kill everything (no waiting)
echo "[1/4] Killing audio processes..."
pkill -9 pipewire 2>/dev/null || true
pkill -9 wireplumber 2>/dev/null || true
sleep 0.5

# Step 2: Clear state
echo "[2/4] Clearing state..."
rm -rf ~/.local/state/wireplumber/* 2>/dev/null || true
rm -rf ~/.local/state/pipewire/* 2>/dev/null || true

# Step 3: Reset failed systemd state (don't wait)
systemctl --user reset-failed 2>/dev/null &

# Step 4: USB reset if requested
if [[ "${1:-}" == "--usb-reset" ]]; then
    echo "[3/4] Resetting USB audio devices..."
    for f in /sys/bus/usb/devices/*/product; do
        [[ -f "$f" ]] || continue
        if grep -qiE "audio|headset|epos|jabra" "$f" 2>/dev/null; then
            dev=$(dirname "$f")
            echo "  Resetting: $(cat "$f")"
            sudo sh -c "echo 0 > $dev/authorized; sleep 0.3; echo 1 > $dev/authorized" 2>/dev/null || true
        fi
    done
    sleep 1
elif [[ "${1:-}" == "--alsa" ]]; then
    echo "[3/4] Reloading ALSA modules..."
    sudo modprobe -r snd_usb_audio snd_hda_intel 2>/dev/null || true
    sleep 0.5
    sudo modprobe snd_hda_intel snd_usb_audio 2>/dev/null || true
    sleep 1
else
    echo "[3/4] Skipped (use --usb-reset or --alsa)"
fi

# Step 5: Start fresh via socket activation
echo "[4/4] Starting audio services..."
systemctl --user start pipewire.socket pipewire-pulse.socket 2>/dev/null
sleep 2

# Verify
echo ""
echo "=== Status ==="
if timeout 2 wpctl status 2>/dev/null | grep -q "Audio"; then
    timeout 2 wpctl status 2>/dev/null | grep -A10 "Sinks:" | head -12
    echo ""
    echo "Audio restored!"
else
    echo "Services starting... try playing audio in a few seconds."
    echo "If still broken, run: $0 --usb-reset"
fi
