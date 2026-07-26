# The login that forgets you while looking at you
kind: fact
date: 2026-07-13 (observed in this project)
source: firsthand — the PSE fetch build (studio/src/PseFetch.res history)
snag: a machine that greets you as a stranger until it finishes remembering who you are

A single-page app renders you as logged-out first, then "hydrates" your
session and remembers you're a member — so software (or a person) acting in
that gap gets treated as an anonymous stranger by a system that is, at that
very moment, holding their credentials. Also: the session lived in
sessionStorage, so every new process was born logged out; the fix was one
warm, patient session instead of many hasty ones. Bureaucracy texture:
recognition as a race condition.
