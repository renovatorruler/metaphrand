#!/usr/bin/env bash
# Scene 1 generation is allowed through exactly one guarded ReScript boundary.
# This is an accidental-bypass ratchet: it scans the working tree, including
# untracked files, so a new local provider script cannot silently skip the gate.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
studio_src="$repo_root/studio/src"
scene_root="$repo_root/stories/drakosha/ep1prod/scene1"
runner="$studio_src/Drakosha_SceneFlow.res"
runner_interface="$studio_src/Drakosha_SceneFlow.resi"
cli="$studio_src/Drakosha_SceneFlowCli.res"
flow_test="$studio_src/Drakosha_SceneFlowTest.res"
manifest="$scene_root/scene1.production.v1.json"
human_state="$scene_root/CURRENT.md"
package_json="$repo_root/studio/package.json"
fail=0

report() {
  echo ">>> $1"
  fail=1
}

if [ ! -f "$runner" ] || [ ! -f "$runner_interface" ] || [ ! -f "$cli" ] || [ ! -f "$manifest" ]; then
  report "Scene 1 guarded runner, narrow interface, CLI, or canonical manifest is missing."
else
  if ! grep -Fq 'let lockedRaw = requireFormalReadiness(m.path, stage)' "$runner" ||
    ! grep -Fq 'let candidateRaw = requireFormalReadiness(m.path, stage)' "$runner"; then
    report "The paid generation boundary no longer reruns formal readiness inside the lease and immediately before submission."
  fi
  if ! grep -Fq 'requireCanonicalRequest(' "$runner"; then
    report "The paid boundary no longer compares the actual request with generationSpec."
  fi
  if ! grep -Fq 'let safeOutput = safeSceneOutputPath(m, out, "generation output")' "$runner" ||
    ! grep -Fq 'Drakosha_OutputSafety.manifestOutputPath(' "$runner"; then
    report "Scene 1 generation outputs and receipt directories are no longer protected from traversal or symlink escape."
  fi
  if [ "$(grep -Fc 'authorityStillMatches()' "$runner")" -ne 2 ] ||
    ! grep -Fq 'B.removeFile(B.Path(out))' "$runner"; then
    report "The runner no longer revalidates authority both before download and immediately before success commit."
  fi
  if ! grep -Fq 'B.writeTextExclusive(B.Path(attemptReceiptPath' "$runner"; then
    report "The paid generation boundary no longer claims attempts atomically."
  fi
  if ! grep -Fq 'withSubjectLock(fresh, subjectId' "$runner"; then
    report "The paid generation boundary no longer holds an exclusive per-target lease."
  fi
  if ! grep -Fq 'if attempt > m.maxPaidAttemptsPerTarget' "$runner"; then
    report "The per-target paid-attempt ceiling is missing."
  fi
  if ! grep -Fq 'B.writeText(B.Path(successReceiptPath(out)), success)' "$runner"; then
    report "The adjacent success receipt commit is missing."
  fi
  if [ "$(grep -Fc '~cmd="higgsfield"' "$runner")" -ne 2 ]; then
    report "The guarded runner must contain exactly one paid Higgsfield call and one account-status call."
  fi
  if grep -Eq '^main\(\)' "$runner"; then
    report "The core Scene 1 runner became directly executable; only its guarded CLI may have an entrypoint."
  fi
  if ! grep -Fq 'Drakosha_SceneFlow.runStage' "$cli"; then
    report "The Scene 1 CLI no longer delegates to the guarded runStage boundary."
  fi
  exported_lines="$(grep -Ec '^(let|type|exception) ' "$runner_interface" || true)"
  if [ "$exported_lines" -ne 2 ] ||
    ! grep -Fq 'exception FlowError(string)' "$runner_interface" ||
    ! grep -Fq 'let runStage:' "$runner_interface"; then
    report "The Scene 1 interface must expose only FlowError and runStage."
  fi
  if ! grep -Fq '"canonicalRunner": "studio/src/Drakosha_SceneFlowCli.res.mjs"' "$manifest"; then
    report "The canonical manifest does not pin the guarded Scene 1 CLI."
  fi
  if ! grep -Fq '"maxPaidAttemptsPerTarget": 2' "$manifest"; then
    report "The canonical manifest no longer limits each target to two paid attempts."
  fi
  manifest_hash="$(shasum -a 256 "$manifest" | awk '{print $1}')"
  if [ ! -f "$human_state" ] ||
    ! grep -Fq "**Manifest SHA-256:** \`$manifest_hash\`" "$human_state"; then
    report "CURRENT.md does not bind the exact canonical manifest bytes."
  fi
fi

