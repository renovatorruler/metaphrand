/* Zero-spend regression tests for the scene provenance contract. */

open Cinema_Backends

type hash
@module("crypto") external createHash: string => hash = "createHash"
@send external hUpdate: (hash, string) => hash = "update"
@send external hDigest: (hash, string) => string = "digest"
let sha256 = s => createHash("sha256")->hUpdate(s)->hDigest("hex")

let fail = m => {
  Js.log("FAIL - " ++ m)
  assert(false)
}

let expectOk = (label, r) =>
  switch r {
  | Ok() => ()
  | Error(m) => fail(label ++ ": " ++ m)
  }

let expectError = (label, needle, r) =>
  switch r {
  | Ok() => fail(label ++ ": unexpectedly passed")
  | Error(m) =>
    if !Js.String2.includes(m, needle) {
      fail(label ++ ": expected '" ++ needle ++ "', got '" ++ m ++ "'")
    }
  }

let pathString = p =>
  switch p {
  | Path(s) => s
  }

let receiptString = (path, key) =>
  Js.Json.parseExn(readText(Path(pathString(path) ++ ".receipt.json")))
  ->Js.Json.decodeObject
  ->Belt.Option.flatMap(o => Js.Dict.get(o, key))
  ->Belt.Option.flatMap(Js.Json.decodeString)
  ->Belt.Option.getWithDefault("")

let setReceiptString = (path, key, value) => {
  let receiptPath = Path(pathString(path) ++ ".receipt.json")
  let receipt =
    Js.Json.parseExn(readText(receiptPath))->Js.Json.decodeObject->Belt.Option.getExn
  Js.Dict.set(receipt, key, Js.Json.string(value))
  writeText(receiptPath, Js.Json.stringifyWithSpace(Js.Json.object_(receipt), 2))
}

let fixture = (~dir: string, ~name: string, ~dialogue: string): (path, string) => {
  let path = Path(dir ++ "/" ++ name ++ ".scene.txt")
  let body = "ACTION: Ray closes the door.\nRAY: Give me the keys.\nSAM: No."
  writeText(
    path,
    "test-scene — INT. ROOM - DAY\n[engine-emitted]\n\n@@SCENE@@\n" ++ body,
  )
  let d = Js.Dict.empty()
  Js.Dict.set(d, "schemaVersion", Js.Json.number(2.0))
  Js.Dict.set(d, "id", Js.Json.string("test-scene"))
  Js.Dict.set(d, "slug", Js.Json.string("INT. ROOM - DAY"))
  Js.Dict.set(d, "seedHash", Js.Json.string("seed-fixture"))
  Js.Dict.set(d, "sceneHash", Js.Json.string(sha256(body)))
  Js.Dict.set(d, "gate", Js.Json.string("PASS"))
  Js.Dict.set(d, "dialogue", Js.Json.string(dialogue))
  Js.Dict.set(d, "operation", Js.Json.string("GENERATED"))
  writeText(
    Path(pathString(path) ++ ".receipt.json"),
    Js.Json.stringifyWithSpace(Js.Json.object_(d), 2),
  )
  (path, body)
}

let seedFingerprints = () => {
  let card: Seed.voiceCard = {
    name: "RAY",
    who: "a locksmith",
    register: "plain",
    earnsEloquence: false,
  }
  let beat: Seed.beat = {
    who: "RAY",
    want: "the keys",
    wall: "Sam refuses",
    turn: "Ray leaves",
  }
  let seed: Seed.sceneSeed = {
    id: "seed-test",
    slug: "INT. ROOM - DAY",
    logline: "Ray asks for keys.",
    cast: [card],
    layer: {peshat: "an argument", sod: "trust"},
    beats: [beat],
    rules: ["Keep it short."],
  }
  let base = Write.fingerprintSeed(seed)
  let withLexicon = Write.fingerprintSeed({...seed, cast: [{...card, lexicon: "locks and doors"}]})
  let withEloquence = Write.fingerprintSeed({...seed, cast: [{...card, earnsEloquence: true}]})
  let withSubtext = Write.fingerprintSeed({...seed, beats: [{...beat, subtext: "ask him to stay"}]})
  if base == withLexicon || base == withEloquence || base == withSubtext {
    fail("every prompt-affecting seed field must change the fingerprint")
  }
}

