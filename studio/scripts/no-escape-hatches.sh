#!/usr/bin/env bash
# Principle 4: no type-safety escape hatches. Enforced by the build, not by trust.
# An escape hatch is exactly how the type discipline gets routed around — so the
# build refuses to pass while one is present in src/. If one is ever truly needed,
# stop and ask, then add a reviewed, commented exception here.

if grep -rnE 'Obj\.magic|%raw|%identity|%bs\.raw|magic\(' src/; then
  echo ""
  echo ">>> escape hatch found above — banned (principle 4). Ask before adding one."
  exit 1
fi
echo "no escape hatches: clean"
exit 0
