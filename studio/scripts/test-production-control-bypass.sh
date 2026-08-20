#!/usr/bin/env bash
# Adversarial, zero-network self-test for no-production-control-bypass.sh.
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
lint="$script_dir/no-production-control-bypass.sh"
fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/production-control-bypass.XXXXXX")"
trap 'rm -rf "$fixture_root"' EXIT

base="$fixture_root/base"
mkdir -p "$base/studio/src" "$base/studio/scripts" "$base/stories"

# A new repository starts with no reviewed legacy capabilities. The empty,
# present manifest is intentional: absence must fail closed, while an empty
# compatibility surface is valid.
: > "$base/studio/scripts/production-control-legacy-capabilities.sha256"

printf '%s\n' '{"scripts":{"test":"npm run test:production-control","test:production-control":"rescript clean && rescript && bash scripts/no-production-control-bypass.sh && bash scripts/test-production-control-bypass.sh && node src/Production_LeaseTest.res.mjs && node src/Production_DomainTest.res.mjs && node src/Production_StateTest.res.mjs && node src/Production_WorkOrderTest.res.mjs && node src/Production_CredentialsTest.res.mjs && node src/Production_ReferencesTest.res.mjs && node src/Production_InspectionTest.res.mjs && node src/Production_ExecutionJournalTest.res.mjs && node src/Production_ArtifactStoreTest.res.mjs && node src/Production_GatewayTest.res.mjs && node src/Production_ControllerTest.res.mjs && node src/Production_RestartTest.res.mjs && node src/Production_EndToEndTest.res.mjs && bash scripts/test-production-control-concurrency.sh"}}' \
  > "$base/studio/package.json"

modules="Domain Credentials OutputSafety Lease WorkOrder State Inspection ArtifactStore References ExecutionJournal Preflight"
for suffix in $modules; do
  printf '%s\n' 'let fixture = "generic"' > "$base/studio/src/Production_${suffix}.res"
  printf '%s\n' 'let fixture: string' > "$base/studio/src/Production_${suffix}.resi"
done

printf '%s\n' 'type principalCredential' 'type humanCommand' 'let fixture: string' \
  > "$base/studio/src/Production_Credentials.resi"
printf '%s\n' 'type t' 'let fixture: string' \
  > "$base/studio/src/Production_Lease.resi"
printf '%s\n' 'type cleared' 'let fixture: string' \
  > "$base/studio/src/Production_Preflight.resi"
printf '%s\n' 'type authorizationIntent' 'let fixture: string' \
  > "$base/studio/src/Production_ExecutionJournal.resi"
printf '%s\n' 'type store' 'let fixture: string' \
  > "$base/studio/src/Production_ArtifactStore.resi"

test_modules="LeaseTest DomainTest StateTest WorkOrderTest CredentialsTest ReferencesTest InspectionTest ExecutionJournalTest ArtifactStoreTest ControllerTest RestartTest EndToEndTest ConcurrencyTest"
for suffix in $test_modules; do
  printf '%s\n' 'let fixture = "synthetic test"' > "$base/studio/src/Production_${suffix}.res"
done
: > "$base/studio/scripts/test-production-control-concurrency.sh"

printf '%s\n' \
  'exception GatewayError(string)' \
  'type request' \
  'type authorization' \
  'type provider' \
  'type result' \
  'let registerProvider: string => provider' \
  'let authorizationBinding: provider => string' \
  'let authorize: request => authorization' \
  'let recover: string => unit' \
  'let candidateAuthorityCurrent: string => bool' \
  'let execute: (authorization, request) => result' \
  > "$base/studio/src/Production_Gateway.resi"

printf '%s\n' \
  'exception GatewayError(string)' \
  'type request = string' \
  'type authorization = string' \
  'type provider = string' \
  'type result = string' \
  'let registerProvider = value => value' \
  'let authorizationBinding = value => value' \
  'let authorize = request => request' \
  'let recover = _state => ()' \
  'let candidateAuthorityCurrent = _candidate => true' \
  'let execute = (_authorization, request) => request' \
  > "$base/studio/src/Production_Gateway.res"

printf '%s\n' \
  'let run = request => {' \
  '  let authorization = Production_Gateway.authorize(request)' \
  '  Production_Gateway.execute(authorization, request)' \
  '}' \
  > "$base/studio/src/Production_Controller.res"
