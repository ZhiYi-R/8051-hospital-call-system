#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

BUTTON_MASK=0xf7 EXPECTED_P0_HEX=0x66 sh "$SCRIPT_DIR/test-button.sh"
