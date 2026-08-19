/* Synthetic-only fixture builder shared by production-control tests. Nothing
 in this module names or reads a real story, provider, or media asset. */

module B = Cinema_Backends
module C = Production_Credentials
module G = Production_Gateway

type fixture = {
  root: string,
  packetPath: string,
  stateDir: string,
  storeDir: string,
  firstReferencePath: string,
  secondReferencePath: string,
}

let q = value => Js.Json.stringify(Js.Json.string(value))

let testPublicKeyPem = "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3nUcySpaAmlCbtpsXBQi\nScyuK/FPe6r6SwIHXFb50a7Xww8QXhmkZMX1MXB3ScT6U3uHJONjemYmDFo85zTg\nuM4oOyIaqeszWsxcSWCirEjQEG3tdcjSxdui0IjYVbyznn40s61LyBIp/x7Y6oYx\nh2Ddq1bWHydW+J3lq4+lCin2eVif9sUE2wxTyJJ/biqdzuFl2AzKZ1VTW65DtqWJ\nvojf/yvRUMRei3WxsS1KmrzBMR7qzEGwuvcbETdmowhg3NFnmNwDBmgv1kDVAUaG\nlxonvoOyMPgfnOTWaJP6OC5k8lE6Rm0hbF6aaZNdpH6XIOFJAICgtLO0tP86jujh\n4QIDAQAB\n-----END PUBLIC KEY-----"
let testPrivateKeyPem = "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDedRzJKloCaUJu\n2mxcFCJJzK4r8U97qvpLAgdcVvnRrtfDDxBeGaRkxfUxcHdJxPpTe4ck42N6ZiYM\nWjznNOC4zig7Ihqp6zNazFxJYKKsSNAQbe11yNLF26LQiNhVvLOefjSzrUvIEin/\nHtjqhjGHYN2rVtYfJ1b4neWrj6UKKfZ5WJ/2xQTbDFPIkn9uKp3O4WXYDMpnVVNb\nrkO2pYm+iN//K9FQxF6LdbGxLUqavMExHurMQbC69xsRN2ajCGDc0WeY3AMGaC/W\nQNUBRoaXGie+g7Iw+B+c5NZok/o4LmTyUTpGbSFsXpppk12kfpcg4UkAgKC0s7S0\n/zqO6OHhAgMBAAECggEADv3EbVgRzcTLKc5FbCUdNGz7NdHiwdpBWMmvtkzUNAm8\n15PNzhGbTwE6J1VFbK6+Ed8qudUrEIYOvVldblVVaY7XDjkbo+TKRq2r8HP3MnYL\ns3e8/2mDrrrA6521On3neuBVa+BbUYXL17n78z4M22svNQs6jcnoZgO6BQg+noMa\nQ2QI/3mlRZjBwBLmFjO0chMpqsAcNTm/Qb8Z95BO9qjsXeiZgubKa5cwBS5OWVGk\nL1UOZXhFdCr/y853HJDpLn0uzQcKOrCW9na/1V2hPO5riNLEq68OKbUswmGTcSm/\nu86Ijb1SJ6NuEP20q0qLGVq1zNFybt9Mhg5djFKoiwKBgQDwEzXROMHDsMbpEDVy\nY+SZirHdwPKbvnw1gy9a27aCpzwMdmJX7EuDUCf06KUgS3WkP0qnkOqIA+YvhYly\nAc2KwssOogh3dx7i2Pb3SYqmmmbkZqNZcUiyXPa7Q0YtoNP524EHoVTVttFAzF1A\n/1gX/FopraZH+kQOuaLb6R9A0wKBgQDtNruUUD+rDVhhT44byUdIiEI2C+2UvpZf\nHTEb4iJh877XQPiTL8PQkrUykyCybpRDdqtxQQpNd9Rg2RNtVsXvySSs05fbGkQ/\nvc4frLGb9lgO16Q1eu0jiF2377JDBxj7gRrG9cnnqjcWSwCDtMJtaVe6O2RYa4EL\nMjsIu76B+wKBgQCpKqAtgXTn09UVvVor9L/MgbK7s45AuIUFoB7qQw/kGLtzfKfn\nlJXRPdYp+RUCIKoQxphwYukgVr8IlWw4bZTMRl6XPQ4CQGn/Jys/LQ8KPppqLvjD\nudOj+2XQpqL42+8CjO3q1n/U6DGjG15KwqLso+FUpQwag/sY9S4RD7/6CQKBgQDa\nIMJMl550RElI8kbS9js+T03TNRS6+qZ7v/Qwl7jWKbULawspDXsaiE1mvDQM3/Im\nNzFfa1d19QKuK+7ZVDmfTW8UHV4+c+DeXEL2jW6k49oFi/XL18XILtU/FoLtb9Fh\nNE7TNaD8DmGpdj563fULdxrcfVDAndqD2SS/2yRLkQKBgCTxa//qqqLcDBheApaT\n9qFFegXXKAX7+v07rh+tX5Dpjv1sbX59PWEYPZjuedCOdlMaqy3VCYiDa2dnF2w4\n6qC3JE//zZK+qSZjNl8DSoRkm3WZqBAepfqc1X69e4yPZOLfdrP98Um7E+5RAfQ0\nSJA4187ltkU7C6pAEmzNeHKz\n-----END PRIVATE KEY-----"

