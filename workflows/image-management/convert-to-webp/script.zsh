# =====================================================================
#  Convert to WebP  —  Finder Quick Action
#  Right-click image(s) in Finder > Quick Actions > Convert to WebP
#
#  Needs Google's free "cwebp" tool. If it isn't already installed
#  (e.g. via Homebrew), the first run offers to download the official
#  copy from Google into ~/Library/Application Support/MESH/webp-tools.
#  No admin password and no Homebrew required.
# =====================================================================

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

QUALITY=80
WEBP_VERSION="1.6.0"
TOOLS_DIR="$HOME/Library/Application Support/MESH/webp-tools"
TITLE="Convert to WebP"

# ---------- small helpers for on-screen messages ----------
notify() {
    osascript - "$1" "$TITLE" <<'EOF' >/dev/null 2>&1
on run argv
    display notification (item 1 of argv) with title (item 2 of argv)
end run
EOF
}

alert() {
    osascript - "$1" "$TITLE" <<'EOF' >/dev/null 2>&1
on run argv
    display alert (item 2 of argv) message (item 1 of argv) as critical
end run
EOF
}

# Returns 0 if the person clicks "Download"
ask_to_download() {
    osascript - "$TITLE" <<'EOF' >/dev/null 2>&1
on run argv
    display dialog "This action needs Google's free WebP converter (cwebp), which isn't installed on this Mac yet." & return & return & "Download it now? It's a one-time setup and takes a few seconds." with title (item 1 of argv) buttons {"Cancel", "Download"} default button "Download" with icon note
end run
EOF
}

tool_works() { [[ -x "$1" ]] && "$1" -version >/dev/null 2>&1 }

# ---------- find or install cwebp ----------
CWEBP=""
GIF2WEBP=""

if command -v cwebp >/dev/null 2>&1; then
    CWEBP="$(command -v cwebp)"
    GIF2WEBP="$(command -v gif2webp 2>/dev/null)"
elif tool_works "$TOOLS_DIR/bin/cwebp"; then
    CWEBP="$TOOLS_DIR/bin/cwebp"
    GIF2WEBP="$TOOLS_DIR/bin/gif2webp"
else
    ask_to_download || exit 0

    case "$(uname -m)" in
        arm64)  PLATFORM="mac-arm64" ;;
        *)      PLATFORM="mac-x86-64" ;;
    esac
    PKG="libwebp-${WEBP_VERSION}-${PLATFORM}"
    URL="https://storage.googleapis.com/downloads.webmproject.org/releases/webp/${PKG}.tar.gz"
    TMP="$(mktemp -d)"

    notify "Downloading the WebP converter…"
    if ! curl -fsSL "$URL" -o "$TMP/webp.tar.gz" || ! tar -xzf "$TMP/webp.tar.gz" -C "$TMP"; then
        rm -rf "$TMP"
        alert "Couldn't download the WebP converter. Check your internet connection and try again."
        exit 1
    fi

    mkdir -p "$TOOLS_DIR/bin"
    cp "$TMP/$PKG/bin/cwebp" "$TMP/$PKG/bin/gif2webp" "$TOOLS_DIR/bin/" 2>/dev/null
    rm -rf "$TMP"
    chmod +x "$TOOLS_DIR/bin/"*
    xattr -dr com.apple.quarantine "$TOOLS_DIR" 2>/dev/null

    # Apple Silicon refuses to run unsigned programs; add a local signature if needed.
    if ! tool_works "$TOOLS_DIR/bin/cwebp"; then
        codesign --force --sign - "$TOOLS_DIR/bin/"* >/dev/null 2>&1
    fi

    if ! tool_works "$TOOLS_DIR/bin/cwebp"; then
        alert "The WebP converter downloaded but won't run on this Mac. Ask Daniel for help."
        exit 1
    fi

    CWEBP="$TOOLS_DIR/bin/cwebp"
    GIF2WEBP="$TOOLS_DIR/bin/gif2webp"
fi

# ---------- convert ----------
converted=0
failed=0
failed_names=()

for f in "$@"
do
    [[ -f "$f" ]] || continue
    ext="${(L)${f:e}}"
    base="${f%.*}"
    out="${base}.webp"
    ok=1

    case "$ext" in
        webp|avif)
            continue ;;
        png|jpg|jpeg|tif|tiff)
            "$CWEBP" -quiet -q "$QUALITY" "$f" -o "$out" || ok=0 ;;
        gif)
            if [[ -x "$GIF2WEBP" ]]; then
                "$GIF2WEBP" -quiet -q "$QUALITY" "$f" -o "$out" || ok=0
            else
                ok=0
            fi ;;
        *)
            # HEIC, BMP, etc.: let macOS turn it into a PNG first, then convert.
            tmp_dir="$(mktemp -d)"
            tmp_png="$tmp_dir/image.png"
            if sips -s format png "$f" --out "$tmp_png" >/dev/null 2>&1; then
                "$CWEBP" -quiet -q "$QUALITY" "$tmp_png" -o "$out" || ok=0
            else
                ok=0
            fi
            rm -rf "$tmp_dir" ;;
    esac

    if (( ok )); then
        (( converted++ ))
    else
        (( failed++ ))
        failed_names+=("${f:t}")
    fi

    # AVIF at quality 80 (optional — requires ImageMagick)
    # magick "$f" -quality 80 "${base}.avif"
done

# ---------- report ----------
if (( failed > 0 )); then
    alert "Converted $converted image(s). Couldn't convert: ${(j:, :)failed_names}"
elif (( converted > 0 )); then
    notify "Converted $converted image(s) to WebP."
fi
