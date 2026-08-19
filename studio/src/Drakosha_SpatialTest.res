/* Zero-spend regression tests for the physical-production gate. */

open Cinema_Backends

@module("node:fs") external linkSync: (string, string) => unit = "linkSync"

let fail = message => {
  Js.log("FAIL - " ++ message)
  assert(false)
}

let expectCode = (label, code, evaluation) =>
  if !(evaluation.Drakosha_Spatial.findings->Belt.Array.some(f => f.code == code)) {
    fail(label ++ ": expected finding " ++ code)
  }

let expectSpatialError = (label, run) => {
  let failed = ref(false)
  try {
    run()
  } catch {
  | Drakosha_Spatial.SpatialError(_) => failed := true
  }
  if !failed.contents {
    fail(label ++ ": expected strict input rejection")
  }
}

let expectOutputSafetyError = (label, run) => {
  let failed = ref(false)
  try {
    run()
  } catch {
  | Drakosha_OutputSafety.OutputSafetyError(_) => failed := true
  }
  if !failed.contents {
    fail(label ++ ": expected output-safety rejection")
  }
}

let productionRegression = () => {
  let registry =
    readText(Path("../stories/drakosha/production/physical/physical_registry.v1.json"))
    ->Drakosha_Spatial.decodeRegistry
  let manifest =
    readText(Path("../stories/drakosha/production/physical/ep1_physical_manifest.v1.json"))
    ->Drakosha_Spatial.decodeManifest
  let screenplay = readText(Path("../stories/drakosha/2026-08-04_EP1_den-rozhdeniya_SHOOTING_numbered_bilingual.md"))
  let evaluation = Drakosha_Spatial.evaluate(~registry, ~manifest, ~screenplay)
  if !Drakosha_Spatial.hasBlockers(evaluation) {
    fail("the current unproved shooting script must not pass")
  }
  expectCode("complete coverage is mandatory", "COV_SHOT_MISSING", evaluation)
  expectCode("replacement sock sequence remains explicitly pending", "COV_PENDING", evaluation)
  expectCode("open production queue remains a release gate", "PHY_BACKLOG_OPEN", evaluation)
  let obsoleteCodes = [
    "SRC_HASH_MISMATCH",
    "COV_BLOCK_HASH_MISMATCH",
    "COV_INTERACTION_UNLINKED",
    "DEC_REJECTED",
    "PHY_PATH_WIDTH_FAIL",
    "PHY_VERTICAL_REACH_FAIL",
    "PHY_ARM_REACH_FAIL",
    "PHY_HANDLING_METHOD_FAIL",
    "PHY_LIFT_CAPACITY_FAIL",
    "PHY_PROTECTED_APPROACH_MISSING",
  ]
  evaluation.findings->Belt.Array.forEach(f =>
    if obsoleteCodes->Belt.Array.some(code => code == f.code) {
      fail("the approved hook-and-shoelace replacement must not retain obsolete staging diagnostic " ++ f.code)
    }
  )
}

