module B = Cinema_Backends
module D = Production_Domain

exception CredentialError(string)

type assertionData = {
  id: string,
  principalId: string,
  role: D.principalRole,
  action: string,
  bindingHash: string,
  canonical: string,
  signature: string,
}
type principalCredential = PrincipalCredential(assertionData)
type humanCommand = HumanCommand(assertionData)

type verifier
@module("node:crypto") external createVerify: string => verifier = "createVerify"
@send external verifierUpdate: (verifier, string) => verifier = "update"
@send external verifierEnd: verifier => unit = "end"
@send external verifierVerifyBase64: (verifier, string, string, string) => bool = "verify"
@module("node:path") external dirname: string => string = "dirname"

let die = message => raise(CredentialError(message))

let bindingHash = values => B.sha256Text(values->Js.Array2.joinWith("\u{1f}"))

let objectOf = (json, where) =>
  switch Js.Json.decodeObject(json) {
  | Some(value) => value
  | None => die(where ++ " must be an object")
  }

let requiredString = (object_, key, where) =>
  switch Js.Dict.get(object_, key)->Belt.Option.flatMap(Js.Json.decodeString) {
  | Some(value) if Js.String2.trim(value) != "" => value
  | _ => die(where ++ "." ++ key ++ " must be a nonempty string")
  }

let roleOf = value =>
  switch value {
  | "authorizer" => D.Authorizer
  | "reviewer" => D.Reviewer
  | "producer" => D.Producer
  | "inspector" => D.Inspector
  | other => die("unknown signed principal role '" ++ other ++ "'")
  }

let assertionBody = (~id, ~principalId, ~role, ~action, ~bindingHash) => {
  let row = Js.Dict.empty()
  Js.Dict.set(row, "schema", Js.Json.string("production.signed-assertion/v1"))
  Js.Dict.set(row, "assertionId", Js.Json.string(id))
  Js.Dict.set(row, "principalId", Js.Json.string(principalId))
  Js.Dict.set(row, "role", Js.Json.string(D.principalRoleName(role)))
  Js.Dict.set(row, "action", Js.Json.string(action))
  Js.Dict.set(row, "bindingHash", Js.Json.string(bindingHash))
  D.canonicalJson(Js.Json.object_(row))
}

let decodeAndVerify = (~packetPath, ~raw, ~expectedRole, ~expectedAction, ~expectedBindingHash) => {
  let json = try Js.Json.parseExn(raw) catch {
  | _ => die("signed assertion must be valid JSON")
  }
  let row = objectOf(json, "signed assertion")
  let allowed = [
    "schema",
    "assertionId",
    "principalId",
    "role",
    "action",
    "bindingHash",
    "signature",
  ]
  Js.Dict.keys(row)->Belt.Array.forEach(key =>
    if !(allowed->Belt.Array.some(value => value == key)) {
      die("signed assertion contains unknown field '" ++ key ++ "'")
    }
  )
  if requiredString(row, "schema", "signed assertion") != "production.signed-assertion/v1" {
    die("unsupported signed assertion schema")
  }
  let id = requiredString(row, "assertionId", "signed assertion")
  let principalId = requiredString(row, "principalId", "signed assertion")
  let role = roleOf(requiredString(row, "role", "signed assertion"))
  let action = requiredString(row, "action", "signed assertion")
  let declaredBindingHash = requiredString(row, "bindingHash", "signed assertion")
  let signature = requiredString(row, "signature", "signed assertion")
  if !Js.Re.test_(%re("/^[A-Za-z0-9][A-Za-z0-9._:-]*$/"), id) {
    die("signed assertion id is not a stable identifier")
  }
  if !Js.Re.test_(%re("/^[A-Fa-f0-9]{64}$/"), declaredBindingHash) {
    die("signed assertion bindingHash must contain 64 hexadecimal characters")
  }
  if role != expectedRole || action != expectedAction || declaredBindingHash != expectedBindingHash {
    die("signed assertion does not authorize the exact requested action")
  }
  let context = try {
    D.reconstruct(B.readText(B.Path(packetPath)))
  } catch {
  | D.DomainError(message) => die("cannot verify principal against invalid packet: " ++ message)
  | B.BackendError(message) => die("cannot read principal authority: " ++ message)
  }
  let principal = switch context.packet.principals->Belt.Array.getBy(row => row.id == principalId) {
  | Some(value) => value
  | None => die("signed assertion names an unknown principal")
  }
  if !(principal.roles->Belt.Array.some(value => value == role)) {
    die("principal lacks the signed role")
  }
  let principalAuthorized = principal.decisionIds->Belt.Array.every(decisionId =>
    D.approvalBinds(
      context,
      ~decisionId,
      ~subjectId="principal:" ++ principal.id,
      ~authorityHash=principal.authorityHash,
    )
  )
  if !principalAuthorized {
    die("principal authority is not content-bound to effective approval")
  }
  let canonical = assertionBody(
    ~id,
    ~principalId,
    ~role,
    ~action,
    ~bindingHash=declaredBindingHash,
  )
  let verifier = createVerify("SHA256")
  verifier->verifierUpdate(canonical)->ignore
  verifier->verifierEnd
  let valid = try {
    verifier->verifierVerifyBase64(principal.publicKeyPem, signature, "base64")
  } catch {
  | _ => false
  }
  if !valid {
    die("signed assertion signature is invalid")
  }
  {id, principalId, role, action, bindingHash: declaredBindingHash, canonical, signature}
}

let verifyPrincipal = (~packetPath, ~raw, ~role, ~action, ~bindingHash) =>
  PrincipalCredential(
    decodeAndVerify(
      ~packetPath,
      ~raw,
      ~expectedRole=role,
      ~expectedAction=action,
      ~expectedBindingHash=bindingHash,
    ),
  )

let verifyHumanCommand = (~packetPath, ~raw, ~role, ~action, ~bindingHash) =>
  HumanCommand(
    decodeAndVerify(
      ~packetPath,
      ~raw,
      ~expectedRole=role,
      ~expectedAction=action,
      ~expectedBindingHash=bindingHash,
    ),
  )

let principalId = (PrincipalCredential(value)) => value.principalId
let commandPrincipalId = (HumanCommand(value)) => value.principalId
let commandId = (HumanCommand(value)) => value.id

let consumeHumanCommand = (~stateDir, ~command) => {
  let HumanCommand(value) = command
  let relative = "commands/" ++ value.id ++ ".used.json"
  let path = try {
    Production_OutputSafety.manifestOutputPath(
      ~baseDir=stateDir,
      ~relativePath=relative,
      ~label="single-use human command",
    )
  } catch {
  | Production_OutputSafety.OutputSafetyError(message) => die(message)
  }
  B.ensureDirPath(B.Path(dirname(path)))
  let body = D.canonicalJson(Js.Json.object_(Js.Dict.fromArray([
    ("schema", Js.Json.string("production.consumed-command/v1")),
    ("assertionId", Js.Json.string(value.id)),
    ("principalId", Js.Json.string(value.principalId)),
    ("assertionHash", Js.Json.string(B.sha256Text(value.canonical ++ "\n" ++ value.signature))),
  ]))) ++ "\n"
  if !B.writeTextExclusive(B.Path(path), body) {
    die("human command " ++ value.id ++ " has already been consumed")
  }
}