printf '%s\n' 'let run: Production_Gateway.request => Production_Gateway.result' \
  'type inspector' \
  > "$base/studio/src/Production_Controller.resi"

printf '%s\n' \
  'let contract = request => {' \
  '  let token = Production_Gateway.authorize(request)' \
  '  Production_Gateway.execute(token, request)' \
  '}' \
  > "$base/studio/src/Production_GatewayTest.res"

passes=0

expect_pass() {
  local label="$1"
  local root="$2"
  local output
  if ! output="$(bash "$lint" --fixture-root "$root" 2>&1)"; then
    echo ">>> FAIL: $label should pass"
    echo "$output"
    exit 1
  fi
  passes=$((passes + 1))
}

expect_fail() {
  local label="$1"
  local root="$2"
  local expected="$3"
  local output
  local status
  set +e
  output="$(bash "$lint" --fixture-root "$root" 2>&1)"
  status=$?
  set -e
  if [ "$status" -eq 0 ]; then
    echo ">>> FAIL: $label escaped detection"
    exit 1
  fi
  if ! grep -Fq "$expected" <<<"$output"; then
    echo ">>> FAIL: $label failed for the wrong reason; expected '$expected'"
    echo "$output"
    exit 1
  fi
  passes=$((passes + 1))
}

new_case() {
  local name="$1"
  local root="$fixture_root/$name"
  mkdir -p "$root"
  cp -R "$base/." "$root/"
  printf '%s' "$root"
}

expect_pass "valid narrow gateway and controller-only calls" "$base"

case_root="$(new_case backend_alias)"
printf '%s\n' \
  'module Backend = Cinema_Backends' \
  'module Hidden = Backend' \
  'let bypass = prompt => Hidden.imageGpt2(~prompt, ~refs=[])' \
  > "$case_root/studio/src/Production_Preflight.res"
expect_fail "alias-to-alias paid backend call" "$case_root" "paid-media Cinema_Backends members"

case_root="$(new_case child_process)"
printf '%s\n' \
  '@module("child_process") external spawnSync: (string, array<string>) => unit = "spawnSync"' \
  'let bypass = () => spawnSync("tool", [])' \
  > "$case_root/studio/src/Production_State.res"
expect_fail "direct child process binding" "$case_root" "direct process or network capability"

case_root="$(new_case backend_process)"
printf '%s\n' \
  'module Backend = Cinema_Backends' \
  'let bypass = () => Backend.run(~cmd="fake", ~args=[])' \
  > "$case_root/studio/src/Production_State.res"
expect_fail "direct Cinema_Backends process runner" "$case_root" "paid-media Cinema_Backends members"

case_root="$(new_case network)"
printf '%s\n' \
  'type response' \
  '@val external fetch: string => promise<response> = "fetch"' \
  'let bypass = url => fetch(url)' \
  > "$case_root/studio/src/Production_Inspection.res"
expect_fail "direct network binding" "$case_root" "direct process or network capability"

case_root="$(new_case cli_literal)"
printf '%s\n' 'let command = "higgsfield"' > "$case_root/studio/src/Production_WorkOrder.res"
expect_fail "provider CLI literal" "$case_root" "provider/media CLI literal"

case_root="$(new_case model_boundary)"
printf '%s\n' 'let bypass = prompt => Session.ask(prompt)' > "$case_root/studio/src/Production_Preflight.res"
expect_fail "direct model boundary" "$case_root" "model or media provider module"

case_root="$(new_case unauthorized_direct)"
printf '%s\n' 'let bypass = request => Production_Gateway.execute(Production_Gateway.authorize(request), request)' \
  > "$case_root/studio/src/Production_State.res"
expect_fail "unauthorized direct gateway caller" "$case_root" "only Production_Controller"

case_root="$(new_case unauthorized_alias)"
printf '%s\n' \
  'module Door = Production_Gateway' \
  'module HiddenDoor = Door' \
  'let bypass = request => HiddenDoor.execute(HiddenDoor.authorize(request), request)' \
  > "$case_root/studio/src/Production_Inspection.res"
expect_fail "unauthorized chained-alias gateway caller" "$case_root" "only Production_Controller"

