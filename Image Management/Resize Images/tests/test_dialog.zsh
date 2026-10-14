#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
SOURCE="${SCRIPT_DIR:h}/script.zsh"
TMP_SCRIPT="${TMPDIR:-/tmp}/resize-images-dialog-test-$$.applescript"
STDOUT_FILE="${TMPDIR:-/tmp}/resize-images-dialog-test-$$.out"
STDERR_FILE="${TMPDIR:-/tmp}/resize-images-dialog-test-$$.err"

cleanup() {
    if [[ -n "${dialog_pid:-}" ]] && /bin/kill -0 "$dialog_pid" 2>/dev/null; then
        /bin/kill "$dialog_pid" 2>/dev/null || true
        wait "$dialog_pid" 2>/dev/null || true
    fi
    /bin/rm -f "$TMP_SCRIPT" "$STDOUT_FILE" "$STDERR_FILE"
}
trap cleanup EXIT

/usr/local/bin/python3 - "$SOURCE" "$TMP_SCRIPT" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text()
start = source.index('use framework "AppKit"')
end = source.index("\nAPPLESCRIPT", start)
Path(sys.argv[2]).write_text(source[start:end] + "\n")
PY

/usr/bin/osacompile -o "${TMP_SCRIPT:r}.scpt" "$TMP_SCRIPT"
/bin/rm -f "${TMP_SCRIPT:r}.scpt"

/usr/bin/osascript "$TMP_SCRIPT" >"$STDOUT_FILE" 2>"$STDERR_FILE" &
dialog_pid=$!
/bin/sleep 2

if ! /bin/kill -0 "$dialog_pid" 2>/dev/null; then
    wait "$dialog_pid" || exit_status=$?
    print -u2 "Dialog exited before it could accept user input (status ${exit_status:-0})."
    [[ ! -s "$STDERR_FILE" ]] || /bin/cat "$STDERR_FILE" >&2
    exit 1
fi

print "PASS: dialog remains open awaiting user input"
