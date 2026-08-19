/* Reusable cross-process lease for production-control mutation boundaries.

   Ownership is the open SQLite write transaction held inside the opaque value,
   not the continued presence of a deletable lock file. Process exit releases
   the kernel lock automatically. Releasing an old handle therefore cannot
   unlink or otherwise disturb a successor lease. */

exception LeaseError(string)

type t

let acquire: (
  ~stateDir: string,
  ~relativePath: string,
  ~resource: string,
  ~legacyRelativePath: string=?,
  ~waitMs: int=?,
) => t

/* Idempotent for the same opaque handle. It can release only the transaction
   opened by that handle; it never removes a shared path. */
let release: t => unit

let ownerToken: t => string

/* Always releases, including when work raises an arbitrary exception, and
   re-raises the original work exception. */
let withLease: (
  ~stateDir: string,
  ~relativePath: string,
  ~resource: string,
  ~legacyRelativePath: string=?,
  ~waitMs: int=?,
  unit => 'a,
) => 'a