type signer
@module("node:crypto") external createSign: string => signer = "createSign"
@send external signerUpdate: (signer, string) => signer = "update"
@send external signerEnd: signer => unit = "end"
@send external signerSignBase64: (signer, string, string) => string = "sign"

let signedAssertion = (~assertionId, ~principalId, ~role, ~action, ~bindingHash) => {
  let body = Js.Dict.empty()
  Js.Dict.set(body, "schema", Js.Json.string("production.signed-assertion/v1"))
  Js.Dict.set(body, "assertionId", Js.Json.string(assertionId))
  Js.Dict.set(body, "principalId", Js.Json.string(principalId))
  Js.Dict.set(body, "role", Js.Json.string(role))
  Js.Dict.set(body, "action", Js.Json.string(action))
  Js.Dict.set(body, "bindingHash", Js.Json.string(bindingHash))
  let canonical = Production_Domain.canonicalJson(Js.Json.object_(body))
  let signer = createSign("SHA256")
  signer->signerUpdate(canonical)->ignore
  signer->signerEnd
  let signature = signer->signerSignBase64(testPrivateKeyPem, "base64")
  Js.Dict.set(body, "signature", Js.Json.string(signature))
  Production_Domain.canonicalJson(Js.Json.object_(body)) ++ "\n"
}

type bindingSource = {subjectId: string, authorityHash: string, decisionIds: array<string>}
type eventSource = {
  decisionId: string,
  scope: string,
  dependencies: array<string>,
  sequence: int,
  eventJson: Js.Json.t,
}

let jsonObject = json => json->Js.Json.decodeObject->Belt.Option.getExn
let jsonArray = json => json->Js.Json.decodeArray->Belt.Option.getExn
let field = (object_, key) => Js.Dict.get(object_, key)->Belt.Option.getExn
let stringField = (object_, key) => field(object_, key)->Js.Json.decodeString->Belt.Option.getExn
let stringArrayField = (object_, key) =>
  field(object_, key)
  ->jsonArray
  ->Belt.Array.map(value => value->Js.Json.decodeString->Belt.Option.getExn)
let intField = (object_, key) =>
  field(object_, key)->Js.Json.decodeNumber->Belt.Option.map(Js.Math.floor_int)->Belt.Option.getExn

/* Synthetic packet authoring mirrors the production packet contract: events
   are globally chained in sequence order and their ids are derived only after
   all event payload fields (including approval bindings) are final. */
