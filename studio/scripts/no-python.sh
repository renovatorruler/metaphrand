#!/usr/bin/env bash
# ReScript-only migration ratchet.
#
# Default mode checks Git-tracked source, which makes the build reproducible.
# Existing legacy shell invocations are recorded with exact per-file counts;
# any addition OR any completed migration requires an intentional baseline edit.
#
# --workspace is the strict audit: it also reports ignored/untracked Python in
# the local checkout. It remains red until the historical production tools have
# all been ported, but it does not make ordinary tests depend on local caches.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
baseline="$repo_root/studio/scripts/python-legacy-allowlist.txt"
mode="${1:-tracked}"
cd "$repo_root"

if [ "$mode" = "--workspace" ]; then
  prune=(-path ./.git -o -path '*/node_modules' -o -path './.venv*' -o -path '*/__pycache__')
  fail=0

  py=$(find . \( "${prune[@]}" \) -prune -o -name '*.py' -print 2>/dev/null)
  if [ -n "$py" ]; then
    echo ">>> Python source files in this workspace:"
    echo "$py"
    fail=1
  fi

  pkg=$(find . \( "${prune[@]}" \) -prune -o \
    \( -name 'requirements*.txt' -o -name 'pyproject.toml' -o -name 'setup.py' -o -name 'Pipfile' \) \
    -print 2>/dev/null)
  if [ -n "$pkg" ]; then
    echo ">>> Python packaging in this workspace:"
    echo "$pkg"
    fail=1
  fi

  hits=$(grep -rInE '(^|[^[:alnum:]_/.-])(python3?|pip3?)([[:space:]]|$)' \
    --exclude-dir='.git' --exclude-dir='node_modules' --exclude-dir='__pycache__' \
    --exclude-dir='.venv*' \
    --include='*.sh' --include='*.bash' --include='*.zsh' \
    --include='*.res' --include='*.resi' --include='*.json' \
    --include='Makefile' --include='*.mk' . 2>/dev/null \
    | grep -v 'scripts/no-python.sh' || true)
  if [ -n "$hits" ]; then
    echo ">>> Python interpreter invocations in this workspace:"
    echo "$hits"
    fail=1
  fi

  if [ "$fail" -ne 0 ]; then
    echo
    echo ">>> Workspace audit failed. Port these tools to studio/ ReScript."
    exit 1
  fi
  echo "workspace Python audit: clean"
  exit 0
fi

if [ "$mode" != "tracked" ]; then
  echo "usage: no-python.sh [--workspace]"
  exit 2
fi

tracked_py=$(git ls-files '*.py')
if [ -n "$tracked_py" ]; then
  echo ">>> Tracked Python source is forbidden:"
  echo "$tracked_py"
  exit 1
fi

tracked_pkg=$(git ls-files | grep -E '(^|/)(requirements[^/]*\.txt|pyproject\.toml|setup\.py|Pipfile)$' || true)
if [ -n "$tracked_pkg" ]; then
  echo ">>> Tracked Python packaging is forbidden:"
  echo "$tracked_pkg"
  exit 1
fi

if [ ! -f "$baseline" ]; then
  echo ">>> Missing migration baseline: $baseline"
  exit 1
fi

counts=$(mktemp "${TMPDIR:-/tmp}/metaphrand-python-counts.XXXXXX")
trap 'rm -f "$counts"' EXIT

git grep -n -E '(^|[^[:alnum:]_/.-])(python3?|pip3?)([[:space:]]|$)' -- \
  '*.sh' '*.bash' '*.zsh' '*.res' '*.resi' '*.json' 'Makefile' '*.mk' \
  ':(exclude)studio/scripts/no-python.sh' 2>/dev/null \
  | cut -d: -f1 \
  | sort \
  | uniq -c \
  | awk '{print $2 "|" $1}' > "$counts" || true

if ! diff -u "$baseline" "$counts"; then
  echo
  echo ">>> Python migration baseline changed."
  echo ">>> New use: remove it. Completed port: lower/remove its baseline entry."
  exit 1
fi

legacy_files=$(wc -l < "$counts" | tr -d ' ')
legacy_calls=$(awk -F'|' '{n += $2} END {print n + 0}' "$counts")
echo "Python migration ratchet: clean ($legacy_calls known invocations in $legacy_files files; no new debt)"
