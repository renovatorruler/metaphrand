/* Prove the gate on MY OWN handwritten narration: the markered originals (which
   I shipped to audio) vs. the cleaned versions. The gate is the judge. */

let check = (label, text) =>
  switch Craft.gateAction(text) {
  | Ok() => Js.log("  PASS  " ++ label)
  | Error(vs) =>
    Js.log("  FAIL  " ++ label)
    vs->Belt.Array.forEach(v => Js.log("          - " ++ Craft.show(v)))
  }

let () = {
  Js.log("--- my markered originals (what I actually shipped) ---")
  check("establisher", "Below: dark forest, an inlet gone copper, a snow mountain pink at the top.")
  check("plane", "A turboprop airliner sails alone through a sky going gold. High, smooth, unhurried.")
  check("jets", "Then — out the left window — a shape slides into frame. Holds there. Unbothered.")
  check("closer", "The plane sails on, smooth, golden. He's easy, a man enjoying a flight.")

  Js.log("--- the cleaned versions ---")
  check("establisher", "Below are dark forest, an inlet the color of copper, and a snow mountain pink at the top.")
  check("plane", "A twin-engine Bombardier Q400, no airline markings, flies alone through a sky turning gold. High and steady.")
  check("jets", "Then a shape slides into view outside the left window and stays there.")
  check("closer", "The plane flies on. He's easy, a man enjoying a flight.")
}