let passingFixture = () => {
  let screenplay = "### SH001\nTwo children drag a soft bundle down a measured lane."
  let sourceHash = Drakosha_Spatial.sha256(screenplay)
  let blockHash = sourceHash
  let registryRaw = `{
    "schema":"drakosha.physical-registry/v1",
    "units":{"length":"in","mass":"g","time":"s","axes":"x=left-right,y=front-back,z=up"},
    "evidence":[{"id":"EV-M","kind":"physical_measurement","note":"fixture measurements"}],
    "entities":[
      {
        "id":"C-A","label":"Child A","kind":"character",
        "states":[{"id":"standing","evidence":"EV-M","aabb":{"min":[-0.5,-0.3,0],"max":[0.5,0.3,1]},"anchors":{"shoulder.center":{"value":[0,0,0.8]}}}],
        "capabilities":{"drag":{"evidence":"EV-M","states":["standing"],"maxHandHeightLoaded":2.8,"armReachLoaded":0.8,"maxLiftMassG":8,"maxCarryMassG":6,"maxDragMassG":20}}
      },
      {
        "id":"C-B","label":"Child B","kind":"character",
        "states":[{"id":"standing","evidence":"EV-M","aabb":{"min":[-0.5,-0.3,0],"max":[0.5,0.3,1]},"anchors":{"shoulder.center":{"value":[0,0,0.8]}}}],
        "capabilities":{"drag":{"evidence":"EV-M","states":["standing"],"maxHandHeightLoaded":2.8,"armReachLoaded":0.8,"maxLiftMassG":8,"maxCarryMassG":6,"maxDragMassG":20}}
      },
      {
        "id":"O-BUNDLE","label":"bundle","kind":"object",
        "states":[{"id":"compressed","evidence":"EV-M","aabb":{"min":[-0.5,-0.4,0],"max":[0.5,0.4,0.6]},"grips":{"left":{"value":[-0.45,0,0.3]},"right":{"value":[0.45,0,0.3]}},"allowedOrientations":["xyz"]}],
        "massG":{"value":10,"evidence":"EV-M"},
        "handlingMethods":[{"kind":"two_person_drag","states":["compressed"]}]
      },
      {
        "id":"SET-LANE","label":"protected lane","kind":"set",
        "states":[{"id":"clear","evidence":"EV-M","visibilityRisk":"none","aabb":{"min":[-2,-4,0],"max":[2,4,4]},"affordances":["protected_approach"]}]
      }
    ]
  }`
  let manifestRaw = `{
    "schema":"drakosha.physical-manifest/v1",
    "profile":"shooting_release",
    "source":{"path":"fixture.md","sha256":"${sourceHash}","expectedShotCount":1},
    "physicalBacklog":{"path":"fixture-backlog.json","sha256":"unused-by-pure-evaluator","openItemIds":[]},
    "output":{"reportPath":"fixture-report.md","proofDir":"proofs","indexPath":"fixture-index.json"},
    "decisions":[{"id":"DEC-OK","status":"author_approved"}],
    "coverage":[{"shotId":"SH001","blockSha256":"${blockHash}","classification":"physical","interactionIds":["I-DRAG"]}],
    "interactions":[{
      "id":"I-DRAG","shotIds":["SH001"],"decisionRefs":["DEC-OK"],"criticality":"blocking","type":"move_object",
      "actors":[
        {"entity":"C-A","state":"standing","capability":"drag","grip":"left","stance":[-1.01,0,0],"stanceEvidence":"EV-M","shoulderAnchor":"shoulder.center"},
        {"entity":"C-B","state":"standing","capability":"drag","grip":"right","stance":[1.01,0,0],"stanceEvidence":"EV-M","shoulderAnchor":"shoulder.center"}
      ],
      "object":{"entity":"O-BUNDLE","state":"compressed"},
      "path":{"entity":"SET-LANE","state":"clear"},
      "orientation":"xyz",
      "method":{"kind":"two_person_drag"}
    }]
  }`
  let registry = Drakosha_Spatial.decodeRegistry(registryRaw)
  let manifest = Drakosha_Spatial.decodeManifest(manifestRaw)
  let evaluation = Drakosha_Spatial.evaluate(~registry, ~manifest, ~screenplay)
  if Drakosha_Spatial.hasBlockers(evaluation) {
    evaluation.findings->Belt.Array.forEach(f => Js.log(f.code ++ ": " ++ f.detail))
    fail("fully measured drag fixture with no concealment requirement should pass")
  }

  let taggedProtectionRegistry = registryRaw
    ->Js.String2.replace(
      `"visibilityRisk":"none","aabb":{"min":[-2,-4,0],"max":[2,4,4]}`,
      `"visibilityRisk":"exposed_to_giants","aabb":{"min":[-2,-4,0],"max":[2,4,4]}`,
    )
  let protectionEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(taggedProtectionRegistry),
    ~manifest,
    ~screenplay,
  )
  expectCode(
    "a protected_approach tag cannot substitute for measured route and cover geometry",
    "PHY_PROTECTED_APPROACH_UNMODELED",
    protectionEvaluation,
  )

  let unclassifiedPathRegistry = registryRaw
    ->Js.String2.replace(`,"visibilityRisk":"none"`, ``)
  let unclassifiedPathEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(unclassifiedPathRegistry),
    ~manifest,
    ~screenplay,
  )
  expectCode(
    "an omitted path visibility classification cannot default to safe",
    "REG_VISIBILITY_RISK_UNCLASSIFIED",
    unclassifiedPathEvaluation,
  )

  let narrowRegistryRaw = registryRaw
    ->Js.String2.replace(`"min":[-2,-4,0],"max":[2,4,4]`, `"min":[-1.25,-4,0],"max":[1.25,4,4]`)
  let narrowEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(narrowRegistryRaw),
    ~manifest,
    ~screenplay,
  )
  expectCode(
    "the object and each actor can fit separately while their translated team formation cannot",
    "PHY_FORMATION_PATH_WIDTH_FAIL",
    narrowEvaluation,
  )
  let taggedTurnRegistry = registryRaw
    ->Js.String2.replace(
      `"affordances":["protected_approach"]`,
      `"affordances":["protected_approach","ninety_degree_turn","turn_envelope_measured"]`,
    )
  let taggedTurnEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(taggedTurnRegistry),
    ~manifest,
    ~screenplay,
  )
  expectCode(
    "a turn_envelope_measured tag cannot substitute for a structured swept formation",
    "PHY_TURN_ENVELOPE_UNMODELED",
    taggedTurnEvaluation,
  )

  let floatingSubjectRegistry = registryRaw
    ->Js.String2.replace(
      `"min":[-0.5,-0.4,0],"max":[0.5,0.4,0.6]`,
      `"min":[-0.5,-0.4,0.2],"max":[0.5,0.4,0.8]`,
    )
  let floatingSubjectEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(floatingSubjectRegistry),
    ~manifest,
    ~screenplay,
  )
  expectCode(
    "a dragged subject cannot float above or penetrate the v1 support plane",
    "PHY_SUBJECT_SUPPORT_MISMATCH",
    floatingSubjectEvaluation,
  )
  let floatingPathRegistry = registryRaw
    ->Js.String2.replace(
      `"min":[-2,-4,0],"max":[2,4,4]`,
      `"min":[-2,-4,0.5],"max":[2,4,4.5]`,
    )
  let floatingPathEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(floatingPathRegistry),
    ~manifest,
    ~screenplay,
  )
  expectCode(
    "a clearance envelope cannot float away from the v1 support plane",
    "PHY_PATH_SUPPORT_MISMATCH",
    floatingPathEvaluation,
  )
}

let strictDecoderFixture = () => {
  let failed = ref(false)
  try {
    let _ = Drakosha_Spatial.decodeRegistry(`{
      "schema":"drakosha.physical-registry/v1",
      "units":{"length":"in","mass":"g","time":"s","axes":"x=left-right,y=front-back,z=up"},
      "evidence":[],
      "entities":[{"id":"X","label":"bad","kind":"object","states":[{"id":"s","evidence":"EV-M","aabb":{"min":[0,0,0],"max":[1,1]}}]}]
    }`)
  } catch {
  | Drakosha_Spatial.SpatialError(_) => failed := true
  }
  if !failed.contents {
    fail("missing geometry must raise instead of becoming zero")
  }
}

