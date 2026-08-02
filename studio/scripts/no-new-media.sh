#!/usr/bin/env bash
# Prevent new generated media from entering Git while legacy LFS cleanup remains
# a separate operation. Existing tracked assets are not re-scanned here.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo_root"

paths=$(
  {
    git diff --name-only --diff-filter=A HEAD 2>/dev/null || true
    git diff --cached --name-only --diff-filter=A 2>/dev/null || true
    git diff-tree --root --no-commit-id --name-only -r HEAD 2>/dev/null || true
  } | sort -u
)

media=$(echo "$paths" | grep -Ei '\.(png|jpe?g|webp|gif|mp3|mp4|m4a|wav|glb|pdf|blend|zip)$' || true)
if [ -n "$media" ]; then
  echo ">>> New generated media is tracked:"
  echo "$media"
  echo
  echo ">>> Keep source/manifests in Git and deliver media outside the repository."
  exit 1
fi

echo "new-media gate: clean"