case_root="$(new_case compiled_authority_ffi)"
printf '%s\n' \
  '@module("./Production_State.res.mjs")' \
  'external append: unit => unit = "append"' \
  'let bypass = () => append()' \
  > "$case_root/studio/src/HiddenFfi.res"
expect_fail \
  "compiled Production authority cannot be imported through ReScript FFI" \
  "$case_root" \
  "bypasses ReScript authority through local compiled-module FFI or raw JavaScript"

case_root="$(new_case raw_authority_escape)"
printf '%s\n' \
  'let bypass = %raw(`() => require("./Production_State.res.mjs").append()`)' \
  > "$case_root/studio/src/HiddenRaw.res"
expect_fail \
  "raw JavaScript cannot import compiled Production authority" \
  "$case_root" \
  "bypasses ReScript authority through local compiled-module FFI or raw JavaScript"

case_root="$(new_case renamed_studio_gateway)"
printf '%s\n' \
  'module Door = Production_Gateway' \
  'let bypass = request => Door.execute(Door.authorize(request), request)' \
  > "$case_root/studio/src/HiddenDoor.res"
expect_fail "renamed studio gateway caller" "$case_root" "only Production_Controller"

case_root="$(new_case renamed_legacy_provider)"
printf '%s\n' \
  'let bypass = prompt => Cinema_Backends.imageGpt2(~prompt, ~refs=[])' \
  > "$case_root/studio/src/HiddenLegacyProvider.res"
expect_fail \
  "differently named studio module cannot add legacy provider capability" \
  "$case_root" \
  "adds or wraps provider/process/network capability outside the sole gateway"

case_root="$(new_case legacy_manifest_hash)"
printf '%s\n' 'let command = "ffmpeg"' > "$case_root/studio/src/LegacyMedia.res"
legacy_hash="$(shasum -a 256 "$case_root/studio/src/LegacyMedia.res" | awk '{print $1}')"
printf '%s  %s\n' "$legacy_hash" 'src/LegacyMedia.res' \
  > "$case_root/studio/scripts/production-control-legacy-capabilities.sha256"
expect_pass "reviewed legacy source at its exact hash" "$case_root"
printf '%s\n' 'let command = "ffmpeg changed"' > "$case_root/studio/src/LegacyMedia.res"
expect_fail \
  "manifest-bound legacy source cannot change silently" \
  "$case_root" \
  "Legacy capability source changed without an explicit reviewed manifest update"

case_root="$(new_case orphan_generated_js)"
printf '%s\n' 'export const bypass = true' > "$case_root/studio/src/Hidden.res.mjs"
expect_fail \
  "orphan generated ReScript JavaScript" \
  "$case_root" \
  "Orphan generated ReScript JavaScript is executable authority without reviewed source"

case_root="$(new_case handwritten_provider_script)"
printf '%s\n' '#!/usr/bin/env bash' 'curl https://provider.invalid' \
  > "$case_root/studio/scripts/hidden-provider.sh"
expect_fail \
  "handwritten provider script" \
  "$case_root" \
  "adds handwritten provider/process/network capability outside the sole gateway"

case_root="$(new_case handwritten_authority_import)"
printf '%s\n' \
  'const pieces = ["Production", "State"]' \
  'const moduleName = pieces.join("_") + ".res.mjs"' \
  'export const loadAuthority = () => import("./" + moduleName)' \
  > "$case_root/studio/src/hidden-authority.mjs"
expect_fail \
  "handwritten JavaScript cannot dynamically import compiled authority" \
  "$case_root" \
  "new handwritten executable code outside the reviewed legacy-script manifest"

case_root="$(new_case test_like_gateway)"
printf '%s\n' \
  'module Door = Production_Gateway' \
  'let bypass = request => Door.execute(Door.authorize(request), request)' \
  > "$case_root/studio/src/Production_BypassTest.res"
expect_fail "unapproved test-like gateway caller" "$case_root" "exact synthetic contract modules"

case_root="$(new_case standard_test_bypass)"
printf '%s\n' '{"scripts":{"test":"echo skipped","test:production-control":"bash scripts/no-production-control-bypass.sh && bash scripts/test-production-control-bypass.sh"}}' \
  > "$case_root/studio/package.json"
expect_fail "standard npm test cannot omit production control" "$case_root" "standard npm test must invoke"

