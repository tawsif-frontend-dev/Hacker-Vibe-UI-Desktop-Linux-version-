#!/usr/bin/env bash
# HackerVibe for Linux - uninstaller.  ./uninstall.sh [--yes] [--purge]
#   --purge  also delete your settings/quotes and the installed fonts without asking
set -u
YES=0; PURGE=0
for a in "$@"; do case "$a" in -y|--yes) YES=1 ;; --purge) PURGE=1 ;; -h|--help) echo "usage: uninstall.sh [--yes] [--purge]"; exit 0 ;; esac; done

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hackervibe"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hackervibe"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hackervibe"
FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/hackervibe"

confirm() { [ "$YES" -eq 1 ] || [ "$PURGE" -eq 1 ] && return 0; local a; read -r -p "$1 [y/N] " a </dev/tty || return 1; case "$a" in [Yy]*) return 0 ;; *) return 1 ;; esac; }

[ -x "$HOME/.local/bin/hackervibe" ] && "$HOME/.local/bin/hackervibe" stop >/dev/null 2>&1

rm -rf "$DATA_DIR" "$CACHE_DIR"
rm -f "$HOME/.local/bin/hackervibe" \
      "${XDG_CONFIG_HOME:-$HOME/.config}/autostart/hackervibe.desktop" \
      "${XDG_DATA_HOME:-$HOME/.local/share}/applications/hackervibe-launcher.desktop"
echo "Removed program files, autostart entry and launcher."

if [ -d "$CONFIG_DIR" ] && confirm "Also delete your settings and quotes ($CONFIG_DIR)?"; then rm -rf "$CONFIG_DIR"; echo "Removed settings."; fi
if [ -d "$FONT_DIR" ]   && confirm "Also remove the bundled fonts ($FONT_DIR)?"; then
  rm -rf "$FONT_DIR"; command -v fc-cache >/dev/null 2>&1 && fc-cache -f >/dev/null 2>&1; echo "Removed fonts."
fi
echo "Your desktop wallpaper was left as it is - change it in your system settings if you like."
echo "Done."
