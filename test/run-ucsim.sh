#!/bin/sh

set -eu

: "${UCSIM:?UCSIM is required}"
: "${UCSIM_CPU:?UCSIM_CPU is required}"
: "${TEST_LOG:?TEST_LOG is required}"

COMMAND_FILE=$(mktemp "${TMPDIR:-/tmp}/ucsim-command.XXXXXX")
RAW_LOG=$(mktemp "${TMPDIR:-/tmp}/ucsim-raw.XXXXXX")
trap 'rm -f "$COMMAND_FILE" "$RAW_LOG"' EXIT HUP INT TERM

cat >"$COMMAND_FILE"

# Different distros use different command names:
# - Fedora: sdcc-ucsim_51 (needs -t parameter)
# - Debian/Ubuntu: ucsim_51 (needs -t parameter)
"$UCSIM" -t "$UCSIM_CPU" -c "$COMMAND_FILE" </dev/null >"$RAW_LOG" 2>&1 || true

grep -E '^(P0|P3)[[:space:]]' "$RAW_LOG" >"$TEST_LOG" || true