let sealDecisionEvents = raw => {
  let rootJson = Js.Json.parseExn(raw)
  let root = jsonObject(rootJson)
  Js.Dict.set(root, "schema", Js.Json.string("production-packet/v2"))
  let events: array<eventSource> = []
  field(root, "decisionLedgers")
  ->jsonArray
  ->Belt.Array.forEach(ledgerJson => {
    let ledger = jsonObject(ledgerJson)
    let decisionId = stringField(ledger, "decisionId")
    let scope = stringField(ledger, "scope")
    let dependencies = stringArrayField(ledger, "dependencies")
    field(ledger, "events")
    ->jsonArray
    ->Belt.Array.forEach(eventJson => {
      let event = jsonObject(eventJson)
      events
      ->Js.Array2.push({
        decisionId,
        scope,
        dependencies,
        sequence: intField(event, "sequence"),
        eventJson,
      })
      ->ignore
    })
  })
  events->Js.Array2.sortInPlaceWith((left, right) => left.sequence - right.sequence)->ignore
  let previousEventId = ref(None)
  events->Belt.Array.forEach(source => {
    let event = jsonObject(source.eventJson)
    Js.Dict.set(
      event,
      "previousEventId",
      switch previousEventId.contents {
      | Some(value) => Js.Json.string(value)
      | None => Js.Json.null
      },
    )
    let eventId = Production_Domain.deriveDecisionEventIdJson(
      ~decisionId=source.decisionId,
      ~scope=source.scope,
      ~dependencies=source.dependencies,
      source.eventJson,
    )
    Js.Dict.set(event, "eventId", Js.Json.string(eventId))
    previousEventId := Some(eventId)
  })
  let decisionHistory = Js.Dict.empty()
  Js.Dict.set(
    decisionHistory,
    "eventCount",
    Js.Json.number(Belt.Int.toFloat(Belt.Array.length(events))),
  )
  Js.Dict.set(
    decisionHistory,
    "headEventId",
    switch previousEventId.contents {
    | Some(value) => Js.Json.string(value)
    | None => Js.Json.null
    },
  )
  Js.Dict.set(root, "decisionHistory", Js.Json.object_(decisionHistory))
  Js.Json.stringify(rootJson)
}

/* Test packets are content-bound the same way a packet-authoring tool would
   bind a reviewed object revision into each approval. Mutating a returned
   packet later intentionally leaves stale bindings, which exercises fail-closed
   authority drift. */
let bindApprovals = raw => {
  let rootJson = Js.Json.parseExn(raw)
  let root = jsonObject(rootJson)
  let sources: array<bindingSource> = []
  let collect = (arrayKey, prefix) =>
    field(root, arrayKey)
    ->jsonArray
    ->Belt.Array.forEach(json => {
      let row = jsonObject(json)
      sources
      ->Js.Array2.push({
        subjectId: prefix ++ stringField(row, "id"),
        authorityHash: Production_Domain.canonicalHashJson(Js.Json.stringify(json)),
        decisionIds: stringArrayField(row, "decisionIds"),
      })
      ->ignore
    })
  collect("principals", "principal:")
  collect("entities", "entity:")
  collect("assets", "asset:")
  collect("targets", "target:")
  collect("requirements", "requirement:")
  collect("policies", "policy:")
  field(root, "decisionLedgers")
  ->jsonArray
  ->Belt.Array.forEach(ledgerJson => {
    let ledger = jsonObject(ledgerJson)
    let decisionId = stringField(ledger, "decisionId")
    field(ledger, "events")
    ->jsonArray
    ->Belt.Array.forEach(eventJson => {
      let event = jsonObject(eventJson)
      if stringField(event, "kind") == "approve" {
        let bindings =
          sources
          ->Belt.Array.keep(source => source.decisionIds->Belt.Array.some(id => id == decisionId))
          ->Belt.Array.map(
            source => {
              let binding = Js.Dict.empty()
              Js.Dict.set(binding, "subjectId", Js.Json.string(source.subjectId))
              Js.Dict.set(binding, "contentSha256", Js.Json.string(source.authorityHash))
              Js.Json.object_(binding)
            },
          )
        Js.Dict.set(event, "bindings", Js.Json.array(bindings))
      }
    })
  })
  Js.Json.stringify(rootJson)->sealDecisionEvents
}

