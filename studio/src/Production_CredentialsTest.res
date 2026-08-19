/* Cryptographic authority contract tests. The private key below exists only
   in Production_TestFixtures and signs synthetic assertions; no provider or
   network capability is involved. */

module B = Cinema_Backends
module C = Production_Credentials
module D = Production_Domain
module F = Production_TestFixtures

let fail = message => {
  Js.Console.error("FAIL - " ++ message)
  assert(false)
}

let check = (condition, message) =>
  if !condition {
    fail(message)
  }

let expectCredentialError = (label, work) => {
  let failed = try {
    work()
    false
  } catch {
  | C.CredentialError(_) => true
  }
  check(failed, label ++ " should fail closed")
}

let signedPrincipalIsExact = () => {
  let fixture = F.create()
  let binding = C.bindingHash(["provider_adapter", "synthetic-adapter"])
  let raw = F.signedAssertion(
    ~assertionId="ASSERT-EXACT-PRODUCER",
    ~principalId="PR-PRODUCER",
    ~role="producer",
    ~action="register_provider_adapter",
    ~bindingHash=binding,
  )
  let credential = C.verifyPrincipal(
    ~packetPath=fixture.packetPath,
    ~raw,
    ~role=D.Producer,
    ~action="register_provider_adapter",
    ~bindingHash=binding,
  )
  check(C.principalId(credential) == "PR-PRODUCER", "verified producer identity changed")
  expectCredentialError("wrong role", () =>
    C.verifyPrincipal(
      ~packetPath=fixture.packetPath,
      ~raw,
      ~role=D.Inspector,
      ~action="register_provider_adapter",
      ~bindingHash=binding,
    )->ignore
  )
  expectCredentialError("wrong action", () =>
    C.verifyPrincipal(
      ~packetPath=fixture.packetPath,
      ~raw,
      ~role=D.Producer,
      ~action="different_action",
      ~bindingHash=binding,
    )->ignore
  )
  expectCredentialError("wrong binding", () =>
    C.verifyPrincipal(
      ~packetPath=fixture.packetPath,
      ~raw,
      ~role=D.Producer,
      ~action="register_provider_adapter",
      ~bindingHash=C.bindingHash(["provider_adapter", "other-adapter"]),
    )->ignore
  )
  let forged = Js.String2.replace(raw, "PR-PRODUCER", "PR-REVIEWER")
  expectCredentialError("payload tamper", () =>
    C.verifyPrincipal(
      ~packetPath=fixture.packetPath,
      ~raw=forged,
      ~role=D.Producer,
      ~action="register_provider_adapter",
      ~bindingHash=binding,
    )->ignore
  )
}

let humanCommandsAreSingleUseAcrossRestart = () => {
  let fixture = F.create()
  let binding = C.bindingHash(["exact", "synthetic", "review"])
  let raw = F.signedAssertion(
    ~assertionId="CMD-SINGLE-USE",
    ~principalId="PR-REVIEWER",
    ~role="reviewer",
    ~action="record_human_review",
    ~bindingHash=binding,
  )
  let verify = () => C.verifyHumanCommand(
    ~packetPath=fixture.packetPath,
    ~raw,
    ~role=D.Reviewer,
    ~action="record_human_review",
    ~bindingHash=binding,
  )
  let first = verify()
  C.consumeHumanCommand(~stateDir=fixture.stateDir, ~command=first)
  let marker = fixture.stateDir ++ "/commands/CMD-SINGLE-USE.used.json"
  check(B.exists(B.Path(marker)), "single-use command lacks a durable marker")
  let markerBytes = B.readText(B.Path(marker))
  let afterRestart = verify()
  expectCredentialError("replayed command", () =>
    C.consumeHumanCommand(~stateDir=fixture.stateDir, ~command=afterRestart)
  )
  check(B.readText(B.Path(marker)) == markerBytes, "replay altered the consumed-command evidence")
}

let authorityDriftInvalidatesOldSignatures = () => {
  let fixture = F.create()
  let binding = C.bindingHash(["provider_adapter", "drift-adapter"])
  let raw = F.signedAssertion(
    ~assertionId="ASSERT-BEFORE-DRIFT",
    ~principalId="PR-PRODUCER",
    ~role="producer",
    ~action="register_provider_adapter",
    ~bindingHash=binding,
  )
  let packet = B.readText(B.Path(fixture.packetPath))
  let changed = Js.String2.replace(packet, "PR-PRODUCER", "PR-PRODUCER-CHANGED")
  check(changed != packet, "principal drift fixture did not change the packet")
  B.writeText(B.Path(fixture.packetPath), changed)
  expectCredentialError("principal authority drift", () =>
    C.verifyPrincipal(
      ~packetPath=fixture.packetPath,
      ~raw,
      ~role=D.Producer,
      ~action="register_provider_adapter",
      ~bindingHash=binding,
    )->ignore
  )
}

signedPrincipalIsExact()
humanCommandsAreSingleUseAcrossRestart()
authorityDriftInvalidatesOldSignatures()
Js.log("PRODUCTION CREDENTIAL TESTS PASSED")
