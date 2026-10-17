#!/usr/bin/env bash
# HackerVibe for Linux - installer / personaliser.
#
#   ./install.sh                 interactive (asks a few questions, installs missing packages)
#   ./install.sh --yes           accept all defaults, no questions
#   ./install.sh --help          all options
#
# Safe to run again any time to change your name, links or event.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(dirname "$HERE")"
RES="$REPO/Skins/HackerSuite/@Resources"

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hackervibe"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hackervibe"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hackervibe"
BIN_DIR="$HOME/.local/bin"
FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/hackervibe"
AUTOSTART_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"
APPS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"

YES=0; NO_DEPS=0; NO_START=0; NO_AUTOSTART=0
A_NAME=""; A_LABEL=""; A_URL=""; A_EVENT=""; A_EDAY=""; A_EMONTH=""

c_info='\033[36m'; c_ok='\033[32m'; c_warn='\033[33m'; c_err='\033[31m'; c_off='\033[0m'
info() { printf "${c_info}==>%s${c_off} %s\n" "" "$*"; }
ok()   { printf "${c_ok} ok${c_off} %s\n" "$*"; }
warn() { printf "${c_warn}  !${c_off} %s\n" "$*" >&2; }
die()  { printf "${c_err}error:${c_off} %s\n" "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
backup_desktop_conflict() {
  local file="$1" expected="$2"
  [ -e "$file" ] || [ -L "$file" ] || return 0
  [ ! -L "$file" ] && [ -f "$file" ] || die "refusing to replace non-regular desktop entry: $file"
  if ! grep -Fqx "$expected" "$file"; then
    cp -p "$file" "$file.backup.$(date +%Y%m%d%H%M%S).$$"
    warn "existing desktop entry backed up before replacement: $file"
  fi
}

usage() {
  cat <<EOF
HackerVibe for Linux installer

  --yes, -y            non-interactive: use defaults / the values below
  --name NAME          your name (wallpaper + greetings, max 14 chars)
  --link-label TEXT    label of your website shortcut      (default: GitHub)
  --link-url URL       URL of that shortcut                (default: https://github.com)
  --event NAME         calendar countdown event name       (default: New Year)
  --event-day N        1-31                                (default: 1)
  --event-month N      1-12                                (default: 1)
  --no-deps            don't try to install packages
  --no-autostart       don't start HackerVibe at login
  --no-start           install but don't start it now
  --help               this text
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -y|--yes) YES=1 ;;
    --name) A_NAME="${2:-}"; shift ;;
    --link-label) A_LABEL="${2:-}"; shift ;;
    --link-url) A_URL="${2:-}"; shift ;;
    --event) A_EVENT="${2:-}"; shift ;;
    --event-day) A_EDAY="${2:-}"; shift ;;
    --event-month) A_EMONTH="${2:-}"; shift ;;
    --no-deps) NO_DEPS=1 ;;
    --no-autostart) NO_AUTOSTART=1 ;;
    --no-start) NO_START=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1 (see --help)" ;;
  esac
  shift
done

# (HV_ALLOW_ROOT=1 exists only so the installer can be tested inside containers)
[ "$(id -u)" -ne 0 ] || [ "${HV_ALLOW_ROOT:-0}" = "1" ] || die "don't run this as root - it installs into your own home folder."
[ -d "$RES" ] || die "can't find $RES - run install.sh from inside a full clone of the repository (linux/install.sh)."

if [ -e "$BIN_DIR/hackervibe" ] || [ -L "$BIN_DIR/hackervibe" ]; then
  [ -L "$BIN_DIR/hackervibe" ] && [ "$(readlink "$BIN_DIR/hackervibe")" = "$DATA_DIR/bin/hackervibe" ] ||
    die "$BIN_DIR/hackervibe already exists and is not the HackerVibe launcher; move it before installing."
fi

# ask "Question" "default"  -> echoes the answer
ask() {
  local q="$1" def="$2" a=""
  if [ "$YES" -eq 1 ] || [ ! -r /dev/tty ]; then printf '%s' "$def"; return; fi
  read -r -p "$q [$def] " a </dev/tty || true
  a="$(printf '%s' "$a" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  if [ -n "$a" ]; then printf '%s' "$a"; else printf '%s' "$def"; fi
}

confirm() {  # confirm "Question" -> 0 yes / 1 no (default yes)
  local a
  if [ "$YES" -eq 1 ] || [ ! -r /dev/tty ]; then return 0; fi
  read -r -p "$1 [Y/n] " a </dev/tty || true
  case "${a:-y}" in [Nn]*) return 1 ;; *) return 0 ;; esac
}

