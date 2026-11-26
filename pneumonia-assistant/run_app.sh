#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FYP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BACKEND_DIR="$FYP_DIR/pneumonia-assistant-main/pneumonia-assistant"
FRONTEND_DIR="$SCRIPT_DIR"

echo "=================================================="
echo " Starting Pneumonia Assistant (Backend + Flutter) "
echo "=================================================="

# 1. Start FastAPI backend in background
echo "[1/2] Starting FastAPI ML Backend (port 8000)..."
cd "$BACKEND_DIR"
"$BACKEND_DIR/.venv/bin/uvicorn" app:app --host 127.0.0.1 --port 8000 > /tmp/pneumonia_api.log 2>&1 &
BACKEND_PID=$!

# Cleanup background process on exit
cleanup() {
    echo ""
    echo "Stopping FastAPI backend (PID: $BACKEND_PID)..."
    kill "$BACKEND_PID" 2>/dev/null || true
    echo "Done."
}
trap cleanup EXIT INT TERM

# Wait for backend to be ready
echo "Waiting for ML models to load..."
READY=0
for i in {1..25}; do
    if curl -s http://127.0.0.1:8000/docs >/dev/null 2>&1; then
        READY=1
        break
    fi
    sleep 0.4
done

if [ "$READY" -eq 1 ]; then
    echo "✓ FastAPI Backend is online (Stage 1 & Stage 2 models active)."
else
    echo "⚠ Warning: Backend startup took longer than usual. Check /tmp/pneumonia_api.log"
fi

# 2. Launch Flutter App in Chromium
echo "[2/2] Launching Flutter Companion in Chromium..."
cd "$FRONTEND_DIR"
export CHROME_EXECUTABLE=/usr/bin/chromium
# The demo build has no Firebase sign-in, so give it the backend key from .env.
API_KEY_VALUE="$(grep -E '^API_KEY=' "$BACKEND_DIR/.env" | cut -d= -f2-)"
flutter run -d chrome --dart-define=API_KEY="$API_KEY_VALUE"
