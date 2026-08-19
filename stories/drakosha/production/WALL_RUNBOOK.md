# The credential wall — human setup runbook

One-time setup, ~5 minutes, needs the admin password. After this, no agent session can spend Higgsfield credits directly: the session credential lives in an account the agent cannot read, and spending happens only through the guarded submit command, which validates artifacts and enforces the allowance you set.

## Why (one paragraph)
Every failure this week reduced to: the agent holds spending power, and rules do not bind a fresh agent instance (the bypass lint reported *clean* while a whole rnd/ pipeline spent outside the boundary). The fix is capability removal: credentials move behind a user boundary, budget and ledger live there too, and the agent's only power is preparing job artifacts.

## Steps (run in Terminal yourself, not through the agent)

1. Create the gate account (no login shell, hidden from login window):
   ```
   sudo sysadminctl -addUser hfgate -fullName "Higgsfield Gate" -password - -shell /usr/bin/false
   sudo dscl . create /Users/hfgate IsHidden 1
   ```
2. Move the Higgsfield session to it (auth confirmed at ~/.config/higgsfield: config.json + credentials.json; the target path is where the CLI will look when HOME=/Users/hfgate/gate):
   ```
   sudo mkdir -p /Users/hfgate/gate/.config
   sudo mv ~/.config/higgsfield /Users/hfgate/gate/.config/higgsfield
   sudo chown -R hfgate /Users/hfgate/gate
   sudo chmod -R 700 /Users/hfgate/gate
   ```
   From this moment `higgsfield` commands in any agent shell fail unauthenticated. That is the wall.
3. Create the allowance file (the human-held budget; agents cannot write it):
   ```
   echo '{"allowance_credits": 0}' | sudo tee /Users/hfgate/gate/allowance.json
   sudo chown hfgate /Users/hfgate/gate/allowance.json && sudo chmod 600 /Users/hfgate/gate/allowance.json
   ```
4. Grant exactly one passwordless path through the wall — the guarded submitter, nothing else:
   ```
   sudo tee /etc/sudoers.d/hfgate <<'EOF'
   dusty ALL=(hfgate) NOPASSWD: /usr/local/bin/hfgate-submit
   EOF
   ```
   The wrapper is already written at `stories/drakosha/production/hfgate-submit` — install it first:
   ```
   sudo cp /Users/dusty/dev/metaphrand/stories/drakosha/production/hfgate-submit /usr/local/bin/hfgate-submit
   sudo chmod 755 /usr/local/bin/hfgate-submit
   ```
   It sets HOME to the gate directory and runs the compiled gate program (`studio/src/Drakosha_GateSubmit.res.mjs`), which validates, budgets, ledgers, and submits — job IDs only, no prompt input.
5. Topping up the budget = human presence, every time (password prompt is the point):
   ```
   sudo -u hfgate sh -c 'echo "{\"allowance_credits\": 500}" > /Users/hfgate/gate/allowance.json'
   ```
6. The ledger is append-only at `/Users/hfgate/gate/ledger.jsonl` — every job: artifact sha, cost, balance before/after, output url. Read it anytime with `sudo -u hfgate cat /Users/hfgate/gate/ledger.jsonl`.

## What the agent can and cannot do afterward
- CAN: prepare shot-record artifacts, run readiness, run `sudo -u hfgate hfgate-submit <artifact>`.
- CANNOT: call higgsfield directly (no auth), raise the allowance, edit the ledger, or submit anything that fails validation inside the gate.
