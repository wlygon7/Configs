#!/usr/bin/env bash
# Clipboard history in wofi, with thumbnails for copied images. Bound to SUPER+V in hyprland.lua.
# Picks an entry from cliphist and puts it back on the clipboard.
#
# Each row starts with "<id>:" inside an invisible span (a tab there would render as a wide indent).
# wofi's parse_action strips the markup from the chosen row, leaving "<id>:<text>", which is turned
# back into the "<id>\t<text>" form `cliphist decode` reads.

thumbs="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/thumbs"
mkdir -p "$thumbs"

escape() {
    local s=${1//&/&amp;}
    s=${s//</&lt;}
    printf '%s' "${s//>/&gt;}"
}

hidden_id() {
    printf '<span size="1" alpha="1">%s:</span>' "$1"
}

entries() {
    cliphist list | while IFS=$'\t' read -r id preview; do
        # Images show up as e.g. "[[ binary data 83 KiB png 1920x1080 ]]"
        if [[ $preview =~ ^\[\[\ binary\ data\ ([0-9.]+\ [KMG]?i?B)\ (png|jpe?g|webp|bmp|gif)\ ([0-9]+x[0-9]+) ]]; then
            thumb="$thumbs/$id.png"
            [[ -f $thumb ]] || printf '%s\t\n' "$id" | cliphist decode | magick - -thumbnail '128x128>' "$thumb" 2>/dev/null
            printf 'img:%s:text:%sImage  ·  %s  ·  %s\n' "$thumb" "$(hidden_id "$id")" "${BASH_REMATCH[3]}" "${BASH_REMATCH[1]}"
        else
            printf '%s%s\n' "$(hidden_id "$id")" "$(escape "$preview")"
        fi
    done
}

choice=$(entries | wofi --dmenu --prompt Clipboard --cache-file /dev/null \
    --define allow_markup=true --define dmenu-parse_action=true \
    --define image_size=48 --width 640 --height 520) || exit 0

printf '%s\n' "$choice" | sed -E 's/^([0-9]+):/\1\t/' | cliphist decode | wl-copy
