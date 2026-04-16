#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

BUTTON_MASK=0xfe EXPECTED_P0_HEX=0x06 sh "$SCRIPT_DIR/test-button.sh"