ask_weather_opt_in() {
  local answer
  if [ "$YES" -eq 1 ] || [ ! -r /dev/tty ]; then printf '0'; return; fi
  read -r -p "Keep IP-based weather location? This sends your public IP to ip-api.com [y/N] " answer </dev/tty || true
  case "${answer:-}" in [Yy]*) printf '1' ;; *) printf '0' ;; esac
}

# set_cfg KEY VALUE  -> replaces KEY="..." in settings.conf (or appends it); values are passed via env so
# backslashes / quotes in the value can't break awk
set_cfg() {
  local f="$CONFIG_DIR/settings.conf" tmp
  tmp="$(mktemp)"
  SC_K="$1" SC_V="$(printf '%s' "${2//\"/}" | tr '\r\n' '  ')" awk '
    BEGIN { k = ENVIRON["SC_K"]; v = ENVIRON["SC_V"]; done = 0 }
    $0 ~ "^[[:space:]]*" k "=" { print k "=\"" v "\""; done = 1; next }
    { print }
    END { if (!done) print k "=\"" v "\"" }' "$f" > "$tmp"
  mv "$tmp" "$f"
}

get_cfg() {  # get_cfg KEY DEFAULT (from existing settings, for re-runs)
  local f="$CONFIG_DIR/settings.conf" v=""
  [ -f "$f" ] && v="$(grep -E "^[[:space:]]*$1=" "$f" | tail -n1 | sed -E 's/^[^=]*=//; s/^"(.*)"$/\1/')"
  if [ -n "$v" ]; then printf '%s' "$v"; else printf '%s' "$2"; fi
}

first_of() { local c; for c in "$@"; do if have "$c"; then printf '%s' "$c"; return 0; fi; done; return 0; }
shell_quote() { local escaped; escaped=$(printf '%s' "$1" | sed "s/'/'\\\\''/g"); printf "'%s'" "$escaped"; }

printf '\n'
info "HackerVibe for Linux - installer"

# ---------------------------------------------------------------- 1. packages
conky_ok() {
  have conky || return 1
  local features
  features="$(conky -v 2>&1)" || return 1
  printf '%s\n' "$features" | grep -qi cairo && printf '%s\n' "$features" | grep -qi lua
}
pil_ok()   { have python3 && python3 -c 'import PIL' >/dev/null 2>&1; }

need=()
conky_ok  || need+=(conky)
have python3 || need+=(python3)
pil_ok    || need+=(pillow)
have fc-cache || need+=(fontconfig)

if [ "${#need[@]}" -gt 0 ] && [ "$NO_DEPS" -eq 0 ]; then
  pm=""
  if   have apt-get; then pm=apt
  elif have dnf;     then pm=dnf
  elif have pacman;  then pm=pacman
  elif have zypper;  then pm=zypper
  fi
  case "$pm" in
    apt)    PKGS="conky-all python3 python3-pil fontconfig x11-utils x11-xserver-utils"
            INSTALL=(sudo apt-get install -y) ;;
    dnf)    PKGS="conky python3 python3-pillow fontconfig xorg-x11-utils xrandr"
            INSTALL=(sudo dnf install -y) ;;
    pacman) PKGS="conky python python-pillow fontconfig xorg-xdpyinfo xorg-xrandr"
            INSTALL=(sudo pacman -S --needed --noconfirm) ;;
    zypper) PKGS="conky python3 python3-Pillow fontconfig xdpyinfo xrandr"
            INSTALL=(sudo zypper --non-interactive install) ;;
    *)      PKGS="" ;;
  esac
  if [ -n "$PKGS" ]; then
    info "Missing: ${need[*]}.  Will run: ${INSTALL[*]} $PKGS"
    if confirm "Install these packages now (needs sudo)?"; then
      [ "$pm" = apt ] && sudo apt-get update || true
      # shellcheck disable=SC2086
      "${INSTALL[@]}" $PKGS || warn "package installation failed - continuing, run 'hackervibe doctor' afterwards."
    else
      warn "skipped package installation"
    fi
  else
    warn "unknown package manager. Please install manually: conky (with Lua + Cairo), python3, Pillow, fontconfig."
  fi
fi
conky_ok  || warn "Conky with both Lua and Cairo support was not found. Widgets won't start until it is installed (apt: conky-all)."
pil_ok    || warn "Pillow missing: your name can't be rendered onto the wallpapers (plain wallpapers will be used)."

