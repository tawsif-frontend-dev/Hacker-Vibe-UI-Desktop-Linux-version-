#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UNINSTALLER="${1:-$ROOT/linux/uninstall.sh}"
confirm_source="$(sed -n '/^confirm() {$/,/^}/p' "$UNINSTALLER")"
[ -n "$confirm_source" ] || { printf 'confirm function not found in %s\n' "$UNINSTALLER" >&2; exit 1; }
eval "$confirm_source"

YES=1
PURGE=0
if confirm 'test'; then
  printf '--yes must keep optional user data\n' >&2
  exit 1
fi
YES=0
PURGE=1
confirm 'test' || { printf '--purge must remove optional user data\n' >&2; exit 1; }
printf 'uninstall confirmation defaults: PASS\n'
