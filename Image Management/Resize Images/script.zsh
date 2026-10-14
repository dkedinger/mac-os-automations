#!/bin/zsh
# Resize Images — Finder Quick Action
# Resizes selected images in place while preserving aspect ratio.
# Smaller images are not enlarged. DPI metadata is set to 72, 150, or 300.

set -u

TITLE="Resize Images"

notify() {
    [[ "${RESIZE_IMAGES_NO_NOTIFY:-0}" == "1" ]] && return 0
    /usr/bin/osascript - "$1" "$TITLE" <<'APPLESCRIPT' >/dev/null 2>&1
on run argv
    display notification (item 1 of argv) with title (item 2 of argv)
end run
APPLESCRIPT
}

alert_error() {
    /usr/bin/osascript - "$1" "$TITLE" <<'APPLESCRIPT' >/dev/null 2>&1
on run argv
    display alert (item 2 of argv) message (item 1 of argv) as critical
end run
APPLESCRIPT
}

prompt_for_options() {
    /usr/bin/osascript <<'APPLESCRIPT'
use framework "AppKit"
use scripting additions

on run
    set nsApp to current application's NSApplication's sharedApplication()
    nsApp's setActivationPolicy:(current application's NSApplicationActivationPolicyAccessory)
    nsApp's activateIgnoringOtherApps:true

    set panelWidth to 390
    set accessoryView to current application's NSView's alloc()'s initWithFrame:{{0, 0}, {panelWidth, 132}}

    set dimensionLabel to current application's NSTextField's labelWithString:"Limit by:"
    dimensionLabel's setFrame:{{0, 101}, {105, 22}}
    dimensionLabel's setAlignment:(current application's NSTextAlignmentRight)
    accessoryView's addSubview:dimensionLabel

    set dimensionMenu to current application's NSPopUpButton's alloc()'s initWithFrame:{{115, 98}, {250, 28}} pullsDown:false
    dimensionMenu's addItemsWithTitles:{"Maximum width", "Maximum height"}
    accessoryView's addSubview:dimensionMenu

    set pixelsLabel to current application's NSTextField's labelWithString:"Maximum size:"
    pixelsLabel's setFrame:{{0, 61}, {105, 22}}
    pixelsLabel's setAlignment:(current application's NSTextAlignmentRight)
    accessoryView's addSubview:pixelsLabel

    set pixelsField to current application's NSTextField's alloc()'s initWithFrame:{{115, 59}, {170, 26}}
    pixelsField's setStringValue:"1600"
    pixelsField's setPlaceholderString:"Pixels"
    accessoryView's addSubview:pixelsField

    set pixelsSuffix to current application's NSTextField's labelWithString:"pixels"
    pixelsSuffix's setFrame:{{295, 61}, {70, 22}}
    accessoryView's addSubview:pixelsSuffix

    set dpiLabel to current application's NSTextField's labelWithString:"Resolution:"
    dpiLabel's setFrame:{{0, 21}, {105, 22}}
    dpiLabel's setAlignment:(current application's NSTextAlignmentRight)
    accessoryView's addSubview:dpiLabel

    set dpiMenu to current application's NSPopUpButton's alloc()'s initWithFrame:{{115, 18}, {170, 28}} pullsDown:false
    dpiMenu's addItemsWithTitles:{"72 DPI", "150 DPI", "300 DPI"}
    accessoryView's addSubview:dpiMenu

    set theAlert to current application's NSAlert's alloc()'s init()
    theAlert's setMessageText:"Resize selected images"
    theAlert's setInformativeText:"Aspect ratio is preserved. Smaller images are not enlarged. Selected files are changed in place."
    theAlert's addButtonWithTitle:"Resize"
    theAlert's addButtonWithTitle:"Cancel"
    theAlert's setAccessoryView:accessoryView
    theAlert's window()'s setInitialFirstResponder:pixelsField

    set response to theAlert's runModal()
    if (response as integer) is not equal to (current application's NSAlertFirstButtonReturn as integer) then error number -128

    set dimensionIndex to dimensionMenu's indexOfSelectedItem() as integer
    if dimensionIndex is 0 then
        set dimensionMode to "width"
    else
        set dimensionMode to "height"
    end if

    set pixelValue to pixelsField's stringValue() as text
    set dpiIndex to dpiMenu's indexOfSelectedItem() as integer
    set dpiValues to {"72", "150", "300"}
    set dpiValue to item (dpiIndex + 1) of dpiValues

    return dimensionMode & tab & pixelValue & tab & dpiValue
end run
APPLESCRIPT
}

mode="${RESIZE_IMAGES_MAX_DIMENSION:-}"
pixels="${RESIZE_IMAGES_MAX_PIXELS:-}"
dpi="${RESIZE_IMAGES_DPI:-}"

if [[ -z "$mode" || -z "$pixels" || -z "$dpi" ]]; then
    dialog_result="$(prompt_for_options 2>/dev/null)" || exit 0
    IFS=$'\t' read -r mode pixels dpi <<< "$dialog_result"
fi

if [[ "$mode" != "width" && "$mode" != "height" ]]; then
    alert_error "Choose either Maximum width or Maximum height."
    exit 1
fi

if [[ ! "$pixels" =~ '^[0-9]+$' ]] || (( pixels < 1 || pixels > 100000 )); then
    alert_error "Enter a maximum size from 1 to 100,000 pixels."
    exit 1
fi

if [[ "$dpi" != "72" && "$dpi" != "150" && "$dpi" != "300" ]]; then
    alert_error "Choose 72, 150, or 300 DPI."
    exit 1
fi

processed=0
resized=0
failed=0
failed_names=()

for file in "$@"; do
    [[ -f "$file" ]] || continue

    width_info="$(/usr/bin/sips -g pixelWidth "$file" 2>/dev/null)" || width_info=""
    height_info="$(/usr/bin/sips -g pixelHeight "$file" 2>/dev/null)" || height_info=""
    width="${width_info##*pixelWidth: }"
    height="${height_info##*pixelHeight: }"

    if [[ ! "$width" =~ '^[0-9]+$' || ! "$height" =~ '^[0-9]+$' ]]; then
        (( failed++ ))
        failed_names+=("${file:t}")
        continue
    fi

    should_resize=0
    if [[ "$mode" == "width" ]] && (( width > pixels )); then
        should_resize=1
        resize_args=(--resampleWidth "$pixels")
    elif [[ "$mode" == "height" ]] && (( height > pixels )); then
        should_resize=1
        resize_args=(--resampleHeight "$pixels")
    else
        resize_args=()
    fi

    if /usr/bin/sips "${resize_args[@]}" --setProperty dpiWidth "$dpi" --setProperty dpiHeight "$dpi" "$file" >/dev/null 2>&1; then
        (( processed++ ))
        (( should_resize )) && (( resized++ ))
    else
        (( failed++ ))
        failed_names+=("${file:t}")
    fi
done

if (( failed > 0 )); then
    failed_list="${(j:, :)failed_names}"
    alert_error "Updated $processed image(s). Couldn't update: $failed_list"
    exit 1
elif (( processed > 0 )); then
    notify "Updated $processed image(s); resized $resized. Resolution: $dpi DPI."
else
    alert_error "No supported image files were selected."
    exit 1
fi
