/* Persistence: a project survives between sessions, and a reload costs zero model
   calls — the world is read from disk, not re-generated. (Voices re-derive on
   demand for now; persisting those too is a later, token-saving refinement.) */
let saveWorld: (Process.bible, string) => unit
let loadWorld: string => option<Process.bible>
