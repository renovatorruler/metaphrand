/* Cryptographically verified principals and exact, single-use human commands.
   Private keys never enter the production control plane. */

exception CredentialError(string)

type principalCredential
type humanCommand

let bindingHash: array<string> => string

let verifyPrincipal: (
  ~packetPath: string,
  ~raw: string,
  ~role: Production_Domain.principalRole,
  ~action: string,
  ~bindingHash: string,
) => principalCredential

let verifyHumanCommand: (
  ~packetPath: string,
  ~raw: string,
  ~role: Production_Domain.principalRole,
  ~action: string,
  ~bindingHash: string,
) => humanCommand

let principalId: principalCredential => string
let commandPrincipalId: humanCommand => string
let commandId: humanCommand => string
let consumeHumanCommand: (~stateDir: string, ~command: humanCommand) => unit