# ---------------------------------------------------------------- 2. questions
info "A few quick questions (press Enter to accept the default)"
def_name="$(get_cfg USER_NAME "${USER:-Hacker}")"
NAME="${A_NAME:-$(ask 'Your name (shown on wallpaper + greetings, Latin letters, max 14)' "$def_name") }"
NAME="$(printf '%s' "$NAME" | tr -cd 'A-Za-z0-9 ._-' | cut -c1-14)"
[ -n "$NAME" ] || NAME="Hacker"
LABEL="${A_LABEL:-$(ask 'Label for your website / GitHub shortcut' "$(get_cfg PORTFOLIO_LABEL GitHub)") }"
URL="${A_URL:-$(ask 'URL for that shortcut' "$(get_cfg PORTFOLIO_URL https://github.com)") }"
EVNAME="${A_EVENT:-$(ask 'Countdown event name (calendar widget)' "$(get_cfg EVENT_NAME 'New Year')") }"
EVDAY="${A_EDAY:-$(ask 'Event day (1-31)' "$(get_cfg EVENT_DAY 1)") }"
EVMONTH="${A_EMONTH:-$(ask 'Event month (1-12)' "$(get_cfg EVENT_MONTH 1)") }"
case "$EVDAY"   in ''|*[!0-9]*) EVDAY=1 ;;   esac; [ "$EVDAY" -ge 1 ] && [ "$EVDAY" -le 31 ] || EVDAY=1
case "$EVMONTH" in ''|*[!0-9]*) EVMONTH=1 ;; esac; [ "$EVMONTH" -ge 1 ] && [ "$EVMONTH" -le 12 ] || EVMONTH=1
case "$URL" in http://*|https://*) ;; *) URL="https://$URL" ;; esac
case "$URL" in
  http://|https://) die "link URL must include a host" ;;
  *[[:space:][:cntrl:]]*) die "link URL cannot contain whitespace or control characters" ;;
esac

# ---------------------------------------------------------------- 3. stop old version, copy files
if [ -L "$BIN_DIR/hackervibe" ] && [ "$(readlink "$BIN_DIR/hackervibe")" = "$DATA_DIR/bin/hackervibe" ] && [ -x "$DATA_DIR/bin/hackervibe" ]; then
  "$DATA_DIR/bin/hackervibe" stop >/dev/null 2>&1 || true
fi

info "Installing to $DATA_DIR"
mkdir -p "$DATA_DIR" "$CONFIG_DIR/state" "$CACHE_DIR" "$BIN_DIR" "$FONT_DIR" "$AUTOSTART_DIR" "$APPS_DIR"
rm -rf "$DATA_DIR/lib" "$DATA_DIR/conky" "$DATA_DIR/libexec" "$DATA_DIR/bin"
cp -r "$HERE/lib" "$HERE/conky" "$HERE/libexec" "$HERE/bin" "$DATA_DIR/"
chmod +x "$DATA_DIR/bin/hackervibe" "$DATA_DIR/libexec/weather.py"
ln -sfn "$DATA_DIR/bin/hackervibe" "$BIN_DIR/hackervibe"
ok "scripts installed, command: $BIN_DIR/hackervibe"

# settings: keep the user's file on re-runs, only update the answers
if [ ! -f "$CONFIG_DIR/settings.conf" ]; then
  cp "$HERE/config/settings.conf" "$CONFIG_DIR/settings.conf"
  fresh=1
else
  fresh=0
  backup="$CONFIG_DIR/settings.conf.backup.$(date +%Y%m%d%H%M%S).$$"
  cp -p "$CONFIG_DIR/settings.conf" "$backup"
  info "Existing settings backed up to $backup"
fi
[ -f "$CONFIG_DIR/quotes.txt" ] || cp "$RES/Quotes.txt" "$CONFIG_DIR/quotes.txt"

if [ "$fresh" -eq 0 ] && [ "$(get_cfg WEATHER_AUTO 0)" = "1" ]; then
  set_cfg WEATHER_AUTO "$(ask_weather_opt_in)"
fi

if [ "$fresh" -eq 0 ]; then
  [ "$(get_cfg SHORTCUT5_CMD '')" = 'xdg-open $HOME' ] && set_cfg SHORTCUT5_CMD "xdg-open $(shell_quote "$HOME")"
  [ "$(get_cfg SHORTCUT6_CMD '')" = 'xdg-open $HOME/Downloads' ] && set_cfg SHORTCUT6_CMD "xdg-open $(shell_quote "$HOME/Downloads")"
fi

set_cfg USER_NAME "$NAME"
set_cfg PORTFOLIO_LABEL "$LABEL"
set_cfg PORTFOLIO_URL "$URL"
set_cfg EVENT_NAME "$EVNAME"
set_cfg EVENT_DAY "$EVDAY"
set_cfg EVENT_MONTH "$EVMONTH"
set_cfg SHORTCUT3_LABEL "$LABEL"
set_cfg SHORTCUT3_CMD "xdg-open $(shell_quote "$URL")"

