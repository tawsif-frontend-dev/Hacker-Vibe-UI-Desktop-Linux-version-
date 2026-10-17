#!/usr/bin/env bash
# HackerVibe for Linux - uninstaller.  ./uninstall.sh [--yes] [--purge]
#   --purge  also delete settings/quotes and named HackerVibe font files without asking
set -u
YES=0; PURGE=0
for a in "$@"; do case "$a" in -y|--yes) YES=1 ;; --purge) PURGE=1 ;; -h|--help) echo "usage: uninstall.sh [--yes] [--purge]"; exit 0 ;; esac; done

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hackervibe"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hackervibe"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hackervibe"
FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/hackervibe"
LAUNCHER="$HOME/.local/bin/hackervibe"

confirm() {
  [ "$PURGE" -eq 1 ] && return 0
  [ "$YES" -eq 1 ] && return 1
  local a
  read -r -p "$1 [y/N] " a </dev/tty || return 1
  case "$a" in [Yy]*) return 0 ;; *) return 1 ;; esac
}

if [ -L "$LAUNCHER" ] && [ "$(readlink "$LAUNCHER")" = "$DATA_DIR/bin/hackervibe" ]; then
  if [ -x "$DATA_DIR/bin/hackervibe" ]; then "$DATA_DIR/bin/hackervibe" stop >/dev/null 2>&1 || true; fi
  rm -f "$LAUNCHER"
elif [ -e "$LAUNCHER" ] || [ -L "$LAUNCHER" ]; then
  echo "Preserving unrelated launcher at $LAUNCHER"
fi

remove_owned_entry() {
  local file="$1" expected="$2"
  if [ -f "$file" ] && grep -Fqx "$expected" "$file"; then rm -f "$file"; fi
}
remove_owned_entry "${XDG_CONFIG_HOME:-$HOME/.config}/autostart/hackervibe.desktop" "Exec=\"$HOME/.local/bin/hackervibe\" start"
remove_owned_entry "${XDG_DATA_HOME:-$HOME/.local/share}/applications/hackervibe-launcher.desktop" "Exec=\"$HOME/.local/bin/hackervibe\" launcher"
rm -rf "$DATA_DIR/lib" "$DATA_DIR/conky" "$DATA_DIR/libexec" "$DATA_DIR/bin" "$CACHE_DIR"
rmdir "$DATA_DIR" 2>/dev/null || true
echo "Removed program files, owned desktop entries and launcher. Personalized wallpapers were preserved."

if [ -d "$CONFIG_DIR" ] && confirm "Also delete your settings and quotes ($CONFIG_DIR)?"; then rm -rf "$CONFIG_DIR"; echo "Removed settings."; fi
if [ -d "$FONT_DIR" ]   && confirm "Also remove HackerVibe's bundled font files from $FONT_DIR?"; then
  rm -f "$FONT_DIR/Orbitron.ttf" "$FONT_DIR/JetBrainsMono-Bold.ttf" "$FONT_DIR/JetBrainsMono-Regular.ttf" \
        "$FONT_DIR/OFL-Orbitron.txt" "$FONT_DIR/OFL-JetBrainsMono.txt"
  rmdir "$FONT_DIR" 2>/dev/null || true
  command -v fc-cache >/dev/null 2>&1 && fc-cache -f >/dev/null 2>&1
  echo "Removed HackerVibe fonts; other files in the font directory were preserved."
fi
echo "Your desktop wallpaper was left as it is - change it in your system settings if you like."
echo "Done."
