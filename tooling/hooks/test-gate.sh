#!/usr/bin/env bash
# tooling/hooks/test-gate.sh
#
# Quality gate — run by the Claude Code Stop hook (.claude/settings.json) and
# usable manually before pushing.
#
# Checks, in order (all run, failures are reported together):
#   1. flutter analyze
#   2. dart run custom_lint   (solid_lints complexity metrics)
#   3. flutter test test/unit test/widget
#
# Skipped (exit 0) when nothing relevant changed in the working tree, so
# read-only sessions stop instantly. Pass --force to run anyway.
#
# Exit codes: 0 = green, 2 = red (blocks the Claude Code Stop event and feeds
# stderr back to Claude), 3 = unknown flag.

set -uo pipefail

cd "$(dirname "$0")/../.." || exit 3

FORCE=false
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    *) echo "Unknown flag: $arg" >&2; exit 3 ;;
  esac
done

# ── Early exit: no tracked change under the gated paths ──────────────────────
GATED_PATHS=(lib test cli assets pubspec.yaml analysis_options.yaml)
if [ "$FORCE" = false ] \
   && git rev-parse --git-dir >/dev/null 2>&1 \
   && [ -z "$(git status --porcelain -- "${GATED_PATHS[@]}" 2>/dev/null)" ]; then
  exit 0
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "test-gate: flutter not found on PATH — gate skipped" >&2
  exit 0
fi

# Flutter warns on stderr when run as root (containers, cloud sessions) and
# custom_lint reports any plugin stderr output as a failure (exit 1). Flutter
# skips that warning when it believes it runs on CI.
if [ "$(id -u)" = "0" ]; then
  export CI=true
fi

LOG_DIR="$(mktemp -d)"
trap 'rm -rf "$LOG_DIR"' EXIT
FAILED=()

run_step() {
  local name="$1"; shift
  local log="$LOG_DIR/$name.log"
  echo "── $name"
  if ! "$@" >"$log" 2>&1; then
    FAILED+=("$name")
    {
      echo "════ $name FAILED ════"
      # Keep the useful tail; analyzer and test output can be long.
      tail -60 "$log"
    } >&2
  fi
}

run_step analyze flutter analyze --no-pub
run_step custom_lint dart run custom_lint

TEST_DIRS=()
for dir in test/unit test/widget; do
  [ -d "$dir" ] && TEST_DIRS+=("$dir")
done
if [ ${#TEST_DIRS[@]} -gt 0 ]; then
  run_step tests flutter test --no-pub "${TEST_DIRS[@]}"
fi

if [ ${#FAILED[@]} -gt 0 ]; then
  echo "test-gate: RED (${FAILED[*]})" >&2
  exit 2
fi

echo "test-gate: GREEN"
exit 0
