#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

BUTTON_MASK=0xfb EXPECTED_P0_HEX=0x4f sh "$SCRIPT_DIR/test-button.sh"
