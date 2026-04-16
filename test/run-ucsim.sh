#!/bin/sh

set -eu

: "${UCSIM:?UCSIM is required}"
: "${UCSIM_CPU:?UCSIM_CPU is required}"
: "${TEST_LOG:?TEST_LOG is required}"

SIMULATOR=$UCSIM
if ! command -v "$SIMULATOR" >/dev/null 2>&1; then
	for candidate in s51 ucsim_51 sdcc-ucsim_51; do
		if command -v "$candidate" >/dev/null 2>&1; then
			printf "warning: simulator '%s' not found, using '%s' instead\n" "$SIMULATOR" "$candidate" >&2
			SIMULATOR=$candidate
			break
		fi
	done
fi

if ! command -v "$SIMULATOR" >/dev/null 2>&1; then
	printf "error: simulator '%s' was not found\n" "$UCSIM" >&2
	printf "hint: install sdcc-ucsim or set UCSIM to s51, ucsim_51, or sdcc-ucsim_51\n" >&2
	exit 127
fi

COMMAND_FILE=$(mktemp "${TMPDIR:-/tmp}/ucsim-command.XXXXXX")
RAW_LOG=$(mktemp "${TMPDIR:-/tmp}/ucsim-raw.XXXXXX")
PHASE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/ucsim-phases.XXXXXX")
trap 'rm -f "$COMMAND_FILE" "$RAW_LOG"; rm -rf "$PHASE_DIR"' EXIT HUP INT TERM

cat >"$COMMAND_FILE"

SIMULATOR_VERSION=$("$SIMULATOR" -v 2>&1 | sed -n '1p')
RUN_FILE=$COMMAND_FILE

case "$SIMULATOR_VERSION" in
	*"0.6."*)
		MAIN_FILE="$PHASE_DIR/phase0.cmd"
		CURRENT_FILE=$MAIN_FILE
		HAS_BREAK=
		PHASE_INDEX=0

		: >"$MAIN_FILE"

		while IFS= read -r line || [ -n "$line" ]; do
			case "$line" in
				break\ *)
					HAS_BREAK=1
					printf '%s\n' "$line" >>"$CURRENT_FILE"
					;;
				delete\ *)
					printf '%s\n' "delete 1" >>"$CURRENT_FILE"
					;;
				step\ [0-9]*\ ms)
					MS_VALUE=${line#step }
					MS_VALUE=${MS_VALUE% ms}
					printf 'tick %s\n' "$((MS_VALUE * 11059))" >>"$CURRENT_FILE"
					;;
				run)
					if [ -n "${HAS_BREAK:-}" ]; then
						PHASE_INDEX=$((PHASE_INDEX + 1))
						NEXT_FILE="$PHASE_DIR/phase${PHASE_INDEX}.cmd"
						: >"$NEXT_FILE"
						printf 'commands 1 exec "%s"\n' "$NEXT_FILE" >>"$CURRENT_FILE"
						printf '%s\n' "$line" >>"$CURRENT_FILE"
						CURRENT_FILE=$NEXT_FILE
					else
						printf '%s\n' "$line" >>"$CURRENT_FILE"
					fi
					;;
				*)
					printf '%s\n' "$line" >>"$CURRENT_FILE"
					;;
			esac
		done <"$COMMAND_FILE"

		RUN_FILE=$MAIN_FILE
		;;
esac

# Different distros expose different wrapper names for the same simulator:
# - Ubuntu/Debian: s51
# - older Debian/Ubuntu packages: ucsim_51
# - Fedora: sdcc-ucsim_51
#
# Use the command console on stdin/stdout so the same scripted interaction works
# across both newer Fedora builds and Ubuntu's older uCsim package.
"$SIMULATOR" -t "$UCSIM_CPU" -c - <"$RUN_FILE" >"$RAW_LOG" 2>&1 || true

awk '
function hex_to_dec(hex, i, c, value) {
	hex = tolower(hex)
	value = 0
	for (i = 1; i <= length(hex); i++) {
		c = substr(hex, i, 1)
		value *= 16
		if (c >= "0" && c <= "9") {
			value += c + 0
		} else {
			value += index("abcdef", c) + 9
		}
	}
	return value
}

function emit_port(name, hex, value, bit, bits) {
	value = hex_to_dec(hex)
	bits = ""
	for (bit = 7; bit >= 0; bit--) {
		bits = bits int(value / (2 ^ bit)) % 2
	}
	printf "%s    %s 0x%s\n", name, bits, tolower(hex)
}

/^0x80[[:space:]]+[0-9A-Fa-f][0-9A-Fa-f][[:space:]]/ {
	emit_port("P0", $2)
	next
}

/^0xb0[[:space:]]+[0-9A-Fa-f][0-9A-Fa-f][[:space:]]/ {
	emit_port("P3", $2)
	next
}

/^(P0|P3)[[:space:]]/ {
	print
}
' "$RAW_LOG" >"$TEST_LOG"
