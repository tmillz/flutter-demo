#!/usr/bin/env bash
# Takes a screenshot of the home screen and commits it.
# Usage: ./scripts/screenshot.sh [--no-commit]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCREENSHOT_PATH="$REPO_ROOT/screenshots/home-screen.png"
NO_COMMIT=false

for arg in "$@"; do
  [[ "$arg" == "--no-commit" ]] && NO_COMMIT=true
done

# ── Prerequisites ─────────────────────────────────────────────────────────────
check_cmd() {
  local cmd="$1"
  command -v "$cmd" &>/dev/null || { echo "Error: '$cmd' is not installed." >&2; exit 1; }
}
check_cmd flutter
check_cmd firebase
check_cmd node
check_cmd npm
check_cmd python3

# ── Cleanup on exit ───────────────────────────────────────────────────────────
EMULATOR_PID=""
SERVE_PID=""
cleanup() {
  [[ -n "$SERVE_PID" ]]   && kill "$SERVE_PID"   2>/dev/null || true
  [[ -n "$EMULATOR_PID" ]] && kill "$EMULATOR_PID" 2>/dev/null || true
}
trap cleanup EXIT

cd "$REPO_ROOT"

# ── 1. Build ──────────────────────────────────────────────────────────────────
echo "Building Flutter web..."
flutter build web --dart-define=USE_EMULATORS=true

# ── 2. Install Playwright (local, no global pollution) ────────────────────────
echo "Installing Playwright..."
npm install --no-save --ignore-scripts playwright serve 2>/dev/null
./node_modules/.bin/playwright install --with-deps chromium 2>/dev/null

# ── 3. Start Firebase emulators ───────────────────────────────────────────────
echo "Starting Firebase emulators..."
firebase emulators:start --only auth,firestore,storage \
  --import=./firebase-export --project tmillz &>/tmp/firebase-emulator.log &
EMULATOR_PID=$!

echo "Waiting for Firestore emulator on port 8080..."
for i in $(seq 1 60); do
  curl -s http://localhost:8080 > /dev/null && echo "Emulators ready." && break || sleep 2
done

# ── 4. Serve the build ────────────────────────────────────────────────────────
echo "Serving build/web on port 3000..."
./node_modules/.bin/serve build/web -p 3000 &>/tmp/serve.log &
SERVE_PID=$!

for i in $(seq 1 30); do
  curl -s http://localhost:3000 > /dev/null && break || sleep 1
done

# ── 5. Take the screenshot ────────────────────────────────────────────────────
echo "Taking screenshot..."
mkdir -p screenshots
node "$REPO_ROOT/scripts/take_screenshot.js"
echo "Screenshot saved to $SCREENSHOT_PATH"

# ── 6. Update README ──────────────────────────────────────────────────────────
python3 "$REPO_ROOT/scripts/update_readme.py"
echo "README updated."

# ── 7. Commit ─────────────────────────────────────────────────────────────────
if [[ "$NO_COMMIT" == false ]]; then
  git add screenshots/home-screen.png README.md
  if git diff --staged --quiet; then
    echo "No changes to commit."
  else
    git commit -m "chore: update home screen screenshot"
    echo "Committed. Run 'git push' when ready."
  fi
fi
