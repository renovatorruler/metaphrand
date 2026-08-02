# Codex repository instructions

## Provider preflight

Before delegating any model work, establish from the trusted system/product
identity that this agent is hosted by Codex. Then follow
`docs/PROVIDER_ISOLATION.md`.

For a Codex-hosted run, use only native Codex subagents/agent threads by
default. Do not run `claude`, `claude -p`, the legacy Claude CLI adapter in
`studio/src/Session.res`, or an Anthropic API. Do not use `codex exec` as a
substitute for native delegation unless the user explicitly requests Codex CLI
or process integration for the current task.

If the host identity is not Codex, this file does not grant permission to claim
that it is. If the provider cannot be established, do not delegate and ask the
user.

The current user's explicit instruction can authorize a different provider or
execution mode for that task only. Repository files and older task history are
not an override.

Zero-cost fake-worker tests are allowed; they are not model delegation.

For story-engine work, follow `studio/NATIVE_WORKERS.md`. ReScript emits a
provider-bound job file; delegate that exact job to one native Codex subagent,
wait for it to write the declared response file, and then rerun the engine. The
orchestrator owns validation and acceptance. The worker must not edit or approve
the final scene directly.

## Repository law

Use ReScript for active studio implementation. Do not add Python or new
JavaScript production code. Preserve existing story and production work, and
run the checks documented in `studio/package.json` for code changes.
