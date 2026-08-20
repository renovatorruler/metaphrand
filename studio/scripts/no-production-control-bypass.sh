#!/usr/bin/env bash
# Structural capability ratchet for the generic production control plane.
#
# This scans the working tree rather than Git's index, so untracked ReScript is
# covered.  Existing, non-Production legacy generators are intentionally out of
# scope: adopting this control plane must not silently become a legacy rewrite.
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
scan_root="$repo_root"
source_root="$repo_root/studio/src"
package_json="$repo_root/studio/package.json"
studio_root="$repo_root/studio"
legacy_manifest="$repo_root/studio/scripts/production-control-legacy-capabilities.sha256"

if [ "$#" -ne 0 ]; then
  if [ "$#" -eq 2 ] && [ "$1" = "--fixture-root" ]; then
    scan_root="$(cd "$2" && pwd)"
    source_root="$scan_root/studio/src"
    package_json="$scan_root/studio/package.json"
    studio_root="$scan_root/studio"
    legacy_manifest="$scan_root/studio/scripts/production-control-legacy-capabilities.sha256"
  else
    echo "usage: no-production-control-bypass.sh [--fixture-root ROOT]" >&2
    exit 2
  fi
fi

fail=0

report() {
  echo ">>> $1"
  fail=1
}

report_hits() {
  local message="$1"
  local hits="$2"
  if [ -n "$hits" ]; then
    echo "$hits"
    report "$message"
  fi
}

if [ ! -d "$source_root" ]; then
  echo ">>> Missing production-control source root: $source_root" >&2
  exit 1
fi

if [ ! -f "$package_json" ]; then
  report "studio/package.json is required so the standard test command cannot bypass production control."
else
  test_script="$(node -e 'const p=require(process.argv[1]); process.stdout.write(String((p.scripts||{}).test||""))' "$package_json")"
  production_test_script="$(node -e 'const p=require(process.argv[1]); process.stdout.write(String((p.scripts||{})["test:production-control"]||""))' "$package_json")"
  case "$test_script" in
    *"test:production-control"*) ;;
    *) report "standard npm test must invoke test:production-control." ;;
  esac
  case "$production_test_script" in
    *"no-production-control-bypass.sh"*"test-production-control-bypass.sh"*) ;;
    *) report "test:production-control must run both enforcement lint and its adversarial suite." ;;
  esac
  case "$production_test_script" in
    *"rescript clean && rescript &&"*) ;;
    *) report "test:production-control must start from a clean ReScript build." ;;
  esac
  required_test_tokens=(
    "Production_LeaseTest.res.mjs"
    "Production_DomainTest.res.mjs"
    "Production_StateTest.res.mjs"
    "Production_WorkOrderTest.res.mjs"
    "Production_CredentialsTest.res.mjs"
    "Production_ReferencesTest.res.mjs"
    "Production_InspectionTest.res.mjs"
    "Production_ExecutionJournalTest.res.mjs"
    "Production_ArtifactStoreTest.res.mjs"
    "Production_GatewayTest.res.mjs"
    "Production_ControllerTest.res.mjs"
    "Production_RestartTest.res.mjs"
    "Production_EndToEndTest.res.mjs"
    "test-production-control-concurrency.sh"
  )
  for token in "${required_test_tokens[@]}"; do
    case "$production_test_script" in
      *"$token"*) ;;
      *) report "test:production-control must run required production-control test '$token'." ;;
    esac
  done
fi

# These modules are the architectural boundary. Requiring both the
# implementation and interface prevents deletion of the gate from turning the
# lint green.
required_modules="
Production_Domain
Production_Credentials
Production_OutputSafety
Production_Lease
Production_WorkOrder
Production_State
Production_Inspection
Production_ArtifactStore
Production_References
Production_ExecutionJournal
Production_Preflight
Production_Gateway
Production_Controller
"

while IFS= read -r module_name; do
  [ -n "$module_name" ] || continue
  if [ ! -f "$source_root/$module_name.res" ] || [ ! -f "$source_root/$module_name.resi" ]; then
    report "$module_name must have both .res and .resi files."
  fi
