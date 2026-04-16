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
delete 1
set hw port[2] 0xfe
step 30 ms
break sfr w 0x80
set hw port[2] 0xff
run
step 10
info hw port[3]
step 950 ms
info hw port[3]
step 20 ms
info hw port[3]
quit
EOF

sed -n '1p' "$TEST_LOG" | grep -Eq 'P3[[:space:]]+11111111[[:space:]]+0xff'
sed -n '2p' "$TEST_LOG" | grep -Eq 'P3[[:space:]]+11111111[[:space:]]+0xff'
sed -n '3p' "$TEST_LOG" | grep -Eq 'P3[[:space:]]+01111111[[:space:]]+0x7f'