case_root="$(new_case omitted_e2e_test)"
sed 's/ && node src\/Production_EndToEndTest.res.mjs//' \
  "$case_root/studio/package.json" > "$case_root/studio/package.json.next"
mv "$case_root/studio/package.json.next" "$case_root/studio/package.json"
expect_fail \
  "production-control command cannot omit the end-to-end suite" \
  "$case_root" \
  "must run required production-control test 'Production_EndToEndTest.res.mjs'"

case_root="$(new_case deleted_restart_test)"
rm "$case_root/studio/src/Production_RestartTest.res"
expect_fail \
  "required restart test source cannot disappear silently" \
  "$case_root" \
  "Required production-control test source Production_RestartTest.res is missing"

case_root="$(new_case opaque_forgery)"
printf '%s\n' \
  'let forgedAuthorization = value => Obj.magic(value)' \
  > "$case_root/studio/src/Production_Preflight.res"
expect_fail "opaque authorization forgery" "$case_root" "unsafe type escape"

case_root="$(new_case lifecycle_mutation)"
printf '%s\n' \
  'module Ledger = Production_State' \
  'module HiddenLedger = Ledger' \
  'let bypass = args => HiddenLedger.append(args)' \
  > "$case_root/studio/src/HiddenLifecycle.res"
expect_fail "renamed lifecycle authority mutation" "$case_root" "appends production lifecycle authority"

case_root="$(new_case artifact_mutation)"
printf '%s\n' \
  'module Store = Production_ArtifactStore' \
  'module HiddenStore = Store' \
  'let bypass = store => HiddenStore.createReviewBatch(~store)' \
  > "$case_root/studio/src/HiddenReview.res"
expect_fail "renamed artifact review mutation" "$case_root" "mutates artifact/review authority"

case_root="$(new_case journal_mutation)"
printf '%s\n' \
  'module Journal = Production_ExecutionJournal' \
  'module HiddenJournal = Journal' \
  'let bypass = args => HiddenJournal.recordStatus(args)' \
  > "$case_root/studio/src/HiddenExecution.res"
expect_fail "renamed execution-journal mutation" "$case_root" "mutates execution-journal authority"

case_root="$(new_case wide_interface)"
printf '%s\n' 'let rawProviderCall: string => unit' >> "$case_root/studio/src/Production_Gateway.resi"
expect_fail "wide gateway interface" "$case_root" "must export exactly registerProvider"

case_root="$(new_case widened_preflight_clearance)"
printf '%s\n' 'type cleared = string' 'let fixture: string' \
  > "$case_root/studio/src/Production_Preflight.resi"
expect_fail \
  "preflight clearance cannot be widened into caller data" \
  "$case_root" \
  "Production_Preflight.resi must keep capability type 'cleared' opaque"

case_root="$(new_case executable_gateway)"
printf '%s\n' 'let main = () => ()' 'main()' >> "$case_root/studio/src/Production_Gateway.res"
expect_fail "executable gateway" "$case_root" "must not define/call a main entrypoint"

case_root="$(new_case show_leak)"
printf '%s\n' 'let character = "Frosya"' > "$case_root/studio/src/Production_Domain.res"
expect_fail "show-specific source" "$case_root" "show-specific identifier"

case_root="$(new_case misplaced_untracked)"
mkdir -p "$case_root/stories/example/artifacts"
printf '%s\n' 'let bypass = "untracked"' > "$case_root/stories/example/artifacts/Production_Bypass.res"
expect_fail "untracked Production source in artifact tree" "$case_root" "allowed only in studio/src"

case_root="$(new_case renamed_story_code)"
mkdir -p "$case_root/stories/example/artifacts"
printf '%s\n' 'let bypass = "renamed"' > "$case_root/stories/example/artifacts/HiddenDoor.res"
expect_fail "renamed untracked ReScript in story artifact tree" "$case_root" "ReScript is forbidden in stories"

case_root="$(new_case renamed_artifact_code)"
mkdir -p "$case_root/runtime/artifacts"
printf '%s\n' 'let bypass = "renamed"' > "$case_root/runtime/artifacts/HiddenDoor.res"
expect_fail "renamed untracked ReScript in non-story artifact tree" "$case_root" "ReScript is forbidden in artifact trees"

echo "production-control bypass adversarial tests: clean ($passes cases, zero provider/network calls)"