let orientationContractFixture = () => {
  let point = Drakosha_Spatial.orientPoint(
    {Drakosha_Spatial.x: 2.0, y: 3.0, z: 4.0},
    Drakosha_Spatial.Yxz,
  )
  if point.x != -3.0 || point.y != 2.0 || point.z != 4.0 {
    fail("yxz must be a right-handed +90-degree yaw, not an axis-swap reflection")
  }
  let bounds = Drakosha_Spatial.orientBounds(
    {
      Drakosha_Spatial.min: {Drakosha_Spatial.x: -2.0, y: -3.0, z: 0.0},
      max: {Drakosha_Spatial.x: 4.0, y: 5.0, z: 1.0},
    },
    Drakosha_Spatial.Yxz,
  )
  if bounds.min.x != -5.0 || bounds.max.x != 3.0 || bounds.min.y != -2.0 || bounds.max.y != 4.0 {
    fail("yxz must recompute asymmetric AABB extrema under the signed yaw")
  }
  let entryOffset = {Drakosha_Spatial.x: 0.37, y: -0.22, z: 1.6}
  let finalOffset = Drakosha_Spatial.straightDownFinalOffset(
    ~entryOffset,
    ~subjectBounds={
      Drakosha_Spatial.min: {Drakosha_Spatial.x: -0.5, y: -0.3, z: 0.0},
      max: {Drakosha_Spatial.x: 0.5, y: 0.3, z: 0.4},
    },
    ~volumeBounds={
      Drakosha_Spatial.min: {Drakosha_Spatial.x: -1.0, y: -1.0, z: 0.5},
      max: {Drakosha_Spatial.x: 1.0, y: 1.0, z: 1.5},
    },
    ~clearance=0.1,
  )
  if finalOffset.x != entryOffset.x || finalOffset.y != entryOffset.y {
    fail("straight-down placement must preserve an off-center aperture path instead of teleporting sideways")
  }
}

let placeRegistryRaw = `{
  "schema":"drakosha.physical-registry/v1",
  "units":{"length":"in","mass":"g","time":"s","axes":"x=left-right,y=front-back,z=up"},
  "evidence":[{"id":"EV-M","kind":"physical_measurement","note":"fixture"}],
  "entities":[
    {
      "id":"C-A","label":"Child A","kind":"character",
      "states":[{"id":"standing","evidence":"EV-M","aabb":{"min":[-0.4,-0.3,0],"max":[0.4,0.3,3]},"anchors":{"shoulder.center":{"value":[0,0,1.8]}}}],
      "capabilities":{"lift":{"evidence":"EV-M","states":["standing"],"maxHandHeightLoaded":2.8,"armReachLoaded":1.3,"maxLiftMassG":10,"maxCarryMassG":8,"maxDragMassG":20}}
    },
    {
      "id":"C-B","label":"Child B","kind":"character",
      "states":[{"id":"standing","evidence":"EV-M","aabb":{"min":[-0.4,-0.3,0],"max":[0.4,0.3,3]},"anchors":{"shoulder.center":{"value":[0,0,1.8]}}}],
      "capabilities":{"lift":{"evidence":"EV-M","states":["standing"],"maxHandHeightLoaded":2.8,"armReachLoaded":1.3,"maxLiftMassG":10,"maxCarryMassG":8,"maxDragMassG":20}}
    },
    {
      "id":"O-BOX","label":"small box","kind":"object",
      "states":[{"id":"held","evidence":"EV-M","aabb":{"min":[-0.5,-0.3,0],"max":[0.5,0.3,0.4]},"grips":{"left":{"value":[-0.4,0,0.2]},"right":{"value":[0.4,0,0.2]}},"allowedOrientations":["xyz"]}],
      "massG":{"value":5,"evidence":"EV-M"},
      "handlingMethods":[{"kind":"two_person_lift","states":["held"]}]
    },
    {
      "id":"SET-BIN","label":"measured bin","kind":"set",
      "states":[{
        "id":"open","evidence":"EV-M","visibilityRisk":"none","aabb":{"min":[-2,-1,0],"max":[2,1,2]},
        "anchors":{"rim.top":{"value":[0,-1,1.5]},"floor.front":{"value":[0,-1,0.5]},"support.top":{"value":[0,0,0]}},
        "openings":{"mouth":{"plane":"xy","center":[0,-0.5,1.5],"clearSpanU":2,"clearSpanV":1}},
        "volumes":{"inside":{"aabb":{"min":[-1,-1,0.5],"max":[1,0,1.5]}}},
        "destinations":{"drop":{"barrierAnchor":"rim.top","floorAnchor":"floor.front","supportAnchor":"support.top","opening":"mouth","barrierEdge":"v_min","volume":"inside"}},
        "affordances":["protected_approach"]
      }]
    }
  ]
}`

let placeInteractionJson = (id, sideFile, planFile) => `{
  "id":"${id}","shotIds":["SH001"],"decisionRefs":["DEC-OK"],"criticality":"blocking","type":"place_into",
  "actors":[
    {"entity":"C-A","state":"standing","capability":"lift","grip":"left","stance":[-0.4,-1.61,0],"stanceEvidence":"EV-M","shoulderAnchor":"shoulder.center"},
    {"entity":"C-B","state":"standing","capability":"lift","grip":"right","stance":[0.4,-1.61,0],"stanceEvidence":"EV-M","shoulderAnchor":"shoulder.center"}
  ],
  "object":{"entity":"O-BOX","state":"held"},
  "target":{"entity":"SET-BIN","state":"open","destination":"drop"},
  "orientation":"xyz",
  "method":{"kind":"two_person_lift","clearance":0.1},
  "proof":{"sideFile":"${sideFile}","planFile":"${planFile}"}
}`

let placeManifestRaw = (screenplay, interactions, interactionIds) => `{
  "schema":"drakosha.physical-manifest/v1","profile":"shooting_release",
  "source":{"path":"fixture.md","sha256":"${Drakosha_Spatial.sha256(screenplay)}","expectedShotCount":1},
  "physicalBacklog":{"path":"fixture-backlog.json","sha256":"unused-by-pure-evaluator","openItemIds":[]},
  "output":{"reportPath":"fixture-report.md","proofDir":"proofs","indexPath":"fixture-index.json"},
  "decisions":[{"id":"DEC-OK","status":"author_approved"}],
  "coverage":[{"shotId":"SH001","blockSha256":"${Drakosha_Spatial.sha256(screenplay)}","classification":"physical","interactionIds":[${interactionIds}]}],
  "interactions":[${interactions}]
}`

