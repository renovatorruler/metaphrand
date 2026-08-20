#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
studio_root="$(cd "$script_dir/.." && pwd)"
scratch="$(mktemp -d "${TMPDIR:-/tmp}/production-control-concurrency.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT

descriptor="$scratch/descriptor.txt"
calls="$scratch/calls"
ready="$scratch/ready"
results="$scratch/results"
gate="$scratch/start.gate"
mkdir -p "$calls" "$ready" "$results"

node "$studio_root/src/Production_ConcurrencyTest.res.mjs" setup "$descriptor"
packet_path="$(sed -n '1p' "$descriptor")"
state_dir="$(sed -n '2p' "$descriptor")"

node "$studio_root/src/Production_ConcurrencyTest.res.mjs" worker \
  "$packet_path" "$state_dir" "$calls" "$ready/one" "$gate" "$results/one" &
worker_one=$!
node "$studio_root/src/Production_ConcurrencyTest.res.mjs" worker \
  "$packet_path" "$state_dir" "$calls" "$ready/two" "$gate" "$results/two" &
worker_two=$!

ready_count=0
for _ in $(seq 1 500); do
  ready_count="$(find "$ready" -type f | wc -l | tr -d ' ')"
  if [ "$ready_count" -eq 2 ]; then
    break
  fi
  sleep 0.01
done
if [ "$ready_count" -ne 2 ]; then
  echo ">>> concurrent workers did not reach the start gate" >&2
  exit 1
fi

touch "$gate"
wait "$worker_one"
wait "$worker_two"

call_count="$(find "$calls" -type f | wc -l | tr -d ' ')"
success_count="$(grep -l '^success ' "$results"/* 2>/dev/null | wc -l | tr -d ' ')"
refused_count="$(grep -l '^refused ' "$results"/* 2>/dev/null | wc -l | tr -d ' ')"

if [ "$call_count" -ne 1 ] || [ "$success_count" -ne 1 ] || [ "$refused_count" -ne 1 ]; then
  echo ">>> concurrency contract failed: calls=$call_count success=$success_count refused=$refused_count" >&2
  exit 1
fi

echo "production-control concurrency: clean (2 processes, exactly 1 fake provider call)"

# Crash one live lease holder. A SQLite transaction is released by the kernel
# when the process dies, so there is no deletable stale owner file to race over.
lease_state="$scratch/lease-state"
lease_ready="$scratch/lease-holder.ready"
lease_never_release="$scratch/lease-holder.never-release"
mkdir -p "$lease_state"
node "$studio_root/src/Production_ConcurrencyTest.res.mjs" lease-hold \
  "$lease_state" "$lease_ready" "$lease_never_release" &
stale_owner=$!

for _ in $(seq 1 500); do
  if [ -f "$lease_ready" ]; then
    break
  fi
  sleep 0.01
done
if [ ! -f "$lease_ready" ]; then
  echo ">>> stale lease holder did not acquire its lease" >&2
  exit 1
fi
kill -9 "$stale_owner"
wait "$stale_owner" 2>/dev/null || true

# Two reclaimers start after the crash. Exactly one may own the recovered lease
# while it waits at the release gate; the other must fail closed.
lease_race_ready="$scratch/lease-race-ready"
lease_race_results="$scratch/lease-race-results"
lease_acquired="$scratch/lease-acquired"
lease_start="$scratch/lease-race.start"
lease_release="$scratch/lease-race.release"
mkdir -p "$lease_race_ready" "$lease_race_results" "$lease_acquired"

node "$studio_root/src/Production_ConcurrencyTest.res.mjs" lease-race \
  "$lease_state" "$lease_race_ready/one" "$lease_start" "$lease_release" \
  "$lease_acquired/one" "$lease_race_results/one" &
reclaimer_one=$!
node "$studio_root/src/Production_ConcurrencyTest.res.mjs" lease-race \
  "$lease_state" "$lease_race_ready/two" "$lease_start" "$lease_release" \
  "$lease_acquired/two" "$lease_race_results/two" &
reclaimer_two=$!

lease_ready_count=0
for _ in $(seq 1 500); do
  lease_ready_count="$(find "$lease_race_ready" -type f | wc -l | tr -d ' ')"
  if [ "$lease_ready_count" -eq 2 ]; then
    break
  fi
  sleep 0.01
