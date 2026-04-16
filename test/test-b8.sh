#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

BUTTON_MASK=0x7f EXPECTED_P0_HEX=0x7f sh "$SCRIPT_DIR/test-button.sh"