done <<<"$required_modules"

required_test_modules="
Production_LeaseTest
Production_DomainTest
Production_StateTest
Production_WorkOrderTest
Production_CredentialsTest
Production_ReferencesTest
Production_InspectionTest
Production_ExecutionJournalTest
Production_ArtifactStoreTest
Production_GatewayTest
Production_ControllerTest
Production_RestartTest
Production_EndToEndTest
Production_ConcurrencyTest
"
while IFS= read -r module_name; do
  [ -n "$module_name" ] || continue
  if [ ! -f "$source_root/$module_name.res" ]; then
    report "Required production-control test source $module_name.res is missing."
  fi
done <<<"$required_test_modules"
if [ ! -f "$studio_root/scripts/test-production-control-concurrency.sh" ]; then
  report "Required cross-process production-control concurrency harness is missing."
fi

production_files=()
while IFS= read -r -d '' file; do
  production_files+=("$file")
done < <(
  find "$source_root" -type f \( -name 'Production_*.res' -o -name 'Production_*.resi' \) -print0
)

source_files=()
while IFS= read -r -d '' file; do
  source_files+=("$file")
done < <(
  find "$source_root" -type f \( -name '*.res' -o -name '*.resi' \) -print0
)

# ReScript's type checker is part of the authority boundary. A local FFI import
# of emitted Production_*.res.mjs would skip opaque interfaces and exact-caller
# checks entirely; raw JavaScript can do the same through require/import. These
# forms are unnecessary in this control plane and are forbidden across every
# studio ReScript source, regardless of filename.
for file in "${source_files[@]}"; do
  ffi_hits="$(grep -nE '@module[[:space:]]*\([[:space:]]*"[^"]*Production_[A-Za-z0-9_]+(\.res)?\.mjs"|%{1,2}(raw|ffi)|@val([[:space:]]+@[^[:space:]]+)*[[:space:]]+external[[:space:]]+(require|eval|Function)([^[:alnum:]_]|$)' "$file" 2>/dev/null || true)"
  report_hits \
    "$file bypasses ReScript authority through local compiled-module FFI or raw JavaScript." \
    "$ffi_hits"
done

if [ "${#production_files[@]}" -eq 0 ]; then
  report "No Production_*.res or Production_*.resi files were found."
fi

gateway_impl="$source_root/Production_Gateway.res"
gateway_interface="$source_root/Production_Gateway.resi"

# Production source has one home. A shadow module in a story, artifact, or
# scratch tree is both an authority fork and an easy capability bypass.
misplaced=""
while IFS= read -r -d '' file; do
  case "$file" in
    "$source_root"/*) ;;
    *) misplaced="${misplaced}${file}"$'\n' ;;
  esac
done < <(
  find "$scan_root" \
    \( -path "$scan_root/.git" -o -path '*/node_modules' -o -path '*/.venv*' -o -path '*/_build' \) -prune -o \
    -type f \( -name 'Production_*.res' -o -name 'Production_*.resi' \) -print0
)
report_hits \
  "Production_ ReScript is allowed only in studio/src; story and artifact trees are data, never executable authority." \
  "${misplaced%$'\n'}"

# No ReScript of any name belongs in a story tree. This closes the trivial
# rename-to-Bypass.res route without forcing any legacy studio generator to be
# migrated.
story_code=""
if [ -d "$scan_root/stories" ]; then
  while IFS= read -r -d '' file; do
    story_code="${story_code}${file}"$'\n'
  done < <(
    find "$scan_root/stories" \
      \( -path '*/node_modules' -o -path '*/.venv*' -o -path '*/_build' \) -prune -o \
      -type f \( -name '*.res' -o -name '*.resi' \) -print0
  )
fi
report_hits \
  "ReScript is forbidden in stories and their artifact trees; keep executable production control in studio/src." \
  "${story_code%$'\n'}"

