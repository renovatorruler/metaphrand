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
    process.stderr.write(`[fake] recv #${idx}: ${text}\n`);
    // First turn replies SLOWLY, second quickly: if anything but the queue were
    // ordering us, replies would come back out of order.
    const delay = idx === 1 ? 200 : 10;
    setTimeout(() => {
      const out = {
        type: "result",
        subtype: "success",
        is_error: false,
        result: "echo:" + text,
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
