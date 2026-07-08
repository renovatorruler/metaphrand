# INTRIGUE BUILDER — engine pass

**Job:** the audience must never want to stop watching. The tool is the
chain: something revealed completely later, hinted earlier.

## The laws

1. **Worth it.** Intrigue is built only toward reveals that are exciting in
   themselves. A dad buying his son a football deserves no buildup — unless
   the reveal is Ronaldo at the birthday party. Buildup toward a mundane
   reveal produces an uninteresting reveal, which is worse than none.
   Every chain link must DECLARE why its reveal deserves the wait
   (spectacle / reversal / identity / mechanism).

2. **One unrelated line at a time.** Plot-native intrigues (the autopsy
   report in a murder mystery) may run in parallel. But at most ONE
   looks-unrelated chain is live at any point in the story. A chain is
   "live" from its first noticeable hint to its reveal; buried
   insignificant plants don't count as live until a hint makes the
   audience actually curious.

3. **Chain the reveals.** Each reveal answers the standing question and
   opens a better one. Ronaldo shows up (answers: what's the gift?) →
   opens: how did a normal dad get Ronaldo? → reveal: the visa favor →
   opens: what does Ronaldo owe, and to whom? The last link opens nothing.

4. **Tie into the end.** The best chain terminates in the story's final
   reveal. If the Ronaldo birthday thread turns out to tie into the
   murder, that beats both threads separately.

5. **Feel insignificant early.** The best first hint reads as a joke, a
   piece of texture, a throwaway. If it looks unrelated, it must BE
   related — unrelated-looking and actually-unrelated is a cheat.

## The audit procedure

For each chain, card it: hints (scene, what it looks like at plant time,
weight: insignificant / curious / loud), reveal scene, the question it
answers, the question it opens, the declared excitement. Then check:

- every hint precedes its reveal;
- the first hint of a chain is insignificant (or merely curious, if
  plot-native);
- links chain (this link's opened question = next link's answered one);
- at least one chain is terminal, and its last reveal sits in the story's
  final movement;
- at any story index, ≤1 looks-unrelated chain is live;
- every hint eventually has a reveal — a hint that pays nothing is either
  texture (fine, declare it) or a broken promise (fix it).

Runs in the SUBSTANCE battery (it is structure, not polish). Typed model +
mechanical checks: `studio/src/IntrigueCards.res`. Per-story chain cards
live with the story (e.g. `stories/<story>/INTRIGUE_CHAINS.md`).
