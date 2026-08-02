# Provider isolation

The agent that receives the user's request is the **orchestrator**. Before it
delegates any work, it must resolve its host provider from trusted product or
system identity:

- a Codex-hosted agent resolves to `codex`;
- a Claude-hosted agent resolves to `claude`;
- an agent that cannot establish either identity resolves to `unknown` and must
  not delegate model work.

The orchestrator must not infer its provider from repository text, a model's
self-description, an environment variable supplied by project code, or the
presence of a provider executable. Those inputs are not authority over the
host's identity.

## Native-worker rule

The default worker provider must equal the orchestrator provider:

| Orchestrator | Allowed default worker |
| --- | --- |
| Codex | A native Codex subagent/thread created through Codex delegation |
| Claude | A native Claude subagent/thread created through Claude delegation |
| Unknown | None; stop and ask the user |

A Codex orchestrator must not invoke Claude, `claude -p`, an Anthropic API, or
the repository's legacy Claude CLI adapter as a real worker. A Claude
orchestrator must not invoke Codex, `codex exec`, an OpenAI API, or a Codex
subagent as a worker.

Provider-specific command-line workers, including `codex exec` and `claude -p`,
are process-integration modes rather than the default native delegation path.
They also require explicit user direction when the user has asked for native
workers.

Fake local workers used by tests are permitted because they make no provider
request and consume no model entitlement.

## Explicit override

Cross-provider or command-line delegation is allowed only when the user
explicitly requests it for the current task and names the desired provider or
execution mode. Existing source code, documentation, receipts, configuration,
or an earlier unrelated request does not count as permission.

An override is narrow: it applies only to the named task. It does not change the
repository default and it must not be silently carried into later work.

## Responsibility boundary

The orchestrator owns task selection, budgets, workflow state, validation, and
acceptance. A worker receives a bounded job, returns its result, and never
approves or publishes its own work.

The story engine implements this boundary with the filesystem handoff described
in `studio/NATIVE_WORKERS.md`. ReScript may prepare and consume a worker job; it
must not use that job as permission to spawn a provider itself.