let packetRaw = (~firstHash, ~secondHash) =>
  `{
  "schema":"production-packet/v2",
  "packetId":"PKT-CONTROL-PLANE-TEST",
  "revision":1,
  "decisionLedgers":[
    {
      "decisionId":"D-FOUNDATION","scope":"authority.foundation","dependencies":[],
      "events":[
        {"eventId":"EV-FOUNDATION-PROPOSE","sequence":1,"kind":"propose","statement":"Synthetic production foundation"},
        {"eventId":"EV-FOUNDATION-APPROVE","sequence":2,"kind":"approve","note":"Explicit synthetic approval"}
      ]
    },
    {
      "decisionId":"D-BLOCKING","scope":"blocking.synthetic-target","dependencies":["D-FOUNDATION"],
      "events":[
        {"eventId":"EV-BLOCKING-PROPOSE","sequence":3,"kind":"propose","statement":"Synthetic target contract"},
        {"eventId":"EV-BLOCKING-APPROVE","sequence":4,"kind":"approve"}
      ]
    }
  ],
  "principals":[
    {"id":"PR-AUTHORIZER","roles":["authorizer"],"publicKeyPem":${q(
      testPublicKeyPem,
    )},"decisionIds":["D-FOUNDATION"]},
    {"id":"PR-REVIEWER","roles":["reviewer"],"publicKeyPem":${q(
      testPublicKeyPem,
    )},"decisionIds":["D-FOUNDATION"]},
    {"id":"PR-PRODUCER","roles":["producer"],"publicKeyPem":${q(
      testPublicKeyPem,
    )},"decisionIds":["D-FOUNDATION"]},
    {"id":"PR-INSPECTOR","roles":["inspector"],"publicKeyPem":${q(
      testPublicKeyPem,
    )},"decisionIds":["D-FOUNDATION"]}
  ],
  "entities":[
    {
      "id":"E-SUBJECT","label":"Synthetic subject","kind":"character","decisionIds":["D-FOUNDATION"],
      "states":[
        {"id":"entry","label":"Entry state","tags":["entry"],"dimensions":{"width":2,"height":4,"depth":1.5,"unit":"in"},"locationEntityId":"E-ROOM"},
        {"id":"exit","label":"Exit state","tags":["exit"],"dimensions":{"width":2,"height":4,"depth":1.5,"unit":"in"},"locationEntityId":"E-ROOM"}
      ]
    },
    {
      "id":"E-ANCHOR","label":"Synthetic anchor","kind":"set_object","decisionIds":["D-FOUNDATION"],
      "states":[
        {"id":"installed","label":"Installed","tags":["anchor"],"dimensions":{"width":40,"height":40,"depth":20,"unit":"in"},"locationEntityId":"E-ROOM"}
      ]
    },
    {
      "id":"E-FORBIDDEN","label":"Forbidden synthetic extra","kind":"prop","decisionIds":["D-FOUNDATION"],
      "states":[
        {"id":"visible","label":"Visible","tags":["forbidden"],"dimensions":{"width":1,"height":1,"depth":1,"unit":"in"},"locationEntityId":"E-ROOM"}
      ]
    },
    {
      "id":"E-ROOM","label":"Synthetic room","kind":"location","decisionIds":["D-FOUNDATION"],
      "states":[
        {"id":"day","label":"Day","tags":["interior"],"dimensions":{"width":180,"height":96,"depth":144,"unit":"in"}}
      ]
    }
  ],
  "assets":[
    {
      "id":"A-SUBJECT","label":"Synthetic subject reference","kind":"reference",
      "status":"approved","path":"fixtures/subject.txt","contentSha256":${q(firstHash)},
      "entityIds":["E-SUBJECT"],"referenceAssetIds":[],"decisionIds":["D-FOUNDATION"]
    },
    {
      "id":"A-SET","label":"Synthetic set reference","kind":"reference",
      "status":"approved","path":"fixtures/set.txt","contentSha256":${q(secondHash)},
      "entityIds":["E-ANCHOR","E-ROOM"],"referenceAssetIds":[],"decisionIds":["D-FOUNDATION"]
    }
  ],
  "targets":[
    {
      "id":"T-SYNTHETIC","purpose":"Exercise the generic production lifecycle",
      "principalAction":"Subject reveals itself from behind the anchor",
      "operation":"synthetic_octets","declaredActionCount":1,"declaredContinuousSeconds":3.5,
      "entityIds":["E-SUBJECT","E-ANCHOR","E-ROOM"],
      "assetIds":["A-SUBJECT","A-SET"],
      "requirementIds":["R-CONTINUITY","R-PRESENCE","R-FORBIDDEN","R-SCALE","R-GEOGRAPHY","R-CAMERA","R-FRAMING","R-COMPLEXITY","R-REFERENCES"],
      "dependsOnTargetIds":[],"decisionIds":["D-BLOCKING"]
    }
  ],
  "requirements":[
    {
      "id":"R-CONTINUITY","targetId":"T-SYNTHETIC","scope":"continuity.synthetic-subject",
      "validator":"deterministic","decisionIds":["D-FOUNDATION","D-BLOCKING"],"kind":"continuity",
      "spec":{"entityId":"E-SUBJECT","beforeStateId":"entry","afterStateId":"exit"}
    },
    {
      "id":"R-PRESENCE","targetId":"T-SYNTHETIC","scope":"presence.synthetic-subject",
      "validator":"semantic_inspector","decisionIds":["D-BLOCKING"],"kind":"presence",
      "spec":{"entityId":"E-SUBJECT","stateId":"exit","minimum":1,"maximum":1}
    },
    {
      "id":"R-FORBIDDEN","targetId":"T-SYNTHETIC","scope":"forbidden.synthetic-extra",
      "validator":"semantic_inspector","decisionIds":["D-BLOCKING"],"kind":"forbidden",
      "spec":{"entityId":"E-FORBIDDEN","stateId":"visible"}
    },
    {
      "id":"R-SCALE","targetId":"T-SYNTHETIC","scope":"scale.subject-to-anchor",
      "validator":"deterministic","decisionIds":["D-BLOCKING"],"kind":"relative_scale",
      "spec":{"subjectEntityId":"E-SUBJECT","subjectStateId":"exit","referenceEntityId":"E-ANCHOR","referenceStateId":"installed","minRatio":0.09,"maxRatio":0.11}
    },
    {
      "id":"R-GEOGRAPHY","targetId":"T-SYNTHETIC","scope":"geography.concealment",
      "validator":"semantic_inspector","decisionIds":["D-BLOCKING"],"kind":"geography",
      "spec":{"subjectEntityId":"E-SUBJECT","referenceEntityId":"E-ANCHOR","relation":"behind"}
    },
    {
      "id":"R-CAMERA","targetId":"T-SYNTHETIC","scope":"camera.protected-side",
      "validator":"human_only","decisionIds":["D-BLOCKING"],"kind":"camera_side",
      "spec":{"side":"right","anchorEntityId":"E-ANCHOR","occluderEntityId":"E-ANCHOR"}
    },
    {
      "id":"R-FRAMING","targetId":"T-SYNTHETIC","scope":"framing.readability",
      "validator":"semantic_inspector","decisionIds":["D-BLOCKING"],"kind":"framing",
      "spec":{"shotSize":"wide","requiredEntityIds":["E-SUBJECT","E-ANCHOR"],"fullyVisible":false}
    },
    {
      "id":"R-COMPLEXITY","targetId":"T-SYNTHETIC","scope":"complexity.single-action",
      "validator":"deterministic","decisionIds":["D-BLOCKING"],"kind":"complexity",
      "spec":{"maxPrincipalActions":1,"maxVisibleEntities":3,"maxContinuousSeconds":4}
    },
    {
      "id":"R-REFERENCES","targetId":"T-SYNTHETIC","scope":"references.exact",
      "validator":"deterministic","decisionIds":["D-BLOCKING"],"kind":"references",
      "spec":{"assetIds":["A-SUBJECT","A-SET"],"exact":true}
    }
  ],
  "policies":[
    {"id":"P-ATTEMPTS","decisionIds":["D-FOUNDATION"],"kind":"attempts","spec":{"maxPerTarget":2}},
    {"id":"P-REVIEW","decisionIds":["D-FOUNDATION"],"kind":"review","spec":{"batchSize":3,"requireHumanApproval":true}},
    {"id":"P-COMPLEXITY","decisionIds":["D-FOUNDATION"],"kind":"complexity","spec":{"maxPrincipalActions":1,"maxVisibleEntities":3,"maxContinuousSeconds":5}},
    {"id":"P-EXECUTION","decisionIds":["D-FOUNDATION"],"kind":"execution","spec":{"requiresExplicitAuthorization":true}}
  ]
}`->bindApprovals