done
if [ "$lease_ready_count" -ne 2 ]; then
  echo ">>> lease reclaimers did not reach the start gate" >&2
  exit 1
fi
touch "$lease_start"

acquired_count=0
refused_count=0
for _ in $(seq 1 500); do
  acquired_count="$(find "$lease_acquired" -type f | wc -l | tr -d ' ')"
  refused_count="$(find "$lease_race_results" -type f -exec grep -l '^refused$' {} + 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$acquired_count" -eq 1 ] && [ "$refused_count" -eq 1 ]; then
    break
  fi
  sleep 0.01
done
if [ "$acquired_count" -ne 1 ] || [ "$refused_count" -ne 1 ]; then
  echo ">>> stale lease race failed before release: acquired=$acquired_count refused=$refused_count" >&2
  exit 1
fi

touch "$lease_release"
wait "$reclaimer_one"
wait "$reclaimer_two"

recovered_count="$(find "$lease_race_results" -type f -exec grep -l '^acquired$' {} + 2>/dev/null | wc -l | tr -d ' ')"
if [ "$recovered_count" -ne 1 ]; then
  echo ">>> stale lease recovery did not produce exactly one owner: recovered=$recovered_count" >&2
  exit 1
fi

echo "production-control lease recovery: clean (crashed owner, 2 reclaimers, exactly 1 owner)"

# A queue materializer holds the lifecycle lease around both its anchored read
# and derived writes. A newer reconciliation must wait, then publish queues
# bound to its newer head; it cannot be overwritten later by the older view.
queue_descriptor="$scratch/queue-descriptor.txt"
node "$studio_root/src/Production_ConcurrencyTest.res.mjs" setup "$queue_descriptor"
queue_packet_path="$(sed -n '1p' "$queue_descriptor")"
queue_state_dir="$(sed -n '2p' "$queue_descriptor")"
queue_reference_path="$(sed -n '4p' "$queue_descriptor")"
state_view_ready="$scratch/state-view.ready"
state_view_release="$scratch/state-view.release"
state_view_result="$scratch/state-view.result"
state_update_ready="$scratch/state-update.ready"
state_update_result="$scratch/state-update.result"

node "$studio_root/src/Production_ConcurrencyTest.res.mjs" state-view-hold \
  "$queue_state_dir" "$state_view_ready" "$state_view_release" "$state_view_result" &
state_view_pid=$!

for _ in $(seq 1 500); do
  if [ -f "$state_view_ready" ]; then
    break
  fi
  sleep 0.01
done
if [ ! -f "$state_view_ready" ]; then
  echo ">>> consistent state-view holder did not acquire the lifecycle lease" >&2
  exit 1
fi

node "$studio_root/src/Production_ConcurrencyTest.res.mjs" state-append-refresh \
  "$queue_packet_path" "$queue_state_dir" "$queue_reference_path" \
  "$state_update_ready" "$state_update_result" &
state_update_pid=$!

for _ in $(seq 1 500); do
  if [ -f "$state_update_ready" ]; then
    break
  fi
  sleep 0.01
done
if [ ! -f "$state_update_ready" ]; then
  touch "$state_view_release"
  wait "$state_view_pid"
  wait "$state_update_pid" || true
  echo ">>> newer state updater did not reach the lifecycle lease" >&2
  exit 1
fi

sleep 0.1
if [ -f "$state_update_result" ]; then
  touch "$state_view_release"
  wait "$state_view_pid"
  wait "$state_update_pid"
  echo ">>> newer lifecycle update crossed an active consistent-view lease" >&2
  exit 1
fi

touch "$state_view_release"
wait "$state_view_pid"
wait "$state_update_pid"

if ! grep -q '^released EVT-' "$state_view_result" || \
  ! grep -q '^current EVT-' "$state_update_result"; then
  echo ">>> queue ordering regression did not preserve the newest anchored snapshot" >&2
  exit 1
fi

echo "production-control queue ordering: clean (older view completes before newer anchored queues)"

