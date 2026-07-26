/* THE FOUR OLDS - the dangerous spine (v2, 2026-07-15), through DramaGate.
   Ground truth first (revision diffs against THIS, never against a draft);
   then the causal beat graph with escalation telemetry. The Sky King law
   holds: personal grief submerged, collective optimism visible, the why
   never spoken (docs at memory/four-olds-sky-king-optimism-split). */

let spine: DramaCards.spine = {
  story: "FOUR OLDS - the dangerous spine (v2)",
  truth: {
    premise: {
      x: "Faith kept fifty years past its object",
      leadsTo: "leads to",
      y: "one fatal act of keeping that hands a country back its nerve",
    },
    argument: {
      claim: "A country is its promises - erase the last one and the men who kept it will die to prove it still counts.",
      antithesis: "Retiring old symbols is mercy - a grown country puts away the toys of empire before the toys cost more lives; four old men dying for a barbecue is the sickness, not the cure.",
    },
    designingPrinciple: "A last stand told as a cookout: the confrontation with the state is fought, and won, with the most harmless act in the national repertoire.",
    lighthouse: "The removal crew, ordered to drag one old man off the Moon, stands in a half circle around a lit grill. Cricket holds out a spatula: burgers in one-sixth gravity take some watching. Brandt looks at the man, at the bright flag, at the camera light - and his hand will not close. On Earth the regime is screaming to cut the feed, and a hundred flags are already coming out of closets.",
    authorialStake: "Sincerity without irony: the flag is allowed to mean something, and the movie risks being laughed at for meaning it.",
    contestedObject: {
      object_: "The flags on the Moon, on camera, on the Fourth - the state must be seen taking them down; the four must be seen standing one up bright.",
      whyBothCannotHave: "One site, one broadcast, one day: the same shot cannot show the flags erased and the flag renewed. Whoever owns that frame owns what the country believes about itself.",
    },
    opponentPlan: [
      "Win the presidency on retiring America's imperial self-image",
      "Criminalize the Fourth - the grill, the fireworks, the flag - as sedition",
      "Contract the Frontier/ESA retrieval to bring the Moon flags down",
      "Broadcast the removal globally as the healing of the old world",
      "Fold the triumph into the re-election and the permanent settlement",
    ],
  },
  opening: {
    id: "a01_mandate",
    summary: "President Marwani criminalizes the Fourth and mandates the Moon-flag removal; the one official who flinches is made an example of.",
    povWant: "Marwani wants the removal framed as healing before the world's cameras",
    obstacle: "the heartland's rage, which his framing must swallow whole",
    fortune: -1,
    stakes: 3,
    question: "Is there anyone left who will not kneel?",
  },
  beats: [
    {
      id: "a02_kneel",
      edge: But, /* in spite of the ban, they light a grill in the open */
      cause: Protagonist,
      summary: "The four defy the ban with a grill in the open and lose everything on camera: arrest, the farm seized, Danny watching.",
      povWant: "The four want one Fourth kept in the open, in daylight, on principle",
      obstacle: "the ban is federal now, and the state makes examples",
      fortune: -3,
      stakes: 4,
      antagonistAction: Some("arrest on camera; the Dawes farm seized as an example"),
      question: "What is left for men with nothing left to take?",
    },
    {
      id: "a03_go_or_die",
      edge: Therefore, /* because nothing is left, the real want surfaces */
      cause: Protagonist,
      summary: "Cricket names the want they were all cheated of: go. Before the flags come down. One-way if it has to be.",
      povWant: "Cricket wants the flight itself - the thing denied fifty years, not a gesture about it",
      obstacle: "it is illegal, one-way, and they are four old men the state is already watching",
      fortune: -2,
      stakes: 6,
      antagonistAction: None,
      question: "How do four watched old men reach the Moon at all?",
    },
    {
      id: "a04_theft",
      edge: Therefore, /* because no one will carry them, they take it */
      cause: Protagonist,
      summary: "The Sky King theft: they take the vehicle they were only ever cleared to service and launch through a closing net, live on every screen.",
      povWant: "Take the ship they serviced for decades and get it off the pad",
      obstacle: "lockdown, a federal warrant mid-countdown, and bodies that barely make the climb",
      fortune: 1,
      stakes: 7,
      antagonistAction: Some("the pads locked down; the warrant issued mid-countdown"),
      question: "Can a stolen ship and four old men survive the state that wants it back?",
    },
    {
      id: "a05_state_strikes",
      edge: But, /* in spite of being off the planet, the state reaches them */
      cause: Antagonist,
      summary: "The regime tries to kill the flight: remote abort, support cut, the four branded terrorists. They survive it wounded, and the one-way turns certain.",
      povWant: "Keep the wounded ship alive and pointed at the Moon",
      obstacle: "a state actively trying to end the flight, and damage that cannot be undone",
      fortune: -3,
      stakes: 8,
      antagonistAction: Some("remote-abort attempt, support systems cut, terrorist designation"),
      question: "Can they make it on what the strike left them?",
    },
    {
      id: "a06_people_crack",
      edge: But, /* in spite of the crackdown, the signal spreads */
      cause: ThirdParty,
      summary: "To justify killing grandfathers the regime tightens the screws on Earth - and Tito's generation starts smuggling the feed out at real risk.",
      povWant: "Tito wants the feed alive and the old men seen, whatever it costs him now",
      obstacle: "censorship, arrests of the cheerers, the full machinery aimed at the crowd",
      fortune: -2,
      stakes: 9,
      antagonistAction: Some("the feed censored; cheerers jailed; the crowd pressed down"),
      question: "Will the country stand up before the four burn?",
    },
    {
      id: "a07_the_cost",
      edge: Therefore, /* the strike's damage takes its price */
      cause: Antagonist,
      summary: "The abort damage claims the burn: the crew starts dying to get one man down. It comes to Cricket - alone because the others fell getting him there.",
      povWant: "Get one of us to the surface - whoever the ship can still carry",
      obstacle: "the wrecked margins: air, fuel, and burns that no longer close for four",
      fortune: -5,
      stakes: 10,
      antagonistAction: Some("the sabotage arithmetic collects its dead"),
      question: "Does Cricket land alone or die alone?",
    },
    {
      id: "a08_arrival",
      edge: But, /* in spite of the loss, he lands - into the enemy's hands */
      cause: Protagonist,
      summary: "Contact light. Cricket walks to the flags and finds the removal crew already there, armed with orders: Where did you come from?",
      povWant: "Cricket wants the last hundred meters: the flags, before they come down",
      obstacle: "Brandt's crew, present in force, ordered to stop him and finish the removal",
      fortune: -1,
      stakes: 10,
      antagonistAction: Some("the removal crew ordered to take him and pull the flags"),
      question: "They have force and orders; he has a grill - who wins the frame?",
    },
    {
      id: "a09_cookout",
      edge: But, /* in spite of the orders, he lights the grill */
      cause: Protagonist,
      summary: "He plants Lita's bright flag and lights the grill; the crew ordered to drag him off falters, the regime cuts the feed and orders his air cut - and a pressed-down nation erupts anyway.",
      povWant: "Do the most American thing there is, in front of the men sent to erase it",
      obstacle: "a crew with orders and force, a regime killing the feed and reaching for his air",
      fortune: 3,
      stakes: 10,
      antagonistAction: Some("the feed cut, the air-cut order given, the crew commanded to drag him off"),
      question: "The state is beaten on its own camera - at what price to the man?",
    },
    {
      id: "a10_alone",
      edge: Therefore, /* the price was always the going */
      cause: Protagonist,
      summary: "Cricket alone: crew on the radio, flag bright, grill lit, the planet on its feet. The feed holds on the cookout; the end is not shown.",
      povWant: "Cricket wants nothing anymore - the appointment is kept, the flag stands",
      obstacle: "only the air, running out softly, off camera, never mentioned",
      fortune: 4,
      stakes: 10,
      antagonistAction: None,
      question: "What was the why he never said?",
    },
  ],
  climaxId: "a09_cookout",
}
