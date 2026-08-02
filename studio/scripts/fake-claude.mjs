#!/usr/bin/env node
// A fake `claude` that speaks the stream-json protocol, for testing the warm
// Session plumbing with ZERO model spend. Ignores argv. Reads user messages on
// stdin (one JSON object per line), replies with one `result` line each.
// Logs receipt order to stderr so we can SEE that turns arrive serialized.
process.stdout.write(JSON.stringify({ type: "system", subtype: "init", note: "ignored event" }) + "\n");
let buf = "";
let n = 0;
process.stdin.setEncoding("utf8");
process.stdin.on("data", (c) => {
  buf += c;
  let i;
  while ((i = buf.indexOf("\n")) >= 0) {
    const line = buf.slice(0, i);
    buf = buf.slice(i + 1);
    if (!line.trim()) continue;
    let text = "?";
    try {
      const m = JSON.parse(line);
      const content = m.message && m.message.content;
      text = Array.isArray(content) ? content.map((b) => b.text).join("") : String(content);
    } catch {}
    n += 1;
    const idx = n;
    const preview = text.length > 96 ? text.slice(0, 96) + "..." : text;
    process.stderr.write(`[fake] recv #${idx}: ${preview.replaceAll("\n", " ")}\n`);
    // The smoke test sends "hello" (slow) then "world" (fast) to prove queueing.
    // The timeout test sends "slow", kills this process, then sends "fast" to a
    // fresh process; prompt-based delay keeps that second process fast too.
    const delay = text === "slow" ? 1000 : text === "hello" ? 200 : 10;
    setTimeout(() => {
      const reply = text.includes("You are lifting the DIALOGUE")
        ? "NONE"
        : text.includes("You are ADDING one short beat")
          ? "ACTION: The door opens."
          : "echo:" + text;
      const out = {
        type: "result",
        subtype: "success",
        is_error: false,
        result: reply,
        usage: {
          input_tokens: 3,
          output_tokens: 4,
          cache_read_input_tokens: idx === 1 ? 0 : 1234,
          cache_creation_input_tokens: idx === 1 ? 5678 : 0,
        },
        total_cost_usd: 0.0001,
      };
      process.stdout.write(JSON.stringify(out) + "\n");
    }, delay);
  }
});