let passingPlaceProofFixture = () => {
  let screenplay = "### SH001\nTwo children lift a measured box into a measured protected bin."
  let interaction = placeInteractionJson("I-PLACE", "I-PLACE-side.svg", "I-PLACE-plan.svg")
  let manifestRaw = placeManifestRaw(screenplay, interaction, `"I-PLACE"`)
  let registry = Drakosha_Spatial.decodeRegistry(placeRegistryRaw)
  let manifest = Drakosha_Spatial.decodeManifest(manifestRaw)
  let evaluation = Drakosha_Spatial.evaluate(~registry, ~manifest, ~screenplay)
  if Drakosha_Spatial.hasBlockers(evaluation) {
    evaluation.findings->Belt.Array.forEach(f => Js.log(f.code ++ ": " ++ f.detail))
    fail("fully measured place-into fixture should pass")
  }
  if Belt.Array.length(evaluation.artifacts) != 2 {
    fail("passing place-into fixture should emit two distinct proofs")
  }
  evaluation.artifacts->Belt.Array.forEach(artifact => {
    if !Js.String2.includes(artifact.body, "— PASS") {
      fail("a passing proof must say PASS")
    }
    if Js.String2.includes(artifact.body, "— FAIL") || Js.String2.includes(artifact.body, "UNPROVEN/UNREACHABLE") || Js.String2.includes(artifact.body, "NO PROTECTED APPROACH") {
      fail("a passing proof must not contain a hard-coded failure verdict")
    }
    if Js.String2.includes(artifact.body, "behind dresser") || Js.String2.includes(artifact.body, "giants' visible room") {
      fail("generic place-into proofs must not invent dresser-specific topology")
    }
  })

  let exposedTargetRegistry = placeRegistryRaw
    ->Js.String2.replace(
      `"visibilityRisk":"none"`,
      `"visibilityRisk":"exposed_to_giants"`,
    )
  let exposedTargetEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(exposedTargetRegistry),
    ~manifest,
    ~screenplay,
  )
  expectCode(
    "the target state, not a manifest switch, imposes concealment",
    "PHY_PROTECTED_APPROACH_UNMODELED",
    exposedTargetEvaluation,
  )

  let unclassifiedTargetRegistry = placeRegistryRaw
    ->Js.String2.replace(`,"visibilityRisk":"none"`, ``)
  let unclassifiedTargetEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(unclassifiedTargetRegistry),
    ~manifest,
    ~screenplay,
  )
  expectCode(
    "an omitted target visibility classification cannot default to safe",
    "REG_VISIBILITY_RISK_UNCLASSIFIED",
    unclassifiedTargetEvaluation,
  )

  let narrowOpeningRegistry = placeRegistryRaw
    ->Js.String2.replace(`"clearSpanV":1`, `"clearSpanV":0.7`)
  let openingEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(narrowOpeningRegistry),
    ~manifest,
    ~screenplay,
  )
  expectCode(
    "an xy opening must compare object x-by-y rather than x-by-z",
    "PHY_OPENING_FIT_FAIL",
    openingEvaluation,
  )

  let disconnectedBarrierRegistry = placeRegistryRaw
    ->Js.String2.replace(
      `"anchors":{"rim.top":{"value":[0,-1,1.5]},`,
      `"anchors":{"rim.top":{"value":[0,-1,1.5]},"fake.low":{"value":[0,-1,0.5]},`,
    )
    ->Js.String2.replace(
      `"barrierAnchor":"rim.top"`,
      `"barrierAnchor":"fake.low"`,
    )
  let disconnectedBarrierEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(disconnectedBarrierRegistry),
    ~manifest,
    ~screenplay,
  )
  expectCode(
    "a low unrelated anchor cannot be mixed with a remote opening and interior",
    "REG_DESTINATION_BARRIER_DISCONNECTED",
    disconnectedBarrierEvaluation,
  )
  disconnectedBarrierEvaluation.artifacts->Belt.Array.forEach(artifact =>
    if !Js.String2.includes(artifact.body, "— FAIL") || Js.String2.includes(artifact.body, "— PASS") {
      fail("a disconnected destination tuple must never produce a PASS proof")
    }
  )

  let disconnectedOpeningRegistry = placeRegistryRaw
    ->Js.String2.replace(`"center":[0,-0.5,1.5]`, `"center":[0,-0.5,1.4]`)
  let disconnectedOpeningEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(disconnectedOpeningRegistry),
    ~manifest,
    ~screenplay,
  )
  expectCode(
    "an aperture must be positioned on its bound interior face",
    "REG_DESTINATION_OPENING_DISCONNECTED",
    disconnectedOpeningEvaluation,
  )

  let disconnectedFloorRegistry = placeRegistryRaw
    ->Js.String2.replace(`"floor.front":{"value":[0,-1,0.5]}`, `"floor.front":{"value":[0,-0.5,0.5]}`)
  let disconnectedFloorEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(disconnectedFloorRegistry),
    ~manifest,
    ~screenplay,
  )
  expectCode(
    "the bound floor must share the rim's structural section",
    "REG_DESTINATION_FLOOR_DISCONNECTED",
    disconnectedFloorEvaluation,
  )

  let conflictingSupportRegistry = placeRegistryRaw
    ->Js.String2.replace(`"support.top":{"value":[0,0,0]}`, `"support.top":{"value":[0,0,0.75]}`)
  let conflictingSupportEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(conflictingSupportRegistry),
    ~manifest,
    ~screenplay,
  )
  expectCode(
    "the bound support/underbody cannot intersect the drawer interior",
    "REG_DESTINATION_SUPPORT_CONFLICT",
    conflictingSupportEvaluation,
  )

  let tooShallowInteriorRegistry = placeRegistryRaw
    ->Js.String2.replace(
      `"aabb":{"min":[-1,-1,0.5],"max":[1,0,1.5]}`,
      `"aabb":{"min":[-1,-1,1.15],"max":[1,0,1.5]}`,
    )
  let tooShallowEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(tooShallowInteriorRegistry),
    ~manifest,
    ~screenplay,
  )
  expectCode(
    "entry fit does not prove a clearance-preserving final pose",
    "PHY_FINAL_CONTAINMENT_FAIL",
    tooShallowEvaluation,
  )

  let offCenterGripRegistry = placeRegistryRaw
    ->Js.String2.replace(`"left":{"value":[-0.4,0,0.2]}`, `"left":{"value":[-0.4,0,0.35]}`)
    ->Js.String2.replace(`"right":{"value":[0.4,0,0.2]}`, `"right":{"value":[0.4,0,0.35]}`)
  let offCenterEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(offCenterGripRegistry),
    ~manifest,
    ~screenplay,
  )
  if Drakosha_Spatial.hasBlockers(offCenterEvaluation) {
    fail("off-center grip fixture should remain physically valid")
  }
  let sideProof = offCenterEvaluation.artifacts->Belt.Array.getBy(artifact =>
    Js.String2.includes(artifact.body, "SIDE ELEVATION")
  )
  switch sideProof {
  | Some(artifact) =>
    if !Js.String2.includes(artifact.body, "x='535.00' y='434.00'") {
      fail("side proof must draw the subject from its placed bottom/top, not center it on an off-center grip")
    }
  | None => fail("off-center grip fixture should emit a side proof")
  }

  let elevatedTargetRegistry = placeRegistryRaw
    ->Js.String2.replace(
      `"aabb":{"min":[-2,-1,0],"max":[2,1,2]}`,
      `"aabb":{"min":[-2,-1,0.5],"max":[2,1,3.5]}`,
    )
    ->Js.String2.replace(`"support.top":{"value":[0,0,0]}`, `"support.top":{"value":[0,0,0.5]}`)
  let elevatedTargetEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(elevatedTargetRegistry),
    ~manifest,
    ~screenplay,
  )
  if Drakosha_Spatial.hasBlockers(elevatedTargetEvaluation) {
    fail("nonzero target bounds fixture should remain physically valid")
  }
  let elevatedTargetProof = elevatedTargetEvaluation.artifacts->Belt.Array.getBy(artifact =>
    Js.String2.includes(artifact.body, "SIDE ELEVATION")
  )
  switch elevatedTargetProof {
  | Some(artifact) =>
    if !Js.String2.includes(artifact.body, "x='700' y='377.00' width='260' height='114.00'") {
      fail("side proof must draw target min.z/max.z rather than assume its base is z=0")
    }
  | None => fail("nonzero target bounds fixture should emit a side proof")
  }

  let hostileRegistry = placeRegistryRaw
    ->Js.String2.replace(`"label":"measured bin"`, `"label":"</text><script>alert(1)</script>&"`)
    ->Drakosha_Spatial.decodeRegistry
  let hostileEvaluation = Drakosha_Spatial.evaluate(~registry=hostileRegistry, ~manifest, ~screenplay)
  if Drakosha_Spatial.hasBlockers(hostileEvaluation) {
    fail("hostile-label fixture should test escaping without changing physical validity")
  }
  hostileEvaluation.artifacts->Belt.Array.forEach(artifact => {
    if Js.String2.includes(artifact.body, "<script>") || !Js.String2.includes(artifact.body, "&lt;script&gt;") {
      fail("registry labels must remain escaped literal text in generated SVG")
    }
  })
  let hostileMarkdown = Drakosha_Spatial.markdownText("</td><script>x</script>|`[")
  if Js.String2.includes(hostileMarkdown, "<script>") || Js.String2.includes(hostileMarkdown, "|") {
    fail("generated Markdown text must escape raw HTML and table delimiters")
  }
}