artifact_code=""
while IFS= read -r -d '' file; do
  case "$file" in
    */artifact/*|*/artifacts/*)
      artifact_code="${artifact_code}${file}"$'\n'
      ;;
  esac
done < <(
  find "$scan_root" \
    \( -path "$scan_root/.git" -o -path '*/node_modules' -o -path '*/.venv*' -o -path '*/_build' \) -prune -o \
    -type f \( -name '*.res' -o -name '*.resi' \) -print0
)
report_hits \
  "ReScript is forbidden in artifact trees, regardless of filename." \
  "${artifact_code%$'\n'}"

# Keep provider, model, network, process and media capabilities out of every
# generic module except the one gateway implementation/interface pair.
backend_methods='run|ffmpeg|pango|durationSec|probeDuration|silence|concatAudio|image|imageGpt2|videoSora|imageToVideo|falSeedance2|falOmnihuman|falOmnihumanUrl|dialogue|dialogueTimed|tts|music|soundEffect'
direct_capability_pattern='@module[[:space:]]*\([[:space:]]*"(node:)?(child_process|https?|http2|net|tls|dgram|undici)"|external([^\n]|[[:space:]])*(fetch|XMLHttpRequest|WebSocket)|Js\.Global\.fetch|globalThis\.fetch|(^|[^[:alnum:]_])(spawn|spawnSync|execFile|execFileSync)[[:space:]]*\('
provider_module_pattern='Session[[:space:]]*\.[[:space:]]*ask|Write[[:space:]]*\.[[:space:]]*(writeScene|liftDialogue|extendScene)|Cinema_(Frames|Audio|Upload|PaidSmoke)[[:space:]]*\.'
provider_literal_pattern='https?://|higgsfield|replicate|elevenlabs|fal\.ai|fal\.run|openai|anthropic|claude|gemini|sora|seedance|nano[-_ ]?banana|midjourney|runway|heygen|(^|[^[:alnum:]_])(curl|wget|ffmpeg|ffprobe|pango-view)([^[:alnum:]_]|$)'

# Existing provider-capable legacy modules remain usable, but they are a
# reviewed compatibility surface—not an exemption that a newly named module
# may inherit. Exact hashes make any expansion explicit. The closure scan also
# catches a new wrapper around one of these modules.
manifest_has_path() {
  local relative="$1"
  awk -v wanted="$relative" '$2 == wanted { found=1 } END { exit(found ? 0 : 1) }' "$legacy_manifest"
}

if [ ! -f "$legacy_manifest" ]; then
  report "The reviewed legacy capability manifest is missing."
