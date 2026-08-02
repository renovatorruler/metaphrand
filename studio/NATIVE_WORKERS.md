# Native worker handoff

The ReScript engine prepares model jobs but never chooses or launches a real
provider by default. The host orchestrator delegates each job through its own
native worker mechanism:

- Codex host -> native Codex subagent;
- Claude host -> native Claude subagent;
- unknown host -> refuse.

This keeps the orchestrator, creative worker, and deterministic engine as three
separate roles.

## Run a driver

Create one new, empty job directory for the production run. Reuse that directory
while completing the run; do not reuse it for a different scene or driver.

```bash
native_job_dir="$(mktemp -d)"
STUDIO_NATIVE_WORKER_PROVIDER=codex \
STUDIO_NATIVE_JOB_DIR="$native_job_dir" \
STUDIO_WORKER_BUDGET=4 \
node src/<Driver>.res.mjs
```

Use `claude` instead of `codex` only when the trusted host identity is Claude.

When a model response is needed, the driver refuses with
`NATIVE_WORKER_REQUIRED` and names a `.job.json` file. That job contains:

- the resolved provider;
- the exact prompt and its SHA-256 hash;
- the turn number;
- the exact `responsePath` where the worker must put its answer.

The orchestrator gives that one job to one native worker. The worker follows the
prompt and writes only its final answer to `responsePath`. It must not run a
provider CLI, call an API, approve its own result, or edit the final scene file.

Run the same driver again with the same environment and job directory. ReScript
consumes the response, applies the craft gates, and either finishes or emits the
next bounded job. Repeat until the driver succeeds or the budget is exhausted.

Accepted responses consume `STUDIO_WORKER_BUDGET`. Merely preparing a job does
not. Only one unresolved job may exist in the run directory; later prompts wait
until it has a response. A finished scene receipt records the native worker
provider.

## Safety properties

- No provider is inferred from installed binaries or repository content.
- A positive budget alone cannot start Claude, Codex, or any other model.
- The engine permits only one unresolved native-worker job at a time.
- The response filename includes the prompt hash, so a response for a different
  prompt is not silently consumed.
- A new job directory prevents stale responses from an older run being replayed.
- Fake-worker tests use their own explicit mode and make no external model call.

## Historical Claude CLI mode

The legacy Claude process remains temporarily available for compatibility, but is
disabled by default. It requires both `STUDIO_ALLOW_CLAUDE_CLI=1` and a positive
`CLAUDE_STUDIO_BUDGET`. Under `docs/PROVIDER_ISOLATION.md`, those variables may
be used only after the user explicitly requests Claude CLI integration for the
current task.
