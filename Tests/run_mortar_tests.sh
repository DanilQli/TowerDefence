#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT/project.godot"
TEST_SCENE='res://Tests/MortarTowerTests.tscn'
LOCK_DIR="$ROOT/.mortar_tests.lock"
GODOT_BIN="${GODOT_BIN:-$(command -v godot || true)}"
if [[ -z "$GODOT_BIN" ]]; then
  echo "Godot 4 executable not found. Set GODOT_BIN=/path/to/godot." >&2
  exit 127
fi
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "A Mortar test run is already active, or a stale lock exists: $LOCK_DIR" >&2
  exit 2
fi
BACKUP="$(mktemp)"
LOG_DIR="$(mktemp -d)"
cp -p "$PROJECT" "$BACKUP"
restore() {
  cp -p "$BACKUP" "$PROJECT"
  rm -f "$BACKUP"
  rm -rf "$LOG_DIR" "$LOCK_DIR"
}
trap restore EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# --import waits for all resources and builds the global script-class cache on clean checkouts.
"$GODOT_BIN" --headless --path "$ROOT" --import >"$LOG_DIR/import.log" 2>&1
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' "$LOG_DIR/import.log"; then
  echo "Godot import/compile check failed; see $LOG_DIR/import.log" >&2
  exit 1
fi

# Run the test scene as the temporary main scene, restoring project.godot on every exit path.
python3 - "$PROJECT" "$TEST_SCENE" <<'PY'
import re, sys
from pathlib import Path
path, scene = Path(sys.argv[1]), sys.argv[2]
text = path.read_text(encoding="utf-8")
updated, count = re.subn(r'(?m)^run/main_scene="[^"]+"$', f'run/main_scene="{scene}"', text, count=1)
if count != 1:
    raise SystemExit("Could not find exactly one run/main_scene setting in project.godot")
path.write_text(updated, encoding="utf-8")
PY
set +e
"$GODOT_BIN" --headless --path "$ROOT" --quit-after 180 >"$LOG_DIR/tests.log" 2>&1
STATUS=$?
set -e
cat "$LOG_DIR/tests.log"
if [[ $STATUS -ne 0 ]] || ! grep -q 'MORTAR_TESTS PASS' "$LOG_DIR/tests.log" || grep -E 'SCRIPT ERROR|Parse Error|Mortar test failed|MORTAR_TESTS FAIL' "$LOG_DIR/tests.log"; then
  echo "Mortar test suite failed (exit $STATUS)." >&2
  exit 1
fi