let duplicateShotIdFixture = () => {
  let screenplay = "### SH001\nFirst block.\n### SH001\nSecond block."
  let interaction = placeInteractionJson("I-PLACE", "duplicate-side.svg", "duplicate-plan.svg")
  let manifestRaw = placeManifestRaw(screenplay, interaction, `"I-PLACE"`)
  let registry = Drakosha_Spatial.decodeRegistry(placeRegistryRaw)
  let manifest = Drakosha_Spatial.decodeManifest(manifestRaw)
  let evaluation = Drakosha_Spatial.evaluate(~registry, ~manifest, ~screenplay)
  expectCode("duplicate screenplay IDs cannot share coverage", "SRC_SHOT_ID_DUPLICATE", evaluation)
}

let actorCollisionFixture = () => {
  let screenplay = "### SH001\nA character tries to solve reach by standing inside the target."
  let interaction = placeInteractionJson("I-COLLIDE", "collide-side.svg", "collide-plan.svg")
    ->Js.String2.replace(`[-0.4,-1.61,0]`, `[0,0,0]`)
  let manifestRaw = placeManifestRaw(screenplay, interaction, `"I-COLLIDE"`)
  let registry = Drakosha_Spatial.decodeRegistry(placeRegistryRaw)
  let manifest = Drakosha_Spatial.decodeManifest(manifestRaw)
  let evaluation = Drakosha_Spatial.evaluate(~registry, ~manifest, ~screenplay)
  expectCode("reach cannot be faked by placing an actor inside the target", "PHY_ACTOR_TARGET_COLLISION", evaluation)

  let pairInteraction = placeInteractionJson("I-PAIR", "pair-side.svg", "pair-plan.svg")
    ->Js.String2.replace(`[0.4,-1.61,0]`, `[-0.2,-1.61,0]`)
  let pairManifest = placeManifestRaw(screenplay, pairInteraction, `"I-PAIR"`)
    ->Drakosha_Spatial.decodeManifest
  let pairEvaluation = Drakosha_Spatial.evaluate(~registry, ~manifest=pairManifest, ~screenplay)
  expectCode("team members cannot occupy the same body volume", "PHY_ACTOR_ACTOR_COLLISION", pairEvaluation)

  let subjectInteraction = placeInteractionJson("I-SUBJECT", "subject-side.svg", "subject-plan.svg")
    ->Js.String2.replace(`[-0.4,-1.61,0]`, `[-0.4,-1.0,0]`)
  let subjectManifest = placeManifestRaw(screenplay, subjectInteraction, `"I-SUBJECT"`)
    ->Drakosha_Spatial.decodeManifest
  let subjectEvaluation = Drakosha_Spatial.evaluate(~registry, ~manifest=subjectManifest, ~screenplay)
  expectCode("an actor body cannot pass through the handled subject", "PHY_ACTOR_SUBJECT_COLLISION", subjectEvaluation)
}