else
  malformed_manifest="$(grep -nvE '^[0-9a-f]{64}  (src/[^ ./][^ ]*\.(res|resi)|scripts/[^ ./][^ ]*\.(sh|mjs))$' "$legacy_manifest" 2>/dev/null || true)"
  report_hits "Legacy capability manifest contains malformed or unsafe entries." "$malformed_manifest"
  manifest_paths="$(awk '{print $2}' "$legacy_manifest")"
  duplicate_manifest_paths="$(printf '%s\n' "$manifest_paths" | sort | uniq -d)"
  report_hits "Legacy capability manifest contains duplicate paths." "$duplicate_manifest_paths"
  if [ "$manifest_paths" != "$(printf '%s\n' "$manifest_paths" | sort)" ]; then
    report "Legacy capability manifest paths must be sorted deterministically."
  fi
  while read -r expected relative extra; do
    [ -n "${expected:-}" ] || continue
    if [ -n "${extra:-}" ]; then
      report "Legacy capability manifest entry for $relative has unexpected fields."
      continue
    fi
    case "$relative" in
      src/*.res|src/*.resi|scripts/*.sh|scripts/*.mjs) ;;
      *) report "Legacy capability manifest path is outside its reviewed roots: $relative"; continue ;;
    esac
    full="$studio_root/$relative"
    if [ ! -f "$full" ]; then
      report "Legacy capability source disappeared without an explicit manifest update: $relative"
      continue
    fi
    actual="$(shasum -a 256 "$full" | awk '{print $1}')"
    if [ "$actual" != "$expected" ]; then
      report "Legacy capability source changed without an explicit reviewed manifest update: $relative"
    fi
  done < "$legacy_manifest"

  legacy_modules="$(awk '$2 ~ /^src\/.*\.resi?$/ { value=$2; sub(/^src\//,"",value); sub(/\.resi?$/,"",value); print value }' "$legacy_manifest" | sort -u | paste -sd'|' -)"
  legacy_direct_pattern="Cinema_Backends|(^|[^[:alnum:]_])(run|ffmpeg|pango|durationSec|probeDuration|silence|concatAudio|image|imageGpt2|videoSora|imageToVideo|falSeedance2|falOmnihuman|falOmnihumanUrl|dialogue|dialogueTimed|tts|music|soundEffect)[[:space:]]*\(|Session[[:space:]]*\.[[:space:]]*ask|Write[[:space:]]*\.[[:space:]]*(writeScene|liftDialogue|extendScene)|${direct_capability_pattern}|${provider_literal_pattern}"
  for file in "${source_files[@]}"; do
    base="$(basename "$file")"
    case "$base" in Production_*) continue ;; esac
    relative="${file#"$studio_root/"}"
    legacy_hit="$(grep -niE "$legacy_direct_pattern" "$file" 2>/dev/null || true)"
    if [ -n "$legacy_modules" ]; then
      closure_hit="$(grep -nE "(^|[^[:alnum:]_])(${legacy_modules})[[:space:]]*\." "$file" 2>/dev/null || true)"
      legacy_hit="${legacy_hit}${legacy_hit:+$'\n'}${closure_hit}"
    fi
    if [ -n "$legacy_hit" ] && ! manifest_has_path "$relative"; then
      echo "$legacy_hit"
      report "$file adds or wraps provider/process/network capability outside the sole gateway without reviewed legacy-manifest authority."
    fi
  done

  # Handwritten JavaScript and shell are outside ReScript's opaque-type and
  # exact-caller checks. Freeze every pre-existing executable script at an
  # exact reviewed hash, and allow only this control plane's own deterministic
  # lint/concurrency harnesses outside that legacy surface. This prevents an
  # obfuscated dynamic import of compiled Production_*.res.mjs from becoming a
  # new authority path merely because it avoids the capability regexes below.
  while IFS= read -r -d '' file; do
    case "$file" in
      *.res.mjs)
        source="${file%.mjs}"
        if [ ! -f "$source" ]; then
          report "Orphan generated ReScript JavaScript is executable authority without reviewed source: $file"
        fi
        continue
        ;;
      "$studio_root/scripts/no-production-control-bypass.sh"|"$studio_root/scripts/test-production-control-bypass.sh"|"$studio_root/scripts/test-production-control-concurrency.sh")
        continue
        ;;
    esac
    relative="${file#"$studio_root/"}"
    if ! manifest_has_path "$relative"; then
      report "$file is new handwritten executable code outside the reviewed legacy-script manifest and ReScript control-plane harnesses."
    fi
    script_hit="$(grep -niE "${direct_capability_pattern}|${provider_literal_pattern}" "$file" 2>/dev/null || true)"
    if [ -n "$script_hit" ] && ! manifest_has_path "$relative"; then
      echo "$script_hit"
      report "$file adds handwritten provider/process/network capability outside the sole gateway without reviewed legacy-manifest authority."
    fi
  done < <(find "$studio_root/src" "$studio_root/scripts" -type f \( -name '*.mjs' -o -name '*.sh' \) -print0)
fi

for file in "${production_files[@]}"; do
  hits="$(grep -nE 'Obj[[:space:]]*\.[[:space:]]*magic|%identity|unsafe(Coerce|Cast)|Obj[[:space:]]*\.[[:space:]]*unsafe' "$file" 2>/dev/null || true)"
  report_hits \
    "$file uses an unsafe type escape that could forge opaque preflight or authorization capabilities." \
    "$hits"

  if [ "$file" = "$gateway_impl" ] || [ "$file" = "$gateway_interface" ]; then
    continue
  fi

  hits="$(grep -nE "$direct_capability_pattern" "$file" 2>/dev/null || true)"
  report_hits \
    "$file uses a direct process or network capability; these are forbidden outside Production_Gateway." \
    "$hits"

  hits="$(grep -nE "$provider_module_pattern" "$file" 2>/dev/null || true)"
  report_hits \
    "$file uses a model or media provider module; these are forbidden outside Production_Gateway." \
    "$hits"

  hits="$(grep -niE "$provider_literal_pattern" "$file" 2>/dev/null || true)"
  report_hits \
    "$file contains a provider endpoint, model name, or provider/media CLI literal; these are forbidden outside Production_Gateway." \
    "$hits"

  if grep -nE '^[[:space:]]*(open|include)[[:space:]]+Cinema_Backends([^[:alnum:]_]|$)' "$file" >/dev/null 2>&1; then
    report "$file opens/includes Cinema_Backends, which hides capability calls; use explicit safe filesystem/hash members."
  fi

  # Follow simple ReScript module aliases so `module B = Cinema_Backends; B.run`
  # cannot evade the member scan. Alias-to-alias chains are resolved too.
  aliases="Cinema_Backends"
  declarations="$(
    sed -nE 's/^[[:space:]]*module[[:space:]]+([A-Z][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*([A-Z][A-Za-z0-9_]*).*/\1|\2/p' "$file"
  )"
  changed=1
  while [ "$changed" -eq 1 ]; do
    changed=0
    while IFS='|' read -r alias_name alias_source; do
      [ -n "$alias_name" ] && [ -n "$alias_source" ] || continue
      case " $aliases " in
        *" $alias_source "*)
          case " $aliases " in
            *" $alias_name "*) ;;
            *) aliases="$aliases $alias_name"; changed=1 ;;
          esac
          ;;
      esac
    done <<<"$declarations"
  done

  for alias_name in $aliases; do
    hits="$(
      grep -nE "(^|[^[:alnum:]_])${alias_name}[[:space:]]*\.[[:space:]]*(${backend_methods})([^[:alnum:]_]|$)" "$file" 2>/dev/null || true
    )"
    report_hits \
      "$file uses process, provider, or paid-media Cinema_Backends members; these are forbidden outside Production_Gateway." \
      "$hits"
  done
