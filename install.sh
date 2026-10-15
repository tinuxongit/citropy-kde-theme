#!/bin/sh
set -eu

THEME_NAME="Citropy"
CURSOR_NAME="Citropy-Cursors"
FONT_FAMILY="Citropy Sans"
FONT_SIZE=10
SMALL_FONT_SIZE=8
FONT_TAIL="-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

SOURCE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DATA_DIR=${XDG_DATA_HOME:-$HOME/.local/share}
CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}
STATE_DIR="$CONFIG_DIR/citropy-kde-theme"
STATE_FILE="$STATE_DIR/previous.conf"
ICON_CHANGER=/usr/lib/plasma-changeicons

for tool in kreadconfig6 kwriteconfig6 fc-cache; do
  command -v "$tool" >/dev/null 2>&1 || { printf 'missing required tool: %s\n' "$tool" >&2; exit 1; }
done

font_value() {
  printf '%s,%s,%s' "$FONT_FAMILY" "$1" "$FONT_TAIL"
}

settings_table() {
  printf '%s\n' \
    "kdeglobals|General|font|$(font_value "$FONT_SIZE")" \
    "kdeglobals|General|menuFont|$(font_value "$FONT_SIZE")" \
    "kdeglobals|General|toolBarFont|$(font_value "$FONT_SIZE")" \
    "kdeglobals|General|smallestReadableFont|$(font_value "$SMALL_FONT_SIZE")" \
    "kdeglobals|WM|activeFont|$(font_value "$FONT_SIZE")" \
    "kdeglobals|Icons|Theme|$THEME_NAME" \
    "kcminputrc|Mouse|cursorTheme|$CURSOR_NAME"
}

if [ ! -f "$STATE_FILE" ]; then
  mkdir -p "$STATE_DIR"
  settings_table | while IFS='|' read -r file group key _; do
    previous=$(kreadconfig6 --file "$file" --group "$group" --key "$key")
    printf '%s|%s|%s|%s\n' "$file" "$group" "$key" "$previous"
  done > "$STATE_FILE"
fi

mkdir -p "$DATA_DIR/icons" "$DATA_DIR/fonts"
rm -rf "$DATA_DIR/icons/$THEME_NAME" "$DATA_DIR/icons/$CURSOR_NAME" "$DATA_DIR/fonts/CitropySans"
cp -r "$SOURCE_DIR/icons/$THEME_NAME" "$DATA_DIR/icons/$THEME_NAME"
cp -r "$SOURCE_DIR/cursors/$CURSOR_NAME" "$DATA_DIR/icons/$CURSOR_NAME"
mkdir -p "$DATA_DIR/fonts/CitropySans"
cp "$SOURCE_DIR/fonts/CitropySans.ttf" "$SOURCE_DIR/fonts/CitropySans-OFL.txt" "$DATA_DIR/fonts/CitropySans/"
fc-cache -f "$DATA_DIR/fonts"

settings_table | while IFS='|' read -r file group key value; do
  kwriteconfig6 --file "$file" --group "$group" --key "$key" "$value"
done

if [ -x "$ICON_CHANGER" ]; then "$ICON_CHANGER" "$THEME_NAME"; fi
if command -v plasma-apply-cursortheme >/dev/null 2>&1; then plasma-apply-cursortheme "$CURSOR_NAME"; fi

printf 'Installed. Log out and in so every running app picks up the font and icons.\n'
