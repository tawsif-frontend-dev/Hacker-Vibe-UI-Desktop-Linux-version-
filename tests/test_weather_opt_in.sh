#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="${1:-$ROOT/linux/install.sh}"
helper="$(sed -n '/^ask_weather_opt_in() {$/,/^}/p' "$INSTALLER")"
[ -n "$helper" ] || { printf 'weather opt-in helper not found in %s\n' "$INSTALLER" >&2; exit 1; }
eval "$helper"

YES=1
result="$(ask_weather_opt_in)"
[ "$result" = 0 ] || { printf 'non-interactive install must disable IP lookup\n' >&2; exit 1; }
printf 'non-interactive weather privacy migration: PASS\n'
