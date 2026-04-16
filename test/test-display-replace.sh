#!/bin/sh

set -eu

: "${UCSIM:?UCSIM is required}"
: "${UCSIM_CPU:?UCSIM_CPU is required}"
: "${TEST_OUTPUT:?TEST_OUTPUT is required}"
: "${TEST_LOG:?TEST_LOG is required}"

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

cat <<EOF | sh "$SCRIPT_DIR/run-ucsim.sh"
file "$TEST_OUTPUT"
break sfr w 0x80
run
info hw port[0]
delete 1
set hw port[2] 0xfe
step 30 ms
break sfr w 0x80
set hw port[2] 0xff
run
info hw port[0]
delete 2
step 1200 ms
info hw port[0]
set hw port[2] 0xfb
step 30 ms
break sfr w 0x80
set hw port[2] 0xff
run
info hw port[0]
step 1200 ms
info hw port[0]
quit
EOF

grep -Eq 'P0[[:space:]]+00000000[[:space:]]+0x00' "$TEST_LOG"

first_display_count=$(grep -Ec 'P0[[:space:]]+00000110[[:space:]]+0x06' "$TEST_LOG")
[ "$first_display_count" -ge 2 ]

second_display_count=$(grep -Ec 'P0[[:space:]]+01001111[[:space:]]+0x4f' "$TEST_LOG")
[ "$second_display_count" -ge 2 ]
