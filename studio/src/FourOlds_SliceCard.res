/* THE COOKOUT (a09) — the vertical-slice scene card, gated before a word of
   prose exists (docs/08 Layer D). The lighthouse of the satirical rework.
   Run: node src/FourOlds_SliceCard.res.mjs */

let card: DramaCards.sceneCard = {
  scene: "a09_cookout",
  want: "Cricket wants the cookout finished — Lita's flag standing bright and meat actually cooking — while the voices that got him down are still on the radio to hear it happen.",
  wall: "Brandt's crew holds the site in force with orders to remove him; the regime is cutting the feed and reaching for his air; and a grill in one-sixth gravity barely works.",
  cost: "Dragged off camera: the flags come down on schedule, the men who fell getting him here bought nothing, and the country rolls over and goes back to sleep.",
  clock: "His air is arithmetic now, the feed can die mid-frame, and the crew's orders harden the moment Earth stops watching.",
  truthIn: "The state's crew owns the site and the orders; the cookout is one old man's absurdity, about to be tidied away.",
  truthOut: "The crew cannot execute; the absurdity has become the authority — a lit grill outranks the orders, and the planet saw it happen.",
  value: "the Fourth — what the country is allowed to love",
  chargeIn: Minus, /* criminalized, being erased on schedule */
  chargeOut: Plus, /* alive again in every chest, if not on paper */
  audienceDelta: "The audience learns the regime will let an old man die on camera rather than lose the frame — and that Brandt's men are persuadable humans, not apparatus. Suspense, not twist: the air-cut order is SHOWN being given, and the margin stays visible.",
  forward: "The state is beaten on its own broadcast — what did it cost the man, and what does the country do with it now?",
}

let main = () => {
  DramaGate.failed := false
  DramaGate.checkCard(card)
  if DramaGate.failed.contents {
    Js.log("CARD: FAIL")
  } else {
    Js.log("CARD: PASS — " ++ card.scene ++ " may be written")
  }
}
main()
