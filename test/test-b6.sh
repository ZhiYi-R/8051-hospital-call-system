#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

BUTTON_MASK=0xdf EXPECTED_P0_HEX=0x7d sh "$SCRIPT_DIR/test-button.sh"
