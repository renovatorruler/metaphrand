#!/usr/bin/env bash
# EP1 batch preflight — blocks any job whose prompt or bindings don't match the script's cast.
#
# For every job it checks four things and prints a row per character/prop:
#   TAGGED   the prompt contains an @TAG entry for this token
#   DESCRIBED the @TAG line carries a description AND the "matches the reference" lock
#   REF      the reference image exists on disk
#   (bindings are EMITTED from the same manifest, so they cannot drift from the check)
#
# Usage:  ./preflight.sh                 audit every job, print the table, exit 1 if any FAIL
#         ./preflight.sh refs <job>      print the --image-references / --start-image args for one job
# The batch runner must call `preflight.sh` first and must source its args via `refs`.
set -uo pipefail
cd "$(dirname "$0")"

REFDIR="../../ep1prod/scene1/references"
KFDIR="../../rnd/keyframes"
PROMPTDIR="../../rnd/seedance_test/skill_run2"
MANIFEST="cast_manifest.tsv"
REFMAP="ref_map.tsv"

CHARACTER_TOKENS="FROSYA VASYA MAMA PAPA BABIES YAGA_FLIGHT YAGA_DOMOVOY"

lookup_tag ()  { awk -F'\t' -v t="$1" '$1==t{print $2; exit}' "$REFMAP"; }
lookup_file () {
  local p; p=$(awk -F'\t' -v t="$1" '$1==t{print $3; exit}' "$REFMAP")
  [ -z "$p" ] && return 1
  case "$p" in KF:*) echo "$KFDIR/${p#KF:}";; *) echo "$REFDIR/$p";; esac
}

emit_refs () {
  local want="$1" line job shots cast props start
  while IFS=$'\t' read -r job shots cast props start; do
    case "$job" in \#*|"") continue;; esac
    [ "$job" != "$want" ] && continue
    printf -- '--start-image %s ' "$KFDIR/$start"
    local seen=" "
    for tok in ${cast//,/ } ${props//,/ }; do
      local f; f=$(lookup_file "$tok") || continue
      case "$seen" in *" $f "*) continue;; esac
      seen="$seen$f "
      printf -- '--image-references %s ' "$f"
    done
    echo
    return 0
  done < "$MANIFEST"
  echo "ERROR: job $want not in manifest" >&2; return 1
}

if [ "${1:-}" = "refs" ]; then emit_refs "${2:?job number required}"; exit $?; fi

FAILED=0
printf '%-5s %-12s %-14s %-8s %-10s %-6s %s\n' JOB SHOTS TOKEN TAGGED DESCRIBED REF STATUS
printf '%s\n' "--------------------------------------------------------------------------------"
while IFS=$'\t' read -r job shots cast props start; do
  case "$job" in \#*|"") continue;; esac
  prompt="$PROMPTDIR/job${job}.prompt.txt"
  if [ ! -f "$prompt" ]; then
    printf '%-5s %-12s %-14s %-8s %-10s %-6s %s\n' "$job" "$shots" "(prompt)" - - - "FAIL missing $prompt"
    FAILED=1; continue
  fi
  if [ ! -f "$KFDIR/$start" ]; then
    printf '%-5s %-12s %-14s %-8s %-10s %-6s %s\n' "$job" "$shots" "(start)" - - - "FAIL missing keyframe $start"
    FAILED=1
  fi
  for tok in ${cast//,/ } ${props//,/ }; do
    tag=$(lookup_tag "$tok"); file=$(lookup_file "$tok")
    is_char=0; case " $CHARACTER_TOKENS " in *" $tok "*) is_char=1;; esac

    tagged=SKIP; described=SKIP
    if [ "$is_char" = 1 ]; then
      if grep -q -- "$tag:" "$prompt"; then
        tagged=yes
        line=$(grep -m1 -- "$tag:" "$prompt")
        # description must be substantive and carry the identity lock
        if [ "${#line}" -ge 60 ] && echo "$line" | grep -qi "matches the reference"; then
          described=yes
        else
          described=NO
        fi
      else
        tagged=NO; described=NO
      fi
    fi

    if [ -n "$file" ] && [ -f "$file" ]; then refok=yes; else refok=NO; fi

    status=OK
    [ "$tagged" = NO ] && status="FAIL untagged in prompt"
    [ "$described" = NO ] && [ "$tagged" = yes ] && status="FAIL tag lacks description/identity lock"
    [ "$refok" = NO ] && status="FAIL reference image missing"
    [ "$status" != OK ] && FAILED=1

    printf '%-5s %-12s %-14s %-8s %-10s %-6s %s\n' "$job" "$shots" "$tok" "$tagged" "$described" "$refok" "$status"
  done
done < "$MANIFEST"

printf '%s\n' "--------------------------------------------------------------------------------"
if [ "$FAILED" -eq 0 ]; then
  echo "PREFLIGHT PASS — every character in every shot is tagged, described, and has its reference."
else
  echo "PREFLIGHT FAIL — batch is BLOCKED. Fix the rows above before spending credits."
fi
exit "$FAILED"
