# SET SPEC — Indian Railways sleeper coach, one bay (measured build spec)

The set is built FROM THIS SPEC, never from memory or from a generated picture. Generated images are for LOOK only (grade, light, mood); geometry comes from photographic evidence and real dimensions.

## Reference photographs (real, Wikimedia Commons)

- `Inside_an_Indian_Railways_Train_-_Sleeper_Coach.jpg` — bay-to-bay view: flat berth slabs, folded middle berths, partition ladder posts, chains.
- `The_window_berth-3tier_coach-Indian_Railways-India458.JPG` — window wall: two barred windows per bay, plain sill, chains, underside of the folded middle berth.
- `The_berth_numbers-3tier_coach-Indian_Railways-India459.JPG` — berth numbering, partition detail.

Local copies: `stories/amal/set3d/ref/`.

## What the photographs establish (and what my first build got wrong)

| fact | first build | corrected |
|---|---|---|
| the lower berth is a FLAT PADDED SLAB, no backrest of any kind | box + tall base = read as a park bench with a back | thin slab on end supports, open underneath |
| there are NO tables | figures' imported furniture read as tables | figures regenerate furniture-free |
| middle berth folds FLAT against the partition, chains hanging | folded but wrong plane | vertical panel on the partition, two chains |
| partition carries a vertical ladder post at its aisle edge | absent | added |
| two barred windows per bay, plain sill | one window band | two, with sill |
| berth underside is open (steel mesh visible) | solid to the floor | open, thin end supports |

Consequence for blocking: because the berth is a backless slab, passengers may sit facing either way along it — but everyone on one berth sits in a row facing the same way in normal daytime use, facing the opposite berth. Opposite-facing seating on the SAME berth is wrong and must never be blocked.

## Dimensions (metres)

Coach interior width 3.05 · ceiling 2.30 · bay pitch 1.95

LOWER BERTH — 1.85 long (window→aisle) × 0.72 wide (along coach) × 0.08 slab, top face at 0.45. Open underneath; two end supports 0.06 thick.
MIDDLE BERTH — same slab, folded VERTICAL against the partition, occupying 0.72 × 0.80 at 1.05–1.85 high, two chains to the ceiling.
UPPER BERTH — same slab, fixed horizontal, top face at 1.70.
PARTITION — full height panel 0.06 thick between bays, with a vertical ladder post (0.05 dia) at its aisle end.
PASSAGEWAY — 0.55 wide, running the length between the main berths and the side berths.
SIDE BERTHS — two, each 0.80 long × 0.62 deep, top face at 0.45, against the far window wall; side upper berth at 1.55.
WINDOWS — two per bay on both outer walls, each 0.75 wide × 0.60 tall, sill at 0.75, five horizontal bars.

## Seat sockets (the blocking anchor points)

Named empties, positions in bay-local coordinates (bay origin at x=0):

SEAT_A_WIN (0.36, 0.42) · SEAT_A_MID (0.36, 0.98) · SEAT_A_AISLE (0.36, 1.52)
SEAT_B_WIN (1.59, 0.42) · SEAT_B_MID (1.59, 0.98) · SEAT_B_AISLE (1.59, 1.52)
SIDE_C (0.52, 2.72) · SIDE_D (1.42, 2.72)
STAND_1 (0.70, 2.12) · STAND_2 (1.62, 2.12)

Seated eye height 1.02 · standing eye height 1.55 · seat contact plane 0.45.

## Rules this spec enforces

1. Furniture belongs to the SET. No character asset may carry a chair, bench, stool or table — references are generated furniture-free, and a mesh that arrives with furniture is rejected, not patched.
2. Characters are placed by seat socket, never by coordinates, and aligned by their seat-contact plane (0.45), never by bounding box.
3. Any set change happens here first, then in the build script — never as a per-shot patch.