let create = () => {
  let B.Path(root) = B.tempDir("production-control-")
  let fixtureDir = root ++ "/fixtures"
  let firstReferencePath = fixtureDir ++ "/subject.txt"
  let secondReferencePath = fixtureDir ++ "/set.txt"
  let packetPath = root ++ "/production.packet.json"
  let stateDir = root ++ "/control"
  let storeDir = stateDir ++ "/store"
  B.ensureDirPath(B.Path(fixtureDir))
  B.ensureDirPath(B.Path(stateDir))
  B.writeText(B.Path(firstReferencePath), "synthetic subject reference\n")
  B.writeText(B.Path(secondReferencePath), "synthetic set reference\n")
  B.writeText(
    B.Path(packetPath),
    packetRaw(
      ~firstHash=B.sha256File(B.Path(firstReferencePath)),
      ~secondHash=B.sha256File(B.Path(secondReferencePath)),
    ) ++ "\n",
  )
  {root, packetPath, stateDir, storeDir, firstReferencePath, secondReferencePath}
}

let registerFakeProviderAt = (~packetPath, ~adapterId, ~submit) =>
  G.registerProvider(
    ~packetPath,
    ~adapterId,
    ~credentialText=signedAssertion(
      ~assertionId="ASSERT-REGISTER-" ++ adapterId,
      ~principalId="PR-PRODUCER",
      ~role="producer",
      ~action="register_provider_adapter",
      ~bindingHash=C.bindingHash(["provider_adapter", adapterId]),
    ),
    ~submit,
  )