# detect machine-specific launchers (only on a fresh install, so manual edits survive re-runs)
if [ "$fresh" -eq 1 ]; then
  ed="$(first_of code codium vscodium code-oss gnome-text-editor gedit kate mousepad xed pluma)"
  tm="$(first_of x-terminal-emulator gnome-terminal konsole xfce4-terminal alacritty kitty tilix xterm)"
  dl="$(xdg-user-dir DOWNLOAD 2>/dev/null || true)"; [ -n "$dl" ] && [ "$dl" != "$HOME" ] || dl="$HOME/Downloads"
  [ -n "$ed" ] && set_cfg SHORTCUT1_CMD "$ed" || warn "no code editor found - edit SHORTCUT1_CMD in settings.conf"
  [ -n "$tm" ] && set_cfg SHORTCUT2_CMD "$tm" || warn "no terminal emulator found - edit SHORTCUT2_CMD in settings.conf"
  set_cfg SHORTCUT5_CMD "xdg-open $(shell_quote "$HOME")"
  set_cfg SHORTCUT6_CMD "xdg-open $(shell_quote "$dl")"
fi
ok "settings: $CONFIG_DIR/settings.conf"

# ---------------------------------------------------------------- 4. fonts
info "Installing fonts (Orbitron + JetBrains Mono, OFL licensed)"
cp "$RES/Fonts/Orbitron.ttf" "$RES"/Fonts/JetBrainsMono-*.ttf "$RES"/Fonts/OFL-*.txt "$FONT_DIR/" 2>/dev/null || warn "one or more bundled fonts or license files are missing from $RES/Fonts"
have fc-cache && fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
ok "fonts installed for your user"

# ---------------------------------------------------------------- 5. wallpapers
info "Rendering wallpapers for \"$NAME\""
mkdir -p "$DATA_DIR/wallpapers"
# Render directly into the user's data directory; never personalize source assets in the checkout.
if pil_ok && python3 "$HERE/tools/render_wallpapers.py" --name "$NAME" \
    --base "$RES/Wallpaper/Base" --out "$DATA_DIR/wallpapers" >/dev/null 2>&1; then
  ok "4 personalised wallpapers"
else
  cp "$RES"/Wallpaper/Base/*.png "$DATA_DIR/wallpapers/"
  warn "used the plain wallpapers (no name on them)"
fi

# ---------------------------------------------------------------- 6. autostart + menu entry
if [ "$NO_AUTOSTART" -eq 0 ]; then
  backup_desktop_conflict "$AUTOSTART_DIR/hackervibe.desktop" "Exec=\"$BIN_DIR/hackervibe\" start"
  cat > "$AUTOSTART_DIR/hackervibe.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=HackerVibe
Comment=HackerVibe desktop widgets
Exec="$BIN_DIR/hackervibe" start
Terminal=false
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=6
EOF
  ok "starts automatically at login"
fi
backup_desktop_conflict "$APPS_DIR/hackervibe-launcher.desktop" "Exec=\"$BIN_DIR/hackervibe\" launcher"
cat > "$APPS_DIR/hackervibe-launcher.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=HackerVibe Launcher
Comment=Pick one of your HackerVibe shortcuts
Exec="$BIN_DIR/hackervibe" launcher
Icon=utilities-terminal
Terminal=false
Categories=Utility;
EOF

# ---------------------------------------------------------------- 7. go
[ -f "$CONFIG_DIR/state/theme" ] || echo "Green" > "$CONFIG_DIR/state/theme"
case ":$PATH:" in *":$BIN_DIR:") ;; *) warn "$BIN_DIR is not in your PATH. Add this to ~/.profile:  export PATH=\"\$HOME/.local/bin:\$PATH\"" ;; esac

if [ "$NO_START" -eq 0 ] && [ -n "${DISPLAY:-}" ] && conky_ok; then
  info "Starting HackerVibe"
  "$BIN_DIR/hackervibe" theme "$(cat "$CONFIG_DIR/state/theme")" || true
  "$BIN_DIR/hackervibe" start || warn "couldn't start - run: hackervibe doctor"
else
  [ "$NO_START" -eq 1 ] || warn "not starting now (no graphical session or conky missing). Later run: hackervibe start"
fi

printf "\n${c_ok}Done!${c_off}  Next steps:\n"
cat <<EOF
  1. hackervibe theme next        switch Green -> Blue -> Red -> Purple (also swaps the wallpaper)
  2. hackervibe settings          edit your name, weather city, shortcuts, layout ...
  3. hackervibe launcher          open your shortcuts menu (bind it to a key, e.g. Super+Space)
  4. hackervibe doctor            if anything looks wrong
Re-run ./install.sh any time to change your name or links.
EOF
