#!/usr/bin/env bash
# Refresh generated files for every Quick Action in workflows/.
#
# For each workflows/<category>/<action>/<Name>.workflow this writes, next to it:
#   script.zsh   – the embedded "Run Shell Script" source, for easy reading/diffing
#
# It also checks that <Name>.zip exists. The zip is NOT generated here: make it
# on a Mac from the installed copy in ~/Library/Services (see README), because
# the workflow's code signature lives in extended attributes that git can't store.
#
# Run from anywhere:  ./scripts/build.sh

set -euo pipefail
shopt -s nullglob

cd "$(dirname "$0")/.."

SCRIPT_KEY="actions.0.action.ActionParameters.COMMAND_STRING"

extract_script() {
    local wflow="$1" out="$2"
    if command -v plutil >/dev/null 2>&1; then
        plutil -extract "$SCRIPT_KEY" raw -o - "$wflow" >"$out" 2>/dev/null
    else
        python3 - "$wflow" >"$out" <<'EOF'
import plistlib, sys
with open(sys.argv[1], "rb") as f:
    doc = plistlib.load(f)
sys.stdout.write(doc["actions"][0]["action"]["ActionParameters"]["COMMAND_STRING"])
EOF
    fi
}

found=0
missing_zip=0
for workflow in workflows/*/*/*.workflow; do
    dir="$(dirname "$workflow")"
    name="$(basename "$workflow" .workflow)"
    found=$((found + 1))

    if extract_script "$workflow/Contents/document.wflow" "$dir/script.zsh" && [[ -s "$dir/script.zsh" ]]; then
        echo "wrote $dir/script.zsh"
    else
        rm -f "$dir/script.zsh"
        echo "note: $workflow has no Run Shell Script as its first action; skipped script.zsh" >&2
    fi

    if [[ ! -f "$dir/$name.zip" ]]; then
        echo "missing: $dir/$name.zip (make it on a Mac, see README)" >&2
        missing_zip=$((missing_zip + 1))
    fi
done

if (( found == 0 )); then
    echo "No workflows found under workflows/<category>/<action>/" >&2
    exit 1
fi
(( missing_zip == 0 ))