let expectWriteError = async (label, needle, work) => {
  let failed = ref(false)
  try {
    let _ = await work()
  } catch {
  | Write.WriteError(m) => {
      failed := true
      if !Js.String2.includes(m, needle) {
        fail(label ++ ": expected '" ++ needle ++ "', got '" ++ m ++ "'")
      }
    }
  | _ => fail(label ++ ": raised the wrong exception")
  }
  if !failed.contents {
    fail(label ++ ": unexpectedly passed")
  }
}

let main = async () => {
  seedFingerprints()
  let Path(dir) = tempDir("studio-write-safety-")

  let (malformed, _) = fixture(~dir, ~name="malformed", ~dialogue="LIFTED")
  writeText(Path(pathString(malformed) ++ ".receipt.json"), "{broken")
  expectError("malformed receipt", "valid JSON", Write.verifyIntegrity(malformed))

  let (tamperedPending, pendingBody) = fixture(~dir, ~name="tampered-pending", ~dialogue="PENDING")
  writeText(tamperedPending, "test\n@@SCENE@@\n" ++ pendingBody ++ "\nACTION: Ray smiles.")
  expectError("tampered pending receipt", "TAMPERED", Write.verifyIntegrity(tamperedPending))
  await expectWriteError(
    "tampered scene cannot be lifted",
    "TAMPERED",
    () => Write.liftDialogue(~path=tamperedPending, ~maxTries=1),
  )

  let (tamperedLifted, liftedBody) = fixture(~dir, ~name="tampered-lifted", ~dialogue="LIFTED")
  writeText(tamperedLifted, "test\n@@SCENE@@\n" ++ liftedBody ++ "\nACTION: Sam smiles.")
  await expectWriteError(
    "tampered scene cannot be extended",
    "TAMPERED",
    () => Write.extendScene(~path=tamperedLifted, ~afterLine=0, ~brief="Ray opens the door.", ~maxTries=1),
  )

  let (pending, _) = fixture(~dir, ~name="pending", ~dialogue="PENDING")
  expectOk("pending integrity", Write.verifyIntegrity(pending))
  expectError("pending is not production-ready", "DIALOGUE DOCTRINE NOT RUN", Write.verify(pending))
  await expectWriteError(
    "pending scene cannot be extended",
    "must be LIFTED",
    () => Write.extendScene(~path=pending, ~afterLine=0, ~brief="Ray opens the door.", ~maxTries=1),
  )

  let oldHash = receiptString(pending, "sceneHash")
  let lifted = await Write.liftDialogue(~path=pending, ~maxTries=1)
  let _ = Write.emit(lifted, ~txt=pending)
  expectOk("lifted scene verifies", Write.verify(pending))
  if receiptString(pending, "operation") != "DIALOGUE_LIFTED" ||
    receiptString(pending, "parentSceneHash") != oldHash ||
    receiptString(pending, "emittedBy") != "studio/Write.liftDialogue" ||
    receiptString(pending, "workerProvider") != "fake" {
    fail("lift receipt must name its operation and parent scene hash")
  }
  setReceiptString(pending, "workerProvider", "other")
  expectError(
    "schema 3 receipt provider",
    "invalid workerProvider",
    Write.verifyIntegrity(pending),
  )
  setReceiptString(pending, "workerProvider", "fake")

  let liftedHash = receiptString(pending, "sceneHash")
  let extended = await Write.extendScene(
    ~path=pending,
    ~afterLine=0,
    ~brief="Ray opens the door.",
    ~maxTries=1,
  )
  let _ = Write.emit(extended, ~txt=pending)
  expectOk("extended scene keeps integrity", Write.verifyIntegrity(pending))
  expectError("extended scene needs a new lift", "DIALOGUE DOCTRINE NOT RUN", Write.verify(pending))
  if receiptString(pending, "operation") != "EXTENDED" ||
    receiptString(pending, "parentSceneHash") != liftedHash ||
    receiptString(pending, "emittedBy") != "studio/Write.extendScene" ||
    receiptString(pending, "workerProvider") != "fake" {
    fail("extension receipt must name its operation and parent scene hash")
  }

  let relifted = await Write.liftDialogue(~path=pending, ~maxTries=1)
  let _ = Write.emit(relifted, ~txt=pending)
  expectOk("extended then lifted scene verifies", Write.verify(pending))

  Session.close()
  Js.log("OK - write provenance safety tests passed")
}

main()->ignore