let strictContractFixtures = () => {
  expectSpatialError("wrong units", () => {
    let _ = Drakosha_Spatial.decodeRegistry(Js.String2.replace(placeRegistryRaw, `"length":"in"`, `"length":"cm"`))
  })
  expectSpatialError("unknown registry handling method", () => {
    let _ = Drakosha_Spatial.decodeRegistry(Js.String2.replace(placeRegistryRaw, `"two_person_lift"`, `"teleport"`))
  })
  expectSpatialError("negative mass", () => {
    let _ = Drakosha_Spatial.decodeRegistry(Js.String2.replace(placeRegistryRaw, `"value":5`, `"value":-5`))
  })
  let screenplay = "### SH001\nMeasured action."
  let interaction = placeInteractionJson("I-PLACE", "same.svg", "same.svg")
  expectSpatialError("proof filenames must be distinct", () => {
    let _ = Drakosha_Spatial.decodeManifest(placeManifestRaw(screenplay, interaction, `"I-PLACE"`))
  })
  let unsafeProof = placeInteractionJson("I-PLACE", "bad](x.svg", "safe-plan.svg")
  expectSpatialError("proof filenames cannot inject Markdown or paths", () => {
    let _ = Drakosha_Spatial.decodeManifest(placeManifestRaw(screenplay, unsafeProof, `"I-PLACE"`))
  })
  let unsafeReportManifest = placeManifestRaw(
    screenplay,
    placeInteractionJson("I-PLACE", "safe-side.svg", "safe-plan.svg"),
    `"I-PLACE"`,
  )->Js.String2.replace(`"reportPath":"fixture-report.md"`, `"reportPath":"bad]report.md"`)
  expectSpatialError("manifest output paths use a Markdown-safe contract", () => {
    let _ = Drakosha_Spatial.decodeManifest(unsafeReportManifest)
  })
  let duplicateActors = placeInteractionJson("I-PLACE", "a-side.svg", "a-plan.svg")
    ->Js.String2.replace(`"entity":"C-B"`, `"entity":"C-A"`)
  expectSpatialError("duplicate actors cannot inflate strength", () => {
    let _ = Drakosha_Spatial.decodeManifest(placeManifestRaw(screenplay, duplicateActors, `"I-PLACE"`))
  })
  let unknownMethod = placeInteractionJson("I-PLACE", "b-side.svg", "b-plan.svg")
    ->Js.String2.replace(`"two_person_lift"`, `"teleport"`)
  expectSpatialError("unknown interaction handling method", () => {
    let _ = Drakosha_Spatial.decodeManifest(placeManifestRaw(screenplay, unknownMethod, `"I-PLACE"`))
  })
  let legacyVisibilitySwitch = placeInteractionJson("I-PLACE", "visibility-side.svg", "visibility-plan.svg")
    ->Js.String2.replace(`"clearance":0.1`, `"clearance":0.1,"requiresProtectedApproach":false`)
  expectSpatialError("an interaction cannot turn registered visibility risk off", () => {
    let _ = Drakosha_Spatial.decodeManifest(
      placeManifestRaw(screenplay, legacyVisibilitySwitch, `"I-PLACE"`),
    )
  })
  let noDecision = placeInteractionJson("I-PLACE", "c-side.svg", "c-plan.svg")
    ->Js.String2.replace(`"decisionRefs":["DEC-OK"]`, `"decisionRefs":[]`)
  expectSpatialError("every interaction must consume an explicit author decision", () => {
    let _ = Drakosha_Spatial.decodeManifest(placeManifestRaw(screenplay, noDecision, `"I-PLACE"`))
  })
  let nonblocking = placeInteractionJson("I-PLACE", "d-side.svg", "d-plan.svg")
    ->Js.String2.replace(`"criticality":"blocking"`, `"criticality":"advisory"`)
  expectSpatialError("release interactions cannot downgrade themselves to advisory", () => {
    let _ = Drakosha_Spatial.decodeManifest(placeManifestRaw(screenplay, nonblocking, `"I-PLACE"`))
  })
  let floatingStance = placeInteractionJson("I-PLACE", "e-side.svg", "e-plan.svg")
    ->Js.String2.replace(`[-0.4,-1.61,0]`, `[-0.4,-1.61,1]`)
  expectSpatialError("schema v1 cannot invent an unregistered elevated support", () => {
    let _ = Drakosha_Spatial.decodeManifest(placeManifestRaw(screenplay, floatingStance, `"I-PLACE"`))
  })
  let floatingActorRegistry = placeRegistryRaw
    ->Js.String2.replace(
      `"min":[-0.4,-0.3,0],"max":[0.4,0.3,3]`,
      `"min":[-0.4,-0.3,0.5],"max":[0.4,0.3,3.5]`,
    )
  let floatingActorEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(floatingActorRegistry),
    ~manifest=Drakosha_Spatial.decodeManifest(
      placeManifestRaw(screenplay, placeInteractionJson("I-PLACE", "g-side.svg", "g-plan.svg"), `"I-PLACE"`),
    ),
    ~screenplay,
  )
  expectCode("actor state bounds cannot float above the v1 support plane", "PHY_ACTOR_SUPPORT_MISMATCH", floatingActorEvaluation)
  let floatingGripRegistry = placeRegistryRaw
    ->Js.String2.replace(`"left":{"value":[-0.4,0,0.2]}`, `"left":{"value":[-0.51,0,0.2]}`)
  let geometryManifest = Drakosha_Spatial.decodeManifest(
    placeManifestRaw(screenplay, placeInteractionJson("I-PLACE", "h-side.svg", "h-plan.svg"), `"I-PLACE"`),
  )
  let mismatchedCapabilityRegistry = placeRegistryRaw
    ->Js.String2.replace(
      `"capabilities":{"lift":{"evidence":"EV-M","states":["standing"]`,
      `"capabilities":{"lift":{"evidence":"EV-M","states":["other"]`,
    )
  let mismatchedCapabilityEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(mismatchedCapabilityRegistry),
    ~manifest=geometryManifest,
    ~screenplay,
  )
  expectCode("a pose cannot borrow another pose's capability", "REG_CAPABILITY_STATE_MISMATCH", mismatchedCapabilityEvaluation)
  let mismatchedHandlingRegistry = placeRegistryRaw
    ->Js.String2.replace(
      `{"kind":"two_person_lift","states":["held"]}`,
      `{"kind":"two_person_lift","states":["other"]}`,
    )
  let mismatchedHandlingEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(mismatchedHandlingRegistry),
    ~manifest=geometryManifest,
    ~screenplay,
  )
  expectCode("handling permission must bind the exact object state", "PHY_HANDLING_METHOD_FAIL", mismatchedHandlingEvaluation)
  let floatingGripEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(floatingGripRegistry),
    ~manifest=geometryManifest,
    ~screenplay,
  )
  expectCode("grips must lie within their owning object state", "REG_POINT_OUT_OF_BOUNDS", floatingGripEvaluation)
  floatingGripEvaluation.artifacts->Belt.Array.forEach(artifact =>
    if !Js.String2.includes(artifact.body, "— FAIL") || Js.String2.includes(artifact.body, "— PASS") {
      fail("a referenced global registry blocker must make every emitted proof FAIL")
    }
  )
  let floatingShoulderRegistry = placeRegistryRaw
    ->Js.String2.replace(`"shoulder.center":{"value":[0,0,1.8]}`, `"shoulder.center":{"value":[9,0,1.8]}`)
  let floatingShoulderEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(floatingShoulderRegistry),
    ~manifest=geometryManifest,
    ~screenplay,
  )
  expectCode("shoulder anchors must lie within their owning actor state", "REG_POINT_OUT_OF_BOUNDS", floatingShoulderEvaluation)
  let floatingBarrierRegistry = placeRegistryRaw
    ->Js.String2.replace(`"rim.top":{"value":[0,-1,1.5]}`, `"rim.top":{"value":[0,-1,9]}`)
  let floatingBarrierEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(floatingBarrierRegistry),
    ~manifest=geometryManifest,
    ~screenplay,
  )
  expectCode("barrier anchors must lie within their owning target state", "REG_POINT_OUT_OF_BOUNDS", floatingBarrierEvaluation)
  let oversizedOpeningRegistry = placeRegistryRaw
    ->Js.String2.replace(`"clearSpanU":2`, `"clearSpanU":20`)
  let oversizedOpeningEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(oversizedOpeningRegistry),
    ~manifest=geometryManifest,
    ~screenplay,
  )
  expectCode("openings must fit inside their owning target state", "REG_OPENING_EXCEEDS_STATE", oversizedOpeningEvaluation)
  let oversizedVolumeRegistry = placeRegistryRaw
    ->Js.String2.replace(
      `"aabb":{"min":[-1,-1,0.5],"max":[1,0,1.5]}`,
      `"aabb":{"min":[-10,-1,0.5],"max":[10,0,1.5]}`,
    )
  let oversizedVolumeEvaluation = Drakosha_Spatial.evaluate(
    ~registry=Drakosha_Spatial.decodeRegistry(oversizedVolumeRegistry),
    ~manifest=geometryManifest,
    ~screenplay,
  )
  expectCode("interior volumes must fit inside their owning target state", "REG_VOLUME_EXCEEDS_STATE", oversizedVolumeEvaluation)
  expectSpatialError("opening planes are a closed contract", () => {
    let _ = Drakosha_Spatial.decodeRegistry(Js.String2.replace(placeRegistryRaw, `"plane":"xy"`, `"plane":"diagonal"`))
  })
  expectSpatialError("handled orientations are a closed contract", () => {
    let badOrientation = placeInteractionJson("I-PLACE", "f-side.svg", "f-plan.svg")
      ->Js.String2.replace(`"orientation":"xyz"`, `"orientation":"best_fit"`)
    let _ = Drakosha_Spatial.decodeManifest(placeManifestRaw(screenplay, badOrientation, `"I-PLACE"`))
  })
  let noneManifest = `{
    "schema":"drakosha.physical-manifest/v1","profile":"shooting_release",
    "source":{"path":"fixture.md","sha256":"${Drakosha_Spatial.sha256(screenplay)}","expectedShotCount":1},
    "physicalBacklog":{"path":"fixture-backlog.json","sha256":"unused","openItemIds":[]},
    "output":{"reportPath":"report.md","proofDir":"proofs","indexPath":"index.json"},
    "decisions":[],
    "coverage":[{"shotId":"SH001","blockSha256":"${Drakosha_Spatial.sha256(screenplay)}","classification":"none","reasonCode":"anything"}],
    "interactions":[]
  }`
  expectSpatialError("free-text none classification cannot bypass physics", () => {
    let _ = Drakosha_Spatial.decodeManifest(noneManifest)
  })
}

