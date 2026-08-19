/* Structured, independent candidate inspection. An inspection report is
   evidence only: it has no approval field and cannot promote an artifact. */

exception InspectionError(string)

type verdict = Pass | Fail | Unknown
type check = {id: string, description: string}
type result = {checkId: string, verdict: verdict, confidence: float, evidence: string}
type job = {
  schema: string,
  workOrderHash: string,
  artifactHash: string,
  policyHash: string,
  checks: array<check>,
}
type report = {
  schema: string,
  workOrderHash: string,
  artifactHash: string,
  policyHash: string,
  inspectorId: string,
  results: array<result>,
}
type outcome = Quarantine | HumanRequired | ReviewReady
type adjudication = {
  outcome: outcome,
  reportHash: string,
  failures: array<result>,
  unknowns: array<result>,
}

let verdictName: verdict => string
let outcomeName: outcome => string
let encodeJob: job => string
let decodeJob: string => job
let encodeReport: report => string
let decodeReport: string => report
let policyHash: array<check> => string
let adjudicate: (~job: job, ~report: report) => adjudication
