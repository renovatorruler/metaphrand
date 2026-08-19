module I = Production_Inspection

let fail = message => {
  Js.log("FAIL - " ++ message)
  assert(false)
}

let expectError = (label, work) => {
  let refused = try {
    work()
    false
  } catch {
  | I.InspectionError(_) => true
  }
  if !refused {
    fail(label ++ ": expected InspectionError")
  }
}

let checks: array<I.check> = [
  {id: "SEM-PRESENCE", description: "The required subject is visible."},
  {id: "SEM-SCALE", description: "Relative scale matches the declared anchor."},
]

let job: I.job = {
  schema: "production.inspection-job/v1",
  workOrderHash: "work-order-hash",
  artifactHash: "artifact-hash",
  policyHash: I.policyHash(checks),
  checks,
}

let result = (checkId, verdict): I.result => {
  checkId,
  verdict,
  confidence: 0.95,
  evidence: "synthetic inspector evidence for " ++ checkId,
}

let report = (results): I.report => {
  schema: "production.inspection-report/v1",
  workOrderHash: job.workOrderHash,
  artifactHash: job.artifactHash,
  policyHash: job.policyHash,
  inspectorId: "fake-independent-inspector",
  results,
}

let pass = report([result("SEM-PRESENCE", I.Pass), result("SEM-SCALE", I.Pass)])
if I.adjudicate(~job, ~report=pass).outcome != I.ReviewReady {
  fail("complete PASS evidence did not become review-ready")
}

let failed = report([result("SEM-PRESENCE", I.Pass), result("SEM-SCALE", I.Fail)])
if I.adjudicate(~job, ~report=failed).outcome != I.Quarantine {
  fail("semantic FAIL did not remain quarantined")
}

let unknown = report([result("SEM-PRESENCE", I.Pass), result("SEM-SCALE", I.Unknown)])
if I.adjudicate(~job, ~report=unknown).outcome != I.HumanRequired {
  fail("semantic UNKNOWN silently passed")
}

expectError("missing check", () =>
  I.adjudicate(~job, ~report=report([result("SEM-PRESENCE", I.Pass)]))->ignore
)
expectError("duplicate check", () =>
  I.adjudicate(
    ~job,
    ~report=report([
      result("SEM-PRESENCE", I.Pass),
      result("SEM-PRESENCE", I.Pass),
      result("SEM-SCALE", I.Pass),
    ]),
  )->ignore
)
expectError("wrong artifact", () =>
  I.adjudicate(~job, ~report={...pass, artifactHash: "different"})->ignore
)
expectError("wrong work order", () =>
  I.adjudicate(~job, ~report={...pass, workOrderHash: "different"})->ignore
)
expectError("wrong policy", () =>
  I.adjudicate(~job, ~report={...pass, policyHash: "different"})->ignore
)
expectError("unknown check", () =>
  I.adjudicate(
    ~job,
    ~report=report([
      result("SEM-PRESENCE", I.Pass),
      result("SEM-SCALE", I.Pass),
      result("SEM-INVENTED", I.Pass),
    ]),
  )->ignore
)

let decodedJob = I.decodeJob(I.encodeJob(job))
let decodedReport = I.decodeReport(I.encodeReport(pass))
if I.encodeJob(decodedJob) != I.encodeJob(job) || I.encodeReport(decodedReport) != I.encodeReport(pass) {
  fail("inspection contracts are not stable across restart")
}

Js.log("PASS - structured independent inspection and fail-closed adjudication")
