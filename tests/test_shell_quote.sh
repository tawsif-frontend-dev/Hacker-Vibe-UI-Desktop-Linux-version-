#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="${1:-$ROOT/linux/install.sh}"
helper="$(sed -n '/^shell_quote()/p' "$INSTALLER")"
[ -n "$helper" ] || { printf 'shell_quote helper not found in %s\n' "$INSTALLER" >&2; exit 1; }
eval "$helper"

value="https://example.invalid/o'h?x=1&y=two; printf INJECTED"
quoted="$(shell_quote "$value")"
actual="$(sh -c "printf '%s' $quoted")"
[ "$actual" = "$value" ] || { printf 'unsafe shell quoting: <%s>\n' "$actual" >&2; exit 1; }
printf 'installer URL escaping: PASS\n'
