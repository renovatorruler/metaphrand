/* Kuku_Ep10State.res — EP10's story clock and continuity state.

   Single source of truth for what is true WHEN. A shot spec no longer asserts
   these facts — it declares its beat, and the prompt builder derives them:

     - where गौरी is (aboard the cart from the briefing until the stop)
     - the dragons' form (GREAT until they shrink, small after)
     - the lighting (the last-golden-evening clock)
     - whether the golden ग-shape exists yet (forged in scene 3 — using it
       earlier is a render-time error, not a reviewable mistake)

   The h16/h21/h33/h36 empty-cart defect happened because these facts were
   hand-copied into each shot; this module exists so they never have to be. */

type beat =
  | RingDrill /* scene 0: the drill, गौरी on the grass / at the cart's side */
  | Briefing /* ऋषि's safety briefing — गौरी is aboard from here */
  | TowerMischief /* scene 0-अ at the tower */
  | RopeSlips /* the knot gives; चील takes the bell */
  | Runaway /* scene 1: the cart runs */
  | Braking /* scene 2: braking, markers, the failed breath */
  | FlatSound /* scene 3: the flat stone answers */
  | Forging /* scene 3: कुकु pours the ग */
  | LastApproach /* scene 4 */
  | TheStop /* scene 5 */
  | AfterStop /* scene 6: shrunk small, गौरी out of the cart */
  | DoorwayNight /* scene 7 */
  | TowerEnd /* scene 8 */

let lighting = b =>
  switch b {
  | RingDrill | Briefing | RopeSlips => "warm golden dusk — the last golden evening; the low sun gilds the paper flagstones"
  | TowerMischief | TowerEnd => "cool fading dusk at the tower, blue-grey light on the stone"
  | Runaway | Braking => "deepening golden dusk, long warm shadows running down the lane"
  | FlatSound | LastApproach | TheStop => "the very last of the gold — the sun nearly down, warm light low and grazing"
  | Forging => "deep dusk — the golden breath-light is the light source of the frame"
  | AfterStop => "soft warm afterglow just after sundown"
  | DoorwayNight => "cool blue evening; the doorway's golden glow is the only warmth in frame"
  }

/* the dragons are in their great forms from the drill until the shrink */
let dragonForm = b =>
  switch b {
  | AfterStop | DoorwayNight | TowerEnd => Kuku_PromptSpec.Small
  | _ => Kuku_PromptSpec.Great
  }

/* गौरी is aboard the cart from the briefing until the cart stops */
let gauriAboard = b =>
  switch b {
  | Briefing | TowerMischief | RopeSlips | Runaway | Braking | FlatSound | Forging | LastApproach | TheStop => true
  | RingDrill | AfterStop | DoorwayNight | TowerEnd => false
  }

/* the golden ग-shape exists only once it has been forged */
let gaExists = b =>
  switch b {
  | Forging | LastApproach | TheStop | AfterStop | DoorwayNight | TowerEnd => true
  | _ => false
  }

/* the bell hangs on the arch until चील cuts it loose */
let bellWithCheel = b =>
  switch b {
  | RopeSlips | Runaway | Braking | FlatSound | Forging | LastApproach | TheStop | AfterStop | DoorwayNight | TowerEnd => true
  | RingDrill | Briefing | TowerMischief => false
  }
