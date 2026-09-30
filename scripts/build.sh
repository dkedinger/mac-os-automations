#!/usr/bin/env bash
# Rebuild the downloadable files for every Quick Action in workflows/.
#
# For each workflows/<category>/<action>/<Name>.workflow this writes, next to it:
#   <Name>.zip   – what people download (README links point here)
#   script.zsh   – the embedded "Run Shell Script" source, for easy reading/diffing
#
# Run from anywhere:  ./scripts/build.sh
# Commit the regenerated files together with any change to a .workflow.

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

make_zip() {
    local dir="$1" name="$2"
    rm -f "$dir/$name.zip"
    if command -v ditto >/dev/null 2>&1; then
        (cd "$dir" && ditto -c -k --sequesterRsrc --keepParent "$name.workflow" "$name.zip")
    else
        (cd "$dir" && zip -qrX "$name.zip" "$name.workflow" -x '*.DS_Store')
    fi
}

built=0
for workflow in workflows/*/*/*.workflow; do
    dir="$(dirname "$workflow")"
    name="$(basename "$workflow" .workflow)"

    make_zip "$dir" "$name"

    if ! extract_script "$workflow/Contents/document.wflow" "$dir/script.zsh" || [[ ! -s "$dir/script.zsh" ]]; then
        rm -f "$dir/script.zsh"
        echo "note: $workflow has no Run Shell Script as its first action; skipped script.zsh" >&2
    fi

    echo "built $dir/$name.zip"
    built=$((built + 1))
done

if (( built == 0 )); then
    echo "No workflows found under workflows/<category>/<action>/" >&2
    exit 1
fi
