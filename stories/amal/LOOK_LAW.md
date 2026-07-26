# अमल — THE LOOK LAW (v1, 2026-07-20 — appended to EVERY visual generation; author calibrates)

*Trigger: the author's verdict on the first probes — "everything looks way too poor and rundown, nothing like how India actually looks; the piss-filter; clothes from the 1950s instead of the 1990s; the bundle is a giant pillow." The models' default India is a Western lens. This block corrects it by law, not vigilance.*

## THE LOOK BLOCK (append verbatim to every prompt)

LOOK: 1990s Madhya Pradesh, India, photographed on Kodak color negative — neutral true-color balance, NO sepia, NO orange or yellow wash, NO teal-orange grade; whites are white, greens are green, natural Indian skin tones. The world is busy, lived-in, and FUNCTIONAL — clean pressed clothes, whitewashed and pastel-painted surfaces, bright printed textiles, gleaming steel utensils — not derelict, not squalid. Period-correct 1990s India: polyester and cotton-blend shirts, trousers (not dhotis) on townsmen, wristwatches, oiled combed hair, chappals; women in bright printed synthetic-blend saris, glass bangles; steel trunks, rexine bags, plastic water jugs, painted Hindi signage.

## BANNED DEFAULTS (the model's clichés — prompt against them when they recur)

Sepia/amber "India filter"; universal squalor and peeling decay; 1950s khadi-village costume on 1990s townspeople; ragged clothing on ordinary passengers (Indians dress crisply); empty-eyed poverty-porn extras; British-Raj-era props in a 1990s frame.

## SET CARDS

RAILWAY COACH (Sc 1–5) — AUTHOR-CORRECTED 2026-07-20: an INTERCITY coach with ENCLOSED SECTIONS, not an open car. Full-height wood-laminate partitions — from inside a section you cannot see other passengers. Real-world anchor: 1990s Indian Railways non-AC First Class — four-berth cabins, sliding door, a side corridor running past barred windows. TWO WINDOWS PER SECTION on the outer wall, one serving each bench (author-corrected 2026-07-20: never the single central European-compartment window — each bench has its own window beside its window seat). The cabin: deep blue rexine berths, cream painted metal, black ceiling fan, luggage rack, stenciled Hindi signage. The corridor: barred windows, standees possible, doors to other cabins. NEVER render an open bay where the whole car is visible. Blocking ripple: Rajesh on the upper berth or corridor seat (no side berths in cabins); the Sc 5 confrontation plays in the CORRIDOR; her flight = down the corridor into the next coach.

ENGINE RULE (2026-07-20): complex boards — any shot with 2+ people, a prop interaction, or blocking logic — use nano_banana_2 WITH reference images (set card, prop cards, character heroes). Soul Cinematic only for simple single-character setups. Every butchered composition to date was Soul Cinematic; the two-hander that worked was nano banana.

GRAYBOX RULE (2026-07-20, PROVEN by the A/B demonstrator): every STAGED shot boards from the standing set — shot numbers map to named cameras in stories/amal/set3d/cabin.blend (built by studio/src/Amal_CabinSet.res); render the gray frame, then repaint via nano_banana_2 with the gray render as the FIRST reference ("repaint this gray 3D blocking render; keep its exact camera position, framing, and geometry") plus prop/character refs. Prompt-only generation is reserved for single faces filling frame. Evidence: demo_A_3d_anchored.png (exact designed geometry) vs demo_B_prompt_only.png (wrong shot entirely). SET REFINEMENTS pending: thinner metal window bars, more of them (real IR count 4–5), and stronger cabin enclosure reading behind the subject.

REFERENCE CARDS (approved-once, attached to every shot they touch): THE CABIN (empty set), THE BUNDLE (swaddled newborn, real weight, face covered), THE CONSTABLE UNIFORM (1990s GRP khaki — native check pending).
SMALL STATION (Sc 2): low whitewashed platform, yellow-on-black Hindi station signboard, vendors with glass-fronted snack cases and kulhads, red-shirted porter, neem trees beyond the platform.

## PROP CARDS (continuity objects — spec them in every shot they appear)

THE BUNDLE: a newborn swaddled snugly in a faded green cotton cloth, the size of a real six-week infant — half an arm's length, small against an adult torso — held upright against the mother's shoulder, one hand supporting its weight, a loose fold of cloth over the face. It reads as a carried baby, never a pillow or a package.
THE STEEL TRUNK: small dented silver steel trunk with a brass latch, under the window seat.
THE SNACK PACKET: newsprint-wrapped namkeen packet, string-tied.

## GRADE NOTE (post)

The Portra look is applied ONCE in post via the LUT pass, never begged per-prompt beyond "Kodak color negative, neutral balance." If a generation comes back amber, it is a retake, not a grading problem.