let registerFakeProvider = (~fixture: fixture, ~adapterId, ~submit) =>
  registerFakeProviderAt(~packetPath=fixture.packetPath, ~adapterId, ~submit)

let executionCommand = (~cleared, ~provider, ~assertionId) =>
  signedAssertion(
    ~assertionId,
    ~principalId="PR-AUTHORIZER",
    ~role="authorizer",
    ~action="authorize_execution",
    ~bindingHash=G.authorizationBinding(~cleared, ~provider),
  )

let executionCommandForBinding = (~bindingHash, ~assertionId) =>
  signedAssertion(
    ~assertionId,
    ~principalId="PR-AUTHORIZER",
    ~role="authorizer",
    ~action="authorize_execution",
    ~bindingHash,
  )

let inspectorCredential = (~adapterId, ~assertionId) =>
  signedAssertion(
    ~assertionId,
    ~principalId="PR-INSPECTOR",
    ~role="inspector",
    ~action="register_inspector_adapter",
    ~bindingHash=C.bindingHash(["inspector_adapter", adapterId]),
  )

let reviewCommandForBinding = (~bindingHash, ~assertionId) =>
  signedAssertion(
    ~assertionId,
    ~principalId="PR-REVIEWER",
    ~role="reviewer",
    ~action="record_human_review",
    ~bindingHash,
  )
