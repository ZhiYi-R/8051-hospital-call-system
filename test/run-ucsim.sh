#!/bin/sh

set -eu

: "${UCSIM:?UCSIM is required}"
: "${UCSIM_CPU:?UCSIM_CPU is required}"
: "${TEST_LOG:?TEST_LOG is required}"

COMMAND_FILE=$(mktemp "${TMPDIR:-/tmp}/ucsim-command.XXXXXX")
RAW_LOG=$(mktemp "${TMPDIR:-/tmp}/ucsim-raw.XXXXXX")
trap 'rm -f "$COMMAND_FILE" "$RAW_LOG"' EXIT HUP INT TERM

cat >"$COMMAND_FILE"

# s51 (Ubuntu) doesn't need -t parameter, ucsim_51 (Fedora) does
if echo "$UCSIM" | grep -q "s51"; then
    "$UCSIM" -c "$COMMAND_FILE" >"$RAW_LOG"
else
    "$UCSIM" -t "$UCSIM_CPU" -c "$COMMAND_FILE" >"$RAW_LOG"
fi

grep -E '^(P0|P3)[[:space:]]' "$RAW_LOG" >"$TEST_LOG"