let hasDuplicateStringsForTest = rows => {
  let seen = Js.Dict.empty()
  rows->Belt.Array.some(row =>
    if Js.Dict.get(seen, row) == Some(true) {
      true
    } else {
      Js.Dict.set(seen, row, true)
      false
    }
  )
}

let proofCollisionFixture = () => {
  let screenplay = "### SH001\nTwo independently reviewed placements share one shot."
  let first = placeInteractionJson("I-A", "collision-side.svg", "collision-plan.svg")
  let second = placeInteractionJson("I-B", "collision-side.svg", "collision-plan.svg")
  let manifestRaw = placeManifestRaw(screenplay, first ++ "," ++ second, `"I-A","I-B"`)
  let registry = Drakosha_Spatial.decodeRegistry(placeRegistryRaw)
  let manifest = Drakosha_Spatial.decodeManifest(manifestRaw)
  let evaluation = Drakosha_Spatial.evaluate(~registry, ~manifest, ~screenplay)
  expectCode("proof outputs cannot overwrite one another", "PRF_PATH_COLLISION", evaluation)
  let paths = evaluation.artifacts->Belt.Array.map(a => a.relativePath)
  if Belt.Array.length(paths) != 2 || hasDuplicateStringsForTest(paths) {
    fail("colliding proof outputs must be suppressed instead of duplicated")
  }

  let partialSecond = placeInteractionJson("I-B", "collision-side.svg", "unique-plan.svg")
  let partialManifestRaw = placeManifestRaw(screenplay, first ++ "," ++ partialSecond, `"I-A","I-B"`)
  let partialManifest = Drakosha_Spatial.decodeManifest(partialManifestRaw)
  let partialEvaluation = Drakosha_Spatial.evaluate(~registry, ~manifest=partialManifest, ~screenplay)
  expectCode("a partial proof collision must block the whole second proof pair", "PRF_PATH_COLLISION", partialEvaluation)
  let uniquePlan = partialEvaluation.artifacts->Belt.Array.getBy(artifact =>
    Js.String2.endsWith(artifact.relativePath, "unique-plan.svg")
  )
  switch uniquePlan {
  | Some(artifact) =>
    if !Js.String2.includes(artifact.body, "— FAIL") || Js.String2.includes(artifact.body, "— PASS") {
      fail("a unique sibling artifact must render FAIL when the other proof path collides")
    }
  | None => fail("partial collision should preserve the unique sibling artifact")
  }
}

