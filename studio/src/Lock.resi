/* One-instance guard: a lockfile, so a second studio run can't start alongside
   the first (the off-machine, can't-do-it-in-types half of the runaway defence). */
let acquire: unit => bool   // true if we took the lock; false if another run holds it
let release: unit => unit