done

# Public gateway values are intentionally tiny. Types and exceptions may be
# exported, but callers receive only authorization and execution operations.
if [ -f "$gateway_interface" ]; then
  exported_values="$(
    sed -nE 's/^[[:space:]]*let[[:space:]]+([a-z][A-Za-z0-9_]*)[[:space:]]*:.*/\1/p' "$gateway_interface" | sort
  )"
  expected_values=$'authorizationBinding\nauthorize\ncandidateAuthorityCurrent\nexecute\nrecover\nregisterProvider'
  if [ "$exported_values" != "$expected_values" ]; then
    echo ">>> Production_Gateway.resi value exports:"
    [ -n "$exported_values" ] && echo "$exported_values" || echo "(none)"
    report "Production_Gateway.resi must export exactly registerProvider, authorizationBinding, authorize, recover, candidateAuthorityCurrent, and execute as values."
  fi
  if grep -nE '^[[:space:]]*(@[^[:space:]]+[[:space:]]+)*external[[:space:]]|^[[:space:]]*(open|include|module)[[:space:]]' "$gateway_interface" >/dev/null 2>&1; then
    report "Production_Gateway.resi must not expose FFI, open/include another capability module, or export a module."
  fi
fi

# These types are unforgeable capabilities. Widening any one in a .resi turns
# a compile-time authorization boundary into caller-supplied data.
opaque_capabilities=$'Production_Credentials.resi:principalCredential\nProduction_Credentials.resi:humanCommand\nProduction_Lease.resi:t\nProduction_Preflight.resi:cleared\nProduction_Gateway.resi:authorization\nProduction_Gateway.resi:provider\nProduction_ExecutionJournal.resi:authorizationIntent\nProduction_ArtifactStore.resi:store\nProduction_Controller.resi:inspector'
while IFS=':' read -r interface_name type_name; do
  [ -n "$interface_name" ] && [ -n "$type_name" ] || continue
  interface_path="$source_root/$interface_name"
  if [ ! -f "$interface_path" ]; then
    continue
  fi
  if ! grep -Eq "^[[:space:]]*type[[:space:]]+${type_name}[[:space:]]*$" "$interface_path" ||
    grep -Eq "^[[:space:]]*type[[:space:]]+${type_name}[[:space:]]*=" "$interface_path"; then
    report "$interface_name must keep capability type '$type_name' opaque."
  fi