let outputSafetyFixture = () => {
  if Drakosha_OutputSafety.isAbsentErrorCode("EACCES") || Drakosha_OutputSafety.isAbsentErrorCode("EIO") || !Drakosha_OutputSafety.isAbsentErrorCode("ENOENT") {
    fail("only genuine not-found filesystem codes may be treated as absent")
  }
  expectOutputSafetyError("manifest output cannot traverse upward", () => {
    let _ = Drakosha_OutputSafety.manifestOutputPath(
      ~baseDir="/tmp",
      ~relativePath="../outside.md",
      ~label="test output",
    )
  })
  expectOutputSafetyError("output cannot overwrite protected input", () =>
    Drakosha_OutputSafety.assertNoCollisions(
      ~outputs=[{Drakosha_OutputSafety.label: "output", path: "/tmp/same-file"}],
      ~protectedPaths=[{Drakosha_OutputSafety.label: "input", path: "/tmp/same-file"}],
    )
  )
  let Path(caseDir) = tempDir("drakosha-case-collision-")
  expectOutputSafetyError("case-only output aliases cannot overwrite on a case-insensitive volume", () =>
    Drakosha_OutputSafety.assertNoCollisions(
      ~outputs=[
        {Drakosha_OutputSafety.label: "upper proof", path: caseDir ++ "/Proof.svg"},
        {Drakosha_OutputSafety.label: "lower proof", path: caseDir ++ "/proof.svg"},
      ],
      ~protectedPaths=[],
    )
  )
  expectOutputSafetyError("file outputs cannot be ancestors of other file outputs", () =>
    Drakosha_OutputSafety.assertNoCollisions(
      ~outputs=[
        {Drakosha_OutputSafety.label: "report file", path: caseDir ++ "/bundle"},
        {Drakosha_OutputSafety.label: "nested proof", path: caseDir ++ "/bundle/proof.svg"},
      ],
      ~protectedPaths=[],
    )
  )
}

let diagnosticPublicationFixture = () => {
  let Path(dir) = tempDir("drakosha-diagnostics-")
  let unrelated = dir ++ "/unrelated.txt"
  let report = dir ++ "/report.md"
  let index = dir ++ "/index.json"
  writeText(Path(unrelated), "UNRELATED USER DATA\n")
  linkSync(unrelated, report)
  let set: Drakosha_Diagnostics.diagnosticSet = {
    reportPath: report,
    indexPath: index,
    contentFiles: [{
      relativePath: "report.md",
      destinationPath: report,
      body: "CURRENT REPORT\n",
    }],
    indexBody: "{\"schema\":\"fixture\"}\n",
  }
  Drakosha_Diagnostics.publish(set)
  if readText(Path(unrelated)) != "UNRELATED USER DATA\n" {
    fail("atomic diagnostic replacement must not truncate an out-of-tree hard-link target")
  }
  if readText(Path(report)) != "CURRENT REPORT\n" {
    fail("diagnostic report must replace the destination directory entry")
  }
  Drakosha_Diagnostics.verify(set)
  writeText(Path(report), "STALE OR TAMPERED\n")
  expectOutputSafetyError("the diagnostic index must reject a stale report", () =>
    Drakosha_Diagnostics.verify(set)
  )
}

productionRegression()
passingFixture()
strictDecoderFixture()
orientationContractFixture()
passingPlaceProofFixture()
duplicateShotIdFixture()
actorCollisionFixture()
strictContractFixtures()
proofCollisionFixture()
outputSafetyFixture()
diagnosticPublicationFixture()
Js.log("OK - Drakosha spatial preflight tests passed")
