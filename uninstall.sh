#!/bin/sh
set -eu

THEME_NAME="Citropy"
CURSOR_NAME="Citropy-Cursors"
FALLBACK_ICON_THEME="breeze-dark"
FALLBACK_CURSOR_THEME="breeze_cursors"

DATA_DIR=${XDG_DATA_HOME:-$HOME/.local/share}
CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}
STATE_DIR="$CONFIG_DIR/citropy-kde-theme"
STATE_FILE="$STATE_DIR/previous.conf"
ICON_CHANGER=/usr/lib/plasma-changeicons

[ -f "$STATE_FILE" ] || { printf 'no saved settings at %s, nothing to restore\n' "$STATE_FILE" >&2; exit 1; }

icon_theme=$FALLBACK_ICON_THEME
cursor_theme=$FALLBACK_CURSOR_THEME

while IFS='|' read -r file group key previous; do
  if [ -z "$previous" ]; then
    kwriteconfig6 --file "$file" --group "$group" --key "$key" --delete
  else
    kwriteconfig6 --file "$file" --group "$group" --key "$key" "$previous"
  fi
  if [ "$group|$key" = "Icons|Theme" ] && [ -n "$previous" ]; then icon_theme=$previous; fi
  if [ "$group|$key" = "Mouse|cursorTheme" ] && [ -n "$previous" ]; then cursor_theme=$previous; fi
done < "$STATE_FILE"

if [ -x "$ICON_CHANGER" ]; then "$ICON_CHANGER" "$icon_theme"; fi
if command -v plasma-apply-cursortheme >/dev/null 2>&1; then plasma-apply-cursortheme "$cursor_theme"; fi

rm -rf "$DATA_DIR/icons/$THEME_NAME" "$DATA_DIR/icons/$CURSOR_NAME" "$DATA_DIR/fonts/CitropySans" "$DATA_DIR/wallpapers/$THEME_NAME"
fc-cache -f "$DATA_DIR/fonts"
rm -rf "$STATE_DIR"

printf 'Removed. The wallpaper, if you applied it, stays until you pick another one.\n'