done <<<"$opaque_capabilities"

# The gateway is a library boundary, never a CLI or import-time executable.
if [ -f "$gateway_impl" ]; then
  gateway_entry_hits="$(
    grep -nE '^[[:space:]]*let[[:space:]]+main([^[:alnum:]_]|$)|^[[:space:]]*main[[:space:]]*\(|(^|[^[:alnum:]_])(process|Node\.Process)[[:space:]]*\.[[:space:]]*argv([^[:alnum:]_]|$)|@scope[[:space:]]*\([[:space:]]*"process"[[:space:]]*\)([^\n]|[[:space:]])*argv' "$gateway_impl" 2>/dev/null || true
  )"
  report_hits \
    "Production_Gateway must not define/call a main entrypoint or inspect process argv." \
    "$gateway_entry_hits"
fi

# Only the controller and the exact synthetic contract modules may touch the
# gateway. A filename merely ending in Test is not authority.
# Scan every studio source name, not only Production_*, so renaming a bypass
# module cannot make an unauthorized call disappear from this ratchet.
for file in "${source_files[@]}"; do
  base="$(basename "$file")"
  case "$base" in
    Production_Gateway.res|Production_Gateway.resi|Production_Controller.res|Production_Controller.resi|Production_GatewayTest.res|Production_ConcurrencyTest.res|Production_ControllerTest.res|Production_RestartTest.res|Production_EndToEndTest.res|Production_TestFixtures.res)
      continue
      ;;
  esac

  gateway_hits="$(grep -nE 'Production_Gateway[[:space:]]*\.[[:space:]]*(registerProvider|authorizationBinding|authorize|recover|candidateAuthorityCurrent|execute)([^[:alnum:]_]|$)|^[[:space:]]*(open|include)[[:space:]]+Production_Gateway([^[:alnum:]_]|$)' "$file" 2>/dev/null || true)"

  gateway_aliases="Production_Gateway"
  gateway_declarations="$(
    sed -nE 's/^[[:space:]]*module[[:space:]]+([A-Z][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*([A-Z][A-Za-z0-9_]*).*/\1|\2/p' "$file"
  )"
  changed=1
  while [ "$changed" -eq 1 ]; do
    changed=0
    while IFS='|' read -r alias_name alias_source; do
      [ -n "$alias_name" ] && [ -n "$alias_source" ] || continue
      case " $gateway_aliases " in
        *" $alias_source "*)
          case " $gateway_aliases " in
            *" $alias_name "*) ;;
            *) gateway_aliases="$gateway_aliases $alias_name"; changed=1 ;;
          esac
          ;;
      esac
    done <<<"$gateway_declarations"
  done
  for alias_name in $gateway_aliases; do
    [ "$alias_name" != "Production_Gateway" ] || continue
    alias_hits="$(grep -nE "(^|[^[:alnum:]_])${alias_name}[[:space:]]*\.[[:space:]]*(registerProvider|authorizationBinding|authorize|recover|candidateAuthorityCurrent|execute)([^[:alnum:]_]|$)" "$file" 2>/dev/null || true)"
    if [ -n "$alias_hits" ]; then
      gateway_hits="${gateway_hits}${gateway_hits:+$'\n'}${alias_hits}"
    fi
  done
  report_hits \
    "$file calls the gateway; only Production_Controller and exact synthetic contract modules may use the gateway API." \
    "$gateway_hits"
done

