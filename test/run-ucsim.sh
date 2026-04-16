#!/bin/sh

set -eu

: "${UCSIM:?UCSIM is required}"
: "${UCSIM_CPU:?UCSIM_CPU is required}"
: "${TEST_LOG:?TEST_LOG is required}"

COMMAND_FILE=$(mktemp "${TMPDIR:-/tmp}/ucsim-command.XXXXXX")
RAW_LOG=$(mktemp "${TMPDIR:-/tmp}/ucsim-raw.XXXXXX")
trap 'rm -f "$COMMAND_FILE" "$RAW_LOG"' EXIT HUP INT TERM

cat >"$COMMAND_FILE"
"$UCSIM" -t "$UCSIM_CPU" -c "$COMMAND_FILE" >"$RAW_LOG"

grep -E '^(P0|P3)[[:space:]]' "$RAW_LOG" >"$TEST_LOG"
