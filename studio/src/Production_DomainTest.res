/* Pure synthetic tests for the generic production authority domain. */

let fail = message => {
  Js.Console.error("FAIL - " ++ message)
  assert(false)
}

let check = (condition, message) =>
  if !condition {
    fail(message)
  }

let q = value => Js.Json.stringify(Js.Json.string(value))

@scope("Reflect") external deleteProperty: ('a, string) => bool = "deleteProperty"

let jsonObject = json => json->Js.Json.decodeObject->Belt.Option.getExn
let jsonArray = json => json->Js.Json.decodeArray->Belt.Option.getExn
let jsonField = (row, key) => Js.Dict.get(row, key)->Belt.Option.getExn
let jsonString = (row, key) => jsonField(row, key)->Js.Json.decodeString->Belt.Option.getExn
let jsonStrings = (row, key) =>
  jsonField(row, key)
  ->jsonArray
  ->Belt.Array.map(json => json->Js.Json.decodeString->Belt.Option.getExn)

let ledgerById = (root, decisionId) =>
  jsonField(root, "decisionLedgers")
  ->jsonArray
  ->Belt.Array.getBy(json => jsonString(jsonObject(json), "decisionId") == decisionId)
  ->Belt.Option.getExn
  ->jsonObject

let eventBySequence = (ledger, sequence) =>
  jsonField(ledger, "events")
  ->jsonArray
  ->Belt.Array.getBy(json => {
    let row = jsonObject(json)
    jsonField(row, "sequence")->Js.Json.decodeNumber->Belt.Option.getExn ==
      Belt.Int.toFloat(sequence)
  })
  ->Belt.Option.getExn

let refreshOneEventId = (ledger, eventJson) => {
  let event = jsonObject(eventJson)
  let eventId = Production_Domain.deriveDecisionEventIdJson(
    ~decisionId=jsonString(ledger, "decisionId"),
    ~scope=jsonString(ledger, "scope"),
    ~dependencies=jsonStrings(ledger, "dependencies"),
    eventJson,
  )
  Js.Dict.set(event, "eventId", Js.Json.string(eventId))
}

let expectDomainError = (label, expectedText, run) => {
  let message = try {
    run()
    None
  } catch {
  | Production_Domain.DomainError(message) => Some(message)
  | _ => fail(label ++ ": raised an unexpected exception")
  }
  switch message {
  | None => fail(label ++ ": expected DomainError")
  | Some(actual) if !Js.String2.includes(actual, expectedText) =>
    fail(label ++ ": expected error containing '" ++ expectedText ++ "', got '" ++ actual ++ "'")
  | Some(_) => ()
  }
}

let packetWith = (~ledgers: string, ~decisionIds: string): string =>
  `{
  "schema":"production-packet/v2",
  "packetId":"PKT-SYNTHETIC",
  "revision":1,
  "decisionLedgers":${ledgers},
  "principals":[
    {"id":"PR-AUTHORIZER","roles":["authorizer"],"publicKeyPem":${q(
      Production_TestFixtures.testPublicKeyPem,
    )},"decisionIds":${decisionIds}},
    {"id":"PR-REVIEWER","roles":["reviewer"],"publicKeyPem":${q(
      Production_TestFixtures.testPublicKeyPem,
    )},"decisionIds":${decisionIds}},
    {"id":"PR-PRODUCER","roles":["producer"],"publicKeyPem":${q(
      Production_TestFixtures.testPublicKeyPem,
    )},"decisionIds":${decisionIds}},
    {"id":"PR-INSPECTOR","roles":["inspector"],"publicKeyPem":${q(
      Production_TestFixtures.testPublicKeyPem,
    )},"decisionIds":${decisionIds}}
  ],
  "entities":[
    {
      "id":"E-CHILD","label":"Synthetic child","kind":"character","decisionIds":${decisionIds},
      "states":[
        {"id":"plain","label":"Plain","tags":["before"],"dimensions":{"width":2,"height":4,"depth":1.5,"unit":"in"}},
        {"id":"dressed","label":"Dressed","tags":["after"],"dimensions":{"width":2.1,"height":4,"depth":1.6,"unit":"in"},"locationEntityId":"E-ROOM"}
      ]
    },
    {
      "id":"E-DRESSER","label":"Synthetic dresser","kind":"set_object","decisionIds":${decisionIds},
      "states":[
        {"id":"installed","label":"Installed","tags":["anchor"],"dimensions":{"width":40,"height":44,"depth":20,"unit":"in"},"locationEntityId":"E-ROOM"}
      ]
    },
    {
      "id":"E-ROOM","label":"Synthetic room","kind":"location","decisionIds":${decisionIds},
      "states":[
        {"id":"day","label":"Day","tags":["interior"],"dimensions":{"width":180,"height":96,"depth":144,"unit":"in"}}
      ]
    }
  ],
  "assets":[
    {
      "id":"A-CHAR","label":"Character reference","kind":"reference",
      "status":"approved","path":"fixtures/character.json",
      "contentSha256":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      "entityIds":["E-CHILD"],"referenceAssetIds":[],"decisionIds":${decisionIds}
    },
    {
      "id":"A-SET","label":"Set reference","kind":"reference",
      "status":"approved","path":"fixtures/set.json",
      "contentSha256":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
      "entityIds":["E-DRESSER","E-ROOM"],"referenceAssetIds":[],"decisionIds":${decisionIds}
    }
  ],
  "targets":[
    {
      "id":"T-1","purpose":"Prove typed authority reconstruction",
      "principalAction":"Child peeks from behind dresser",
      "operation":"synthetic_image",
      "declaredActionCount":1,
      "declaredContinuousSeconds":4,
      "entityIds":["E-CHILD","E-DRESSER","E-ROOM"],
      "assetIds":["A-CHAR","A-SET"],
      "requirementIds":["R-CONT","R-PRES","R-FORB","R-SCALE","R-GEO","R-CAM","R-FRAME","R-COMPLEX","R-REF"],
      "dependsOnTargetIds":[],"decisionIds":${decisionIds}
    }
  ],
  "requirements":[
    {
      "id":"R-CONT","targetId":"T-1","scope":"continuity.costume",
      "validator":"deterministic","decisionIds":${decisionIds},"kind":"continuity",
      "spec":{"entityId":"E-CHILD","beforeStateId":"plain","afterStateId":"dressed"}
    },
    {
      "id":"R-PRES","targetId":"T-1","scope":"presence.child",
      "validator":"semantic_inspector","decisionIds":${decisionIds},"kind":"presence",
      "spec":{"entityId":"E-CHILD","stateId":"dressed","minimum":1,"maximum":1}
    },
    {
      "id":"R-FORB","targetId":"T-1","scope":"forbidden.pre-gift-state",
      "validator":"semantic_inspector","decisionIds":${decisionIds},"kind":"forbidden",
      "spec":{"entityId":"E-CHILD","stateId":"plain"}
    },
    {
      "id":"R-SCALE","targetId":"T-1","scope":"scale.child-to-dresser",
      "validator":"deterministic","decisionIds":${decisionIds},"kind":"relative_scale",
      "spec":{"subjectEntityId":"E-CHILD","subjectStateId":"dressed","referenceEntityId":"E-DRESSER","referenceStateId":"installed","minRatio":0.08,"maxRatio":0.12}
    },
    {
      "id":"R-GEO","targetId":"T-1","scope":"geography.concealment",
      "validator":"semantic_inspector","decisionIds":${decisionIds},"kind":"geography",
      "spec":{"subjectEntityId":"E-CHILD","referenceEntityId":"E-DRESSER","relation":"behind"}
    },
    {
      "id":"R-CAM","targetId":"T-1","scope":"camera.approach-side",
      "validator":"human_only","decisionIds":${decisionIds},"kind":"camera_side",
      "spec":{"side":"right","anchorEntityId":"E-DRESSER","occluderEntityId":"E-DRESSER"}
    },
    {
      "id":"R-FRAME","targetId":"T-1","scope":"framing.establishing",
      "validator":"semantic_inspector","decisionIds":${decisionIds},"kind":"framing",
      "spec":{"shotSize":"wide","requiredEntityIds":["E-CHILD","E-DRESSER"],"fullyVisible":false}
    },
    {
      "id":"R-COMPLEX","targetId":"T-1","scope":"complexity.single-action",
      "validator":"deterministic","decisionIds":${decisionIds},"kind":"complexity",
      "spec":{"maxPrincipalActions":1,"maxVisibleEntities":3,"maxContinuousSeconds":4.5}
    },
    {
      "id":"R-REF","targetId":"T-1","scope":"references.locked",
      "validator":"deterministic","decisionIds":${decisionIds},"kind":"references",
      "spec":{"assetIds":["A-CHAR","A-SET"],"exact":true}
    }
  ],
  "policies":[
    {"id":"P-ATTEMPTS","decisionIds":${decisionIds},"kind":"attempts","spec":{"maxPerTarget":2}},
    {"id":"P-REVIEW","decisionIds":${decisionIds},"kind":"review","spec":{"batchSize":3,"requireHumanApproval":true}},
    {"id":"P-COMPLEX","decisionIds":${decisionIds},"kind":"complexity","spec":{"maxPrincipalActions":1,"maxVisibleEntities":3,"maxContinuousSeconds":5}},
    {"id":"P-EXECUTION","decisionIds":${decisionIds},"kind":"execution","spec":{"requiresExplicitAuthorization":true}}
  ]
}`->Production_TestFixtures.bindApprovals

let baseLedgers = `[
  {
    "decisionId":"D-FOUND","scope":"authority.foundation","dependencies":[],
    "events":[
      {"eventId":"EV-FOUND-PROPOSE","sequence":1,"kind":"propose","statement":"Foundation is locked"},
      {"eventId":"EV-FOUND-APPROVE","sequence":2,"kind":"approve","note":"Human approval"}
    ]
  },
  {
    "decisionId":"D-SCALE","scope":"scale.characters","dependencies":["D-FOUND"],
    "events":[
      {"eventId":"EV-SCALE-PROPOSE","sequence":3,"kind":"propose","statement":"Use explicit entity states for scale"},
      {"eventId":"EV-SCALE-APPROVE","sequence":4,"kind":"approve"}
    ]
  }
]`

let basePacket = () => packetWith(~ledgers=baseLedgers, ~decisionIds=`["D-FOUND","D-SCALE"]`)

let baseReconstructionTest = () => {
  let context = Production_Domain.reconstruct(basePacket())
  check(context.packet.packetId == "PKT-SYNTHETIC", "packet id must decode")
  check(context.packet.schema == "production-packet/v2", "packet schema v2 must be required")
  check(
    context.packet.decisionHistory.eventCount == 4,
    "packet decision-history anchor must preserve the exact global event count",
  )
  let anchoredScaleLedger: Production_Domain.decisionLedger =
    context.packet.decisionLedgers
    ->Belt.Array.getBy(ledger => ledger.decisionId == "D-SCALE")
    ->Belt.Option.getExn
  check(
    context.packet.decisionHistory.headEventId ==
      Some(Belt.Array.getExn(anchoredScaleLedger.events, 1).eventId),
    "packet decision-history anchor must preserve the exact global head event",
  )
  check(Belt.Array.length(context.packet.requirements) == 9, "all typed requirements must decode")
  check(Belt.Array.length(context.packet.policies) == 4, "all typed policies must decode")
  check(
    context.effectiveDecisionIds == ["D-FOUND", "D-SCALE"],
    "approved dependency chain must be effective in stable id order",
  )
  check(Belt.Array.length(context.conflicts) == 0, "base packet must have no authority conflict")
  check(Belt.Array.length(context.blockers) == 0, "base packet must have no authority blocker")
  let target = Belt.Array.getExn(context.packet.targets, 0)
  check(target.operation == "synthetic_image", "generic provider operation must survive decoding")
  check(target.declaredActionCount == 1, "declared action count must survive decoding")
  check(
    target.declaredContinuousSeconds == 4.0,
    "declared continuous duration must survive decoding",
  )
}

let canonicalHashTest = () => {
  let left = `{"z":[3,{"b":true,"a":null}],"a":"same"}`
  let right = ` {
    "a": "same",
    "z": [3, {"a": null, "b": true}]
  } `
  check(
    Production_Domain.canonicalHashJson(left) == Production_Domain.canonicalHashJson(right),
    "canonical hash must ignore whitespace and object key order",
  )
  let raw = basePacket()
  let pretty = Js.Json.stringifyWithSpace(Js.Json.parseExn(raw), 2)
  check(
    Production_Domain.reconstruct(raw).canonicalHash ==
      Production_Domain.reconstruct(pretty).canonicalHash,
    "packet hash must be stable across serialization whitespace",
  )
}

let decisionLedgerIntegrityTest = () => {
  let raw = basePacket()
  let context = Production_Domain.reconstruct(raw)
  let found =
    context.packet.decisionLedgers
    ->Belt.Array.getBy(ledger => ledger.decisionId == "D-FOUND")
    ->Belt.Option.getExn
  let scale =
    context.packet.decisionLedgers
    ->Belt.Array.getBy(ledger => ledger.decisionId == "D-SCALE")
    ->Belt.Option.getExn
  let foundPropose = Belt.Array.getExn(found.events, 0)
  let foundApprove = Belt.Array.getExn(found.events, 1)
  let scalePropose = Belt.Array.getExn(scale.events, 0)
  check(
    Js.String2.startsWith(foundPropose.eventId, "DEV-") && foundPropose.previousEventId == None,
    "the first decision event must be a content-derived chain root",
  )
  check(
    foundApprove.previousEventId == Some(foundPropose.eventId),
    "events in one decision must chain to their predecessor",
  )
  check(
    scalePropose.previousEventId == Some(foundApprove.eventId),
    "the decision chain must continue across ledger boundaries",
  )

  expectDomainError("event payload tamper", "canonical content hash", () =>
    Production_Domain.reconstruct(
      Js.String2.replace(raw, "Foundation is locked", "Foundation was silently changed"),
    )->ignore
  )
  expectDomainError("event id substitution", "canonical content hash", () =>
    Production_Domain.reconstruct(
      Js.String2.replace(
        raw,
        foundPropose.eventId,
        "DEV-0000000000000000000000000000000000000000000000000000000000000000",
      ),
    )->ignore
  )
  expectDomainError("decision scope tamper", "canonical content hash", () =>
    Production_Domain.reconstruct(
      Js.String2.replace(raw, "authority.foundation", "authority.changed"),
    )->ignore
  )
  expectDomainError("decision dependency tamper", "canonical content hash", () =>
    Production_Domain.reconstruct(
      Js.String2.replace(raw, `"dependencies":["D-FOUND"]`, `"dependencies":[]`),
    )->ignore
  )

  let wrongLinkJson = Js.Json.parseExn(raw)
  let wrongLinkRoot = jsonObject(wrongLinkJson)
  let foundJson = ledgerById(wrongLinkRoot, "D-FOUND")
  let scaleJson = ledgerById(wrongLinkRoot, "D-SCALE")
  let wrongLinkEventJson = eventBySequence(scaleJson, 3)
  let wrongLinkEvent = jsonObject(wrongLinkEventJson)
  let firstEventId = jsonString(jsonObject(eventBySequence(foundJson, 1)), "eventId")
  Js.Dict.set(wrongLinkEvent, "previousEventId", Js.Json.string(firstEventId))
  refreshOneEventId(scaleJson, wrongLinkEventJson)
  expectDomainError("predecessor substitution", "does not chain to the preceding event", () =>
    Production_Domain.reconstruct(Js.Json.stringify(wrongLinkJson))->ignore
  )

  let reorderedJson = Js.Json.parseExn(raw)
  let reorderedRoot = jsonObject(reorderedJson)
  let reorderedFound = ledgerById(reorderedRoot, "D-FOUND")
  let reorderedEvents = jsonField(reorderedFound, "events")->jsonArray
  Js.Dict.set(
    reorderedFound,
    "events",
    Js.Json.array([Belt.Array.getExn(reorderedEvents, 1), Belt.Array.getExn(reorderedEvents, 0)]),
  )
  expectDomainError("stored event order tamper", "strictly increasing sequence order", () =>
    Production_Domain.reconstruct(Js.Json.stringify(reorderedJson))->ignore
  )

  let deletedJson = Js.Json.parseExn(raw)
  let deletedRoot = jsonObject(deletedJson)
  let deletedFound = ledgerById(deletedRoot, "D-FOUND")
  let deletedEvents = jsonField(deletedFound, "events")->jsonArray
  Js.Dict.set(deletedFound, "events", Js.Json.array([Belt.Array.getExn(deletedEvents, 0)]))
  expectDomainError("deleted middle event", "sequences must be contiguous from 1", () =>
    Production_Domain.reconstruct(
      Production_TestFixtures.sealDecisionEvents(Js.Json.stringify(deletedJson)),
    )->ignore
  )

  /* This is the rollback that a predecessor-only hash chain cannot detect:
     after a restart, every remaining event and link is still canonical. The
     separately sealed packet tip/count must make the missing newest event
     fatal without relying on any prior in-memory context. */
  let deletedTailJson = Js.Json.parseExn(raw)
  let deletedTailRoot = jsonObject(deletedTailJson)
  let deletedTailScale = ledgerById(deletedTailRoot, "D-SCALE")
  let deletedTailEvents = jsonField(deletedTailScale, "events")->jsonArray
  Js.Dict.set(
    deletedTailScale,
    "events",
    Js.Json.array([Belt.Array.getExn(deletedTailEvents, 0)]),
  )
  let rolledBackPacketBytes = Js.Json.stringify(deletedTailJson)
  expectDomainError(
    "newest event deletion on fresh reconstruction",
    "decisionHistory.eventCount does not match",
    () => Production_Domain.reconstruct(rolledBackPacketBytes)->ignore,
  )

  let countTamperJson = Js.Json.parseExn(raw)
  let countTamperRoot = jsonObject(countTamperJson)
  let countTamperAnchor = jsonObject(jsonField(countTamperRoot, "decisionHistory"))
  Js.Dict.set(countTamperAnchor, "eventCount", Js.Json.number(5.0))
  expectDomainError("decision history count tamper", "decisionHistory.eventCount does not match", () =>
    Production_Domain.reconstruct(Js.Json.stringify(countTamperJson))->ignore
  )

  let headTamperJson = Js.Json.parseExn(raw)
  let headTamperRoot = jsonObject(headTamperJson)
  let headTamperAnchor = jsonObject(jsonField(headTamperRoot, "decisionHistory"))
  Js.Dict.set(headTamperAnchor, "headEventId", Js.Json.string(foundPropose.eventId))
  expectDomainError("decision history head tamper", "decisionHistory.headEventId does not match", () =>
    Production_Domain.reconstruct(Js.Json.stringify(headTamperJson))->ignore
  )

  let ledgerOrderJson = Js.Json.parseExn(raw)
  let ledgerOrderRoot = jsonObject(ledgerOrderJson)
  let ledgers = jsonField(ledgerOrderRoot, "decisionLedgers")->jsonArray
  Js.Dict.set(
    ledgerOrderRoot,
    "decisionLedgers",
    Js.Json.array([Belt.Array.getExn(ledgers, 1), Belt.Array.getExn(ledgers, 0)]),
  )
  let reorderedContext = Production_Domain.reconstruct(Js.Json.stringify(ledgerOrderJson))
  check(
    reorderedContext.decisions == context.decisions &&
    reorderedContext.effectiveDecisionIds == context.effectiveDecisionIds &&
    reorderedContext.blockers == context.blockers,
    "materialized decision state must be deterministic independent of ledger container order",
  )
}

let reopenTest = () => {
  let ledgers = `[
    {
      "decisionId":"D-REOPEN","scope":"authority.reopen","dependencies":[],
      "events":[
        {"eventId":"EV-1","sequence":1,"kind":"propose","statement":"Original decision"},
        {"eventId":"EV-2","sequence":2,"kind":"approve"},
        {"eventId":"EV-3","sequence":3,"kind":"reopen","reason":"New evidence"},
        {"eventId":"EV-4","sequence":4,"kind":"approve","note":"Re-approved"}
      ]
    }
  ]`
  let context = Production_Domain.reconstruct(packetWith(~ledgers, ~decisionIds=`["D-REOPEN"]`))
  let decision = Belt.Array.getExn(context.decisions, 0)
  check(
    Production_Domain.decisionStatusName(decision.status) == "approved",
    "reopened decision may be explicitly approved again",
  )
  check(context.effectiveDecisionIds == ["D-REOPEN"], "re-approved decision must be effective")
}

let supersedeTest = () => {
  let ledgers = `[
    {
      "decisionId":"D-OLD","scope":"authority.choice","dependencies":[],
      "events":[
        {"eventId":"EV-1","sequence":1,"kind":"propose","statement":"Old choice"},
        {"eventId":"EV-2","sequence":2,"kind":"approve"},
        {"eventId":"EV-5","sequence":5,"kind":"supersede","supersededBy":"D-NEW","reason":"New choice replaces it"}
      ]
    },
    {
      "decisionId":"D-NEW","scope":"authority.choice","dependencies":[],
      "events":[
        {"eventId":"EV-3","sequence":3,"kind":"propose","statement":"New choice"},
        {"eventId":"EV-4","sequence":4,"kind":"approve"}
      ]
    }
  ]`
  let context = Production_Domain.reconstruct(packetWith(~ledgers, ~decisionIds=`["D-NEW"]`))
  check(
    Belt.Array.length(context.conflicts) == 0,
    "explicit supersession must resolve same-scope conflict",
  )
  check(
    context.effectiveDecisionIds == ["D-NEW"],
    "only replacement decision must remain effective",
  )
  let old =
    context.decisions->Belt.Array.getBy(decision => decision.id == "D-OLD")->Belt.Option.getExn
  check(
    Production_Domain.decisionStatusName(old.status) == "superseded",
    "old decision must reduce to superseded",
  )
}

let conflictTest = () => {
  let ledgers = `[
    {
      "decisionId":"D-A","scope":"authority.conflict","dependencies":[],
      "events":[
        {"eventId":"EV-1","sequence":1,"kind":"propose","statement":"Choice A"},
        {"eventId":"EV-2","sequence":2,"kind":"approve"}
      ]
    },
    {
      "decisionId":"D-B","scope":"authority.conflict","dependencies":[],
      "events":[
        {"eventId":"EV-3","sequence":3,"kind":"propose","statement":"Choice B"},
        {"eventId":"EV-4","sequence":4,"kind":"approve"}
      ]
    }
  ]`
  let context = Production_Domain.reconstruct(packetWith(~ledgers, ~decisionIds=`["D-A","D-B"]`))
  check(Belt.Array.length(context.conflicts) == 1, "same-scope approvals must be detected")
  check(
    Belt.Array.getExn(context.conflicts, 0).decisionIds == ["D-A", "D-B"],
    "conflict ids must be deterministic",
  )
  check(
    Belt.Array.length(context.effectiveDecisionIds) == 0,
    "conflicting decisions cannot be effective",
  )
  check(Belt.Array.length(context.blockers) > 0, "conflict must create a blocker")
}

let strictSchemaTests = () => {
  let raw = basePacket()
  expectDomainError("legacy packet schema", "unsupported schema 'production-packet/v1'", () =>
    Production_Domain.decodePacket(
      Js.String2.replace(raw, "production-packet/v2", "production-packet/v1"),
    )->ignore
  )
  expectDomainError("missing decision history anchor", "packet.decisionHistory is required", () => {
    let json = Js.Json.parseExn(raw)
    let root = jsonObject(json)
    deleteProperty(root, "decisionHistory")->ignore
    Production_Domain.decodePacket(Js.Json.stringify(json))->ignore
  })
  expectDomainError("unknown root field", "unknown field 'unexpected'", () =>
    Production_Domain.decodePacket(
      Js.String2.replace(raw, `"revision":1,`, `"revision":1,"unexpected":true,`),
    )->ignore
  )
  expectDomainError("wrong required type", "packet.revision must be a finite number", () =>
    Production_Domain.decodePacket(
      Js.String2.replace(raw, `"revision":1`, `"revision":"one"`),
    )->ignore
  )
  expectDomainError(
    "nonpositive declared duration",
    "declaredContinuousSeconds must be greater than zero",
    () =>
      Production_Domain.decodePacket(
        Js.String2.replace(raw, `"declaredContinuousSeconds":4`, `"declaredContinuousSeconds":0`),
      )->ignore,
  )
  expectDomainError(
    "explicit scale state required",
    "requirements[3].spec.subjectStateId is required",
    () =>
      Production_Domain.decodePacket(
        Js.String2.replace(raw, `,"subjectStateId":"dressed"`, ``),
      )->ignore,
  )
  expectDomainError("duplicate global event sequence", "duplicate value '2'", () =>
    Production_Domain.decodePacket(
      Production_TestFixtures.sealDecisionEvents(
        Js.String2.replace(raw, `"sequence":3`, `"sequence":2`),
      ),
    )->ignore
  )
  expectDomainError("unknown decision dependency", "unknown id 'D-MISSING'", () =>
    Production_Domain.decodePacket(
      Production_TestFixtures.sealDecisionEvents(
        Js.String2.replace(raw, `"dependencies":["D-FOUND"]`, `"dependencies":["D-MISSING"]`),
      ),
    )->ignore
  )
  let illegalLedgers = `[
    {
      "decisionId":"D-BAD","scope":"authority.bad","dependencies":[],
      "events":[
        {"eventId":"EV-1","sequence":1,"kind":"propose","statement":"Bad transition"},
        {"eventId":"EV-2","sequence":2,"kind":"approve"},
        {"eventId":"EV-3","sequence":3,"kind":"reject","reason":"Cannot reject without reopening"}
      ]
    }
  ]`
  expectDomainError("illegal decision transition", "illegal decision transition", () =>
    Production_Domain.decodePacket(
      packetWith(~ledgers=illegalLedgers, ~decisionIds=`["D-BAD"]`),
    )->ignore
  )
}

baseReconstructionTest()
canonicalHashTest()
decisionLedgerIntegrityTest()
reopenTest()
supersedeTest()
conflictTest()
strictSchemaTests()
Js.log("PASS - Production_Domain")