# Lifecycle and artifact mutations are also authority boundaries. A differently
# named studio module must not be able to self-authorize, self-inspect, or
# self-approve by calling the persistence primitives directly.
for file in "${source_files[@]}"; do
  base="$(basename "$file")"
  case "$base" in
    Production_State.res|Production_State.resi|Production_Gateway.res|Production_Gateway.resi|Production_Controller.res|Production_Controller.resi|Production_StateTest.res|Production_GatewayTest.res|Production_ControllerTest.res|Production_RestartTest.res|Production_EndToEndTest.res)
      continue
      ;;
  esac

  state_hits="$(grep -nE 'Production_State[[:space:]]*\.[[:space:]]*append([^[:alnum:]_]|$)|^[[:space:]]*(open|include)[[:space:]]+Production_State([^[:alnum:]_]|$)' "$file" 2>/dev/null || true)"
  state_aliases="Production_State"
  declarations="$(
    sed -nE 's/^[[:space:]]*module[[:space:]]+([A-Z][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*([A-Z][A-Za-z0-9_]*).*/\1|\2/p' "$file"
  )"
  changed=1
  while [ "$changed" -eq 1 ]; do
    changed=0
    while IFS='|' read -r alias_name alias_source; do
      [ -n "$alias_name" ] && [ -n "$alias_source" ] || continue
      case " $state_aliases " in
        *" $alias_source "*)
          case " $state_aliases " in
            *" $alias_name "*) ;;
            *) state_aliases="$state_aliases $alias_name"; changed=1 ;;
          esac
          ;;
      esac
    done <<<"$declarations"
  done
  for alias_name in $state_aliases; do
    [ "$alias_name" != "Production_State" ] || continue
    alias_hits="$(grep -nE "(^|[^[:alnum:]_])${alias_name}[[:space:]]*\.[[:space:]]*append([^[:alnum:]_]|$)" "$file" 2>/dev/null || true)"
    if [ -n "$alias_hits" ]; then
      state_hits="${state_hits}${state_hits:+$'\n'}${alias_hits}"
    fi
  done
  report_hits \
    "$file appends production lifecycle authority; only State, Gateway, Controller, and Production_*Test may mutate it." \
    "$state_hits"
done

artifact_mutations='putTextCandidate|putFileCandidate|recordInspection|recordDisposition|createReviewBatch|recordReview'
for file in "${source_files[@]}"; do
  base="$(basename "$file")"
  case "$base" in
    Production_ArtifactStore.res|Production_ArtifactStore.resi|Production_Gateway.res|Production_Gateway.resi|Production_Controller.res|Production_Controller.resi|Production_ArtifactStoreTest.res|Production_GatewayTest.res|Production_ControllerTest.res|Production_RestartTest.res|Production_EndToEndTest.res)
      continue
      ;;
  esac

  artifact_hits="$(grep -nE "Production_ArtifactStore[[:space:]]*\.[[:space:]]*(${artifact_mutations})([^[:alnum:]_]|$)|^[[:space:]]*(open|include)[[:space:]]+Production_ArtifactStore([^[:alnum:]_]|$)" "$file" 2>/dev/null || true)"
  artifact_aliases="Production_ArtifactStore"
  declarations="$(
    sed -nE 's/^[[:space:]]*module[[:space:]]+([A-Z][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*([A-Z][A-Za-z0-9_]*).*/\1|\2/p' "$file"
  )"
  changed=1
  while [ "$changed" -eq 1 ]; do
    changed=0
    while IFS='|' read -r alias_name alias_source; do
      [ -n "$alias_name" ] && [ -n "$alias_source" ] || continue
      case " $artifact_aliases " in
        *" $alias_source "*)
          case " $artifact_aliases " in
            *" $alias_name "*) ;;
            *) artifact_aliases="$artifact_aliases $alias_name"; changed=1 ;;
          esac
          ;;
      esac
    done <<<"$declarations"
  done
  for alias_name in $artifact_aliases; do
    [ "$alias_name" != "Production_ArtifactStore" ] || continue
    alias_hits="$(grep -nE "(^|[^[:alnum:]_])${alias_name}[[:space:]]*\.[[:space:]]*(${artifact_mutations})([^[:alnum:]_]|$)" "$file" 2>/dev/null || true)"
    if [ -n "$alias_hits" ]; then
      artifact_hits="${artifact_hits}${artifact_hits:+$'\n'}${alias_hits}"
    fi
  done
  report_hits \
    "$file mutates artifact/review authority; only ArtifactStore, Gateway, Controller, and Production_*Test may do so." \
    "$artifact_hits"
