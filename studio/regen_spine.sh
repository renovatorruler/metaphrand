#!/bin/bash
# Regenerate a list of EP10 shots through the spec engine, one retry each.
cd /Users/dusty/Dev/metaphrand/studio || exit 1
for s in "$@"; do
  r=$(node src/KukuEp10_Shots.res.mjs go "$s" 2>&1 | grep -E "^OK|^FAIL")
  if [ -z "$r" ]; then
    r=$(node src/KukuEp10_Shots.res.mjs go "$s" 2>&1 | grep -E "^OK|^FAIL")
  fi
  echo "${r:-FAIL $s (no result)}"
done
echo "BATCH DONE"