if [ ! -f "$studio_src/Kuku_Gen.res" ] ||
  ! grep -Fq 'let dir = requireKukuEpisodeDir(dir)' "$studio_src/Kuku_Gen.res" ||
  ! grep -Fq 'let name = safeShotName(name)' "$studio_src/Kuku_Gen.res" ||
  ! grep -Fq 'let outputDir = requireRealKukuPath(' "$studio_src/Kuku_Gen.res" ||
  ! grep -Fq '@module("fs") external realpathSync' "$studio_src/Kuku_Gen.res" ||
  ! grep -Fq 'Drakosha Scene 1 must use Drakosha_SceneFlowCli' "$studio_src/Kuku_Gen.res"; then
  report "The legacy Kuku generator is no longer runtime-confined to real stories/kuku paths with traversal-safe shot names."
fi

# When emitted code exists, verify the executable boundary too. This catches a
# stale pre-guard Kuku_Gen.res.mjs before an official Scene 1 flow clean-builds.
compiled_kuku="$studio_src/Kuku_Gen.res.mjs"
if [ -f "$compiled_kuku" ]; then
  set +e
  kuku_boundary_output="$(
    cd "$repo_root/studio" &&
      DRY=1 node src/Kuku_Gen.res.mjs ../stories/drakosha/ep1prod/scene1 __boundary_probe_missing__.json 2>&1
  )"
  kuku_boundary_status=$?
  set -e
  if [ "$kuku_boundary_status" -eq 0 ] ||
    ! grep -Fq 'Kuku_Gen may write only inside stories/kuku' <<<"$kuku_boundary_output"; then
    report "The emitted Kuku generator can reach the Scene 1 tree; clean-build the guarded source."
  fi
fi

alternate_provider_hits="$(
  find "$studio_src" -type f \( -name 'Drakosha_*.res' -o -name 'Drakosha_*.resi' \) \
    ! -path "$runner" ! -path "$flow_test" -print0 \
    | xargs -0 grep -nE 'higgsfield|nano_banana|gemini_omni|Cinema_Backends\.(image|imageGpt2|imageToVideo|videoSora|falSeedance2)|B\.(image|imageGpt2|imageToVideo|videoSora|falSeedance2)' 2>/dev/null \
    || true
)"
if [ -n "$alternate_provider_hits" ]; then
  echo "$alternate_provider_hits"
  report "A Drakosha source file contains an alternate visual-generation provider path."
fi

direct_higgsfield_hits="$(
  find "$studio_src" -type f \( -name '*.res' -o -name '*.resi' \) \
    ! -path "$runner" \
    ! -path "$studio_src/Kuku_CharSheet.res" \
    ! -path "$studio_src/Kuku_Gen.res" \
    -print0 \
    | xargs -0 grep -nF '~cmd="higgsfield"' 2>/dev/null || true
)"
if [ -n "$direct_higgsfield_hits" ]; then
  echo "$direct_higgsfield_hits"
  report "Only the guarded Scene 1 implementation may spawn the Higgsfield CLI."
fi

if grep -Eq 'Drakosha_SceneFlow\.(paidGenerate|genImage|genClip|stageRefs|stageStoryboard|stageMotion)' "$studio_src"/*.res 2>/dev/null; then
  report "A source file calls a private Scene 1 generation helper instead of runStage."
fi

scene_code="$(
  find "$scene_root" -type f \( \
    -name '*.py' -o -name '*.pyc' -o -name '*.js' -o -name '*.mjs' -o \
    -name '*.cjs' -o -name '*.ts' -o -name '*.tsx' -o -name '*.sh' -o \
    -name '*.bash' -o -name '*.zsh' -o -name '*.res' -o -name '*.resi' \
  \) -print 2>/dev/null || true
)"
if [ -n "$scene_code" ]; then
  echo "$scene_code"
  report "Executable/source generation code is forbidden inside the Scene 1 artifact directory."
fi

if grep -Fq 'Drakosha_SceneFlow.res.mjs' "$package_json"; then
  report "package.json invokes the core Scene 1 module directly instead of the guarded CLI."
fi

flow_script_count="$(grep -Ec 'flow:scene1:(refs|storyboard|motion).*rescript clean && rescript && node src/Drakosha_SceneFlowCli\.res\.mjs' "$package_json" || true)"
if [ "$flow_script_count" -ne 3 ]; then
  report "Every Scene 1 flow script must clean-rebuild ReScript before invoking the guarded CLI."
fi

if [ "$fail" -ne 0 ]; then
  echo
  echo ">>> Scene 1 generation bypass lint failed. Use Drakosha_SceneFlowCli only."
  exit 1
fi

echo "Scene 1 generation bypass lint: clean"