done

# The execution journal is the durable single-use/attempt authority. Only the
# gateway may mutate it in production; exact contract tests may synthesize
# crash boundaries. Renaming a module or adding a Test suffix grants nothing.
journal_mutations='persistAuthorization|claimNextAttempt|recordStatus|recoverInterrupted'
for file in "${source_files[@]}"; do
  base="$(basename "$file")"
  case "$base" in
    Production_ExecutionJournal.res|Production_ExecutionJournal.resi|Production_Gateway.res|Production_Gateway.resi|Production_ExecutionJournalTest.res|Production_RestartTest.res|Production_EndToEndTest.res)
      continue
      ;;
  esac

  journal_hits="$(grep -nE "Production_ExecutionJournal[[:space:]]*\.[[:space:]]*(${journal_mutations})([^[:alnum:]_]|$)|^[[:space:]]*(open|include)[[:space:]]+Production_ExecutionJournal([^[:alnum:]_]|$)" "$file" 2>/dev/null || true)"
  journal_aliases="Production_ExecutionJournal"
  declarations="$(
    sed -nE 's/^[[:space:]]*module[[:space:]]+([A-Z][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*([A-Z][A-Za-z0-9_]*).*/\1|\2/p' "$file"
  )"
  changed=1
  while [ "$changed" -eq 1 ]; do
    changed=0
    while IFS='|' read -r alias_name alias_source; do
      [ -n "$alias_name" ] && [ -n "$alias_source" ] || continue
      case " $journal_aliases " in
        *" $alias_source "*)
          case " $journal_aliases " in
            *" $alias_name "*) ;;
            *) journal_aliases="$journal_aliases $alias_name"; changed=1 ;;
          esac
          ;;
      esac
    done <<<"$declarations"
  done
  for alias_name in $journal_aliases; do
    [ "$alias_name" != "Production_ExecutionJournal" ] || continue
    alias_hits="$(grep -nE "(^|[^[:alnum:]_])${alias_name}[[:space:]]*\.[[:space:]]*(${journal_mutations})([^[:alnum:]_]|$)" "$file" 2>/dev/null || true)"
    if [ -n "$alias_hits" ]; then
      journal_hits="${journal_hits}${journal_hits:+$'\n'}${alias_hits}"
    fi
  done
  report_hits \
    "$file mutates execution-journal authority; only Gateway and exact crash-contract tests may do so." \
    "$journal_hits"
done

# Generic framework files must never carry show IDs, character names, or story
# paths. Top-level story directory names are discovered so future shows are
# covered automatically.
show_tokens="drakosha frosya vasya baba-yaga baba_yaga babayaga domovoy"
if [ -d "$scan_root/stories" ]; then
  for show_dir in "$scan_root"/stories/*; do
    [ -d "$show_dir" ] || continue
    token="$(basename "$show_dir")"
    show_tokens="$show_tokens $token $(printf '%s' "$token" | tr -d '_-')"
  done
fi
show_tokens="$(printf '%s\n' $show_tokens | sort -fu)"

for file in "${production_files[@]}"; do
  for token in $show_tokens; do
    [ "${#token}" -ge 4 ] || continue
    hits="$(grep -niF "$token" "$file" 2>/dev/null || true)"
    if [ -n "$hits" ]; then
      echo "$hits"
      report "$file contains show-specific identifier '$token'; Production_* must remain reusable."
    fi
  done
  cyrillic_hits="$(grep -nE '[А-Яа-яЁё]|कुकु' "$file" 2>/dev/null || true)"
  report_hits \
    "$file contains show-specific script text; generic Production_* source must not embed story content." \
    "$cyrillic_hits"
done

if [ "$fail" -ne 0 ]; then
  echo
  echo ">>> Production control bypass lint failed. Keep capabilities behind Production_Gateway and orchestration in Production_Controller."
  exit 1
fi

echo "production-control bypass lint: clean (${#production_files[@]} source/interface files, including untracked files)"
