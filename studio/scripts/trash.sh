#!/usr/bin/env bash
# NOTHING IS EVER HARD-DELETED (author's law, 2026-08-06). This is the shell twin
# of Cinema_Backends.removeFile: move each given path into <repo>/.trash/ keeping
# its repo-relative structure, so recovery is a `mv` back and space reclamation is
# a manual, per-project sweep the author runs (e.g. rm -rf .trash/stories/<proj>).
#
# Usage:
#   scripts/trash.sh <path> [<path>...]      move files/dirs to trash
#   scripts/trash.sh --report                per-project trash sizes (what a sweep frees)
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
trash="$root/.trash"

if [ "${1:-}" = "--report" ]; then
  if [ ! -d "$trash" ]; then echo "trash is empty"; exit 0; fi
  echo "== trash by project (delete a line's path yourself to reclaim it) =="
  du -sh "$trash"/*/* 2>/dev/null | sort -rh || du -sh "$trash"/* 2>/dev/null
  echo "-- total:"
  du -sh "$trash"
  exit 0
fi

[ $# -ge 1 ] || { echo "usage: trash.sh <path> [<path>...] | --report"; exit 1; }

for p in "$@"; do
  [ -e "$p" ] || { echo "skip (absent): $p"; continue; }
  abs="$(cd "$(dirname "$p")" && pwd)/$(basename "$p")"
  case "$abs" in
    "$root"/*) rel="${abs#"$root"/}" ;;
    *) rel="_external/$(basename "$abs")" ;;
  esac
  dest="$trash/$rel"
  # the trash must never itself destroy data: collisions get a timestamp suffix
  if [ -e "$dest" ]; then dest="$dest.$(date +%s%N)"; fi
  mkdir -p "$(dirname "$dest")"
  mv "$abs" "$dest"
  echo "trashed: $rel"
done
