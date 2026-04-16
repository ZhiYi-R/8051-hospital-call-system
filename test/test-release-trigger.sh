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
step 100 ms
info hw port[0]
info hw port[3]
break sfr w 0x80
set hw port[2] 0xff
run
info hw port[0]
step 10
info hw port[3]
quit
EOF

blank_count=$(grep -Ec 'P0[[:space:]]+00000000[[:space:]]+0x00' "$TEST_LOG")
[ "$blank_count" -ge 2 ]

grep -Eq 'P3[[:space:]]+01111111[[:space:]]+0x7f' "$TEST_LOG"
grep -Eq 'P0[[:space:]]+00000110[[:space:]]+0x06' "$TEST_LOG"
grep -Eq 'P3[[:space:]]+11111111[[:space:]]+0xff' "$TEST_LOG"