# Hold the artifact store's real review-batch lease while two independent
# processes line up to claim the same eligible candidate. Once released, both
# callers must complete against one serialized read-select-write history: one
# creates the immutable batch and the other observes that nothing remains.
artifact_root="$scratch/artifact-store"
artifact_descriptor="$scratch/artifact-descriptor.txt"
artifact_holder_ready="$scratch/artifact-holder.ready"
artifact_release="$scratch/artifact-holder.release"
artifact_worker_ready="$scratch/artifact-worker-ready"
artifact_worker_attempts="$scratch/artifact-worker-attempts"
artifact_results="$scratch/artifact-results"
artifact_start="$scratch/artifact-workers.start"
mkdir -p "$artifact_worker_ready" "$artifact_worker_attempts" "$artifact_results"

node "$studio_root/src/Production_ArtifactStoreTest.res.mjs" concurrency-setup \
  "$artifact_root" "$artifact_descriptor"
artifact_target="$(sed -n '1p' "$artifact_descriptor")"
artifact_packet="$(sed -n '2p' "$artifact_descriptor")"
artifact_work_order="$(sed -n '3p' "$artifact_descriptor")"
artifact_candidate="$(sed -n '4p' "$artifact_descriptor")"

node "$studio_root/src/Production_ArtifactStoreTest.res.mjs" concurrency-lease-hold \
  "$artifact_root" "$artifact_holder_ready" "$artifact_release" &
artifact_holder=$!

for _ in $(seq 1 500); do
  if [ -f "$artifact_holder_ready" ]; then
    break
  fi
  sleep 0.01
done
if [ ! -f "$artifact_holder_ready" ]; then
  echo ">>> artifact batch lease holder did not acquire its lease" >&2
  exit 1
fi

node "$studio_root/src/Production_ArtifactStoreTest.res.mjs" concurrency-worker \
  "$artifact_root" "$artifact_target" "$artifact_packet" "$artifact_work_order" \
  "$artifact_worker_ready/one" "$artifact_start" "$artifact_worker_attempts/one" \
  "$artifact_results/one" &
artifact_worker_one=$!
node "$studio_root/src/Production_ArtifactStoreTest.res.mjs" concurrency-worker \
  "$artifact_root" "$artifact_target" "$artifact_packet" "$artifact_work_order" \
  "$artifact_worker_ready/two" "$artifact_start" "$artifact_worker_attempts/two" \
  "$artifact_results/two" &
artifact_worker_two=$!

artifact_ready_count=0
for _ in $(seq 1 500); do
  artifact_ready_count="$(find "$artifact_worker_ready" -type f | wc -l | tr -d ' ')"
  if [ "$artifact_ready_count" -eq 2 ]; then
    break
  fi
  sleep 0.01
done
if [ "$artifact_ready_count" -ne 2 ]; then
  echo ">>> artifact batch workers did not reach the start gate" >&2
  exit 1
fi
touch "$artifact_start"

artifact_attempt_count=0
for _ in $(seq 1 500); do
  artifact_attempt_count="$(find "$artifact_worker_attempts" -type f | wc -l | tr -d ' ')"
  if [ "$artifact_attempt_count" -eq 2 ]; then
    break
  fi
  sleep 0.01
done
if [ "$artifact_attempt_count" -ne 2 ]; then
  echo ">>> artifact batch workers did not attempt their concurrent claims" >&2
  exit 1
fi

touch "$artifact_release"
wait "$artifact_holder"
wait "$artifact_worker_one"
wait "$artifact_worker_two"

artifact_batched_count="$(awk 'BEGIN { n=0 } /^batched / { n++ } END { print n }' "$artifact_results"/*)"
artifact_none_count="$(awk 'BEGIN { n=0 } /^none$/ { n++ } END { print n }' "$artifact_results"/*)"
artifact_refused_count="$(awk 'BEGIN { n=0 } /^refused / { n++ } END { print n }' "$artifact_results"/*)"
if [ "$artifact_batched_count" -ne 1 ] || [ "$artifact_none_count" -ne 1 ] || [ "$artifact_refused_count" -ne 0 ]; then
  echo ">>> artifact batch concurrency failed: batched=$artifact_batched_count none=$artifact_none_count refused=$artifact_refused_count" >&2
  exit 1
fi

node "$studio_root/src/Production_ArtifactStoreTest.res.mjs" concurrency-verify \
  "$artifact_root" "$artifact_candidate"
