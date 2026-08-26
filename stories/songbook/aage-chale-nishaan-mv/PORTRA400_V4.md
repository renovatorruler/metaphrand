# Portra 400 no-HDR v4

`frames_v4_portra400_nohdr/` is the preferred delivery.

The P01–P06 performance frames are unchanged from the brighter v2. The S00–S06 king/commander frames are deterministic grades of the cleaner v1 pixels. They are not ImageGen reconstructions: composition, identity, anatomy, and object placement remain pixel-stable.

## Visual response

- Lower local and global contrast with open shadows.
- Soft highlight shoulder and compressed sunset/water highlights.
- Muted madder, ochre, olive, cyan-blue, and warm-ivory color response.
- Reduced digital acutance and microcontrast.
- No added generative texture, fake film border, scratches, light leaks, or vignette.
- No clarity halos, orange glow, metallic skin, etched clouds, or crunchy water/ground detail.

## Measured change from v2 commander frames

| Metric, mean across S00–S06 | Bright v2 | Portra no-HDR v4 |
|---|---:|---:|
| Luma average | 118.80 | 109.52 |
| 10–90% tonal range | 135.71 | 78.00 |
| Saturation average | 25.77 | 8.81 |

The new grade reduces tonal range by approximately 42% and average saturation by approximately 66%, while preserving a usable bright exposure.

## Exact deterministic filter

Applied independently to each original `frames/S*.png` image:

```text
hqdn3d=3.0:2.5:6.0:6.0,
unsharp=5:5:-0.55:5:5:0,
eq=contrast=0.86:brightness=0.025:saturation=0.74:gamma=1.03:gamma_weight=0.8,
curves=all='0/0.035 0.18/0.21 0.50/0.52 0.78/0.79 1/0.94',
colorbalance=bs=0.008:bm=0.003:rh=0.012:gh=0.004:bh=-0.010
```

## Continuity

- Same commander, grey horse, army, one standard, two pack animals, and left-to-right geography.
- Commander remains last in every frame.
- No generated people, props, architecture, effects, or altered poses.
- All 13 preferred frames remain 1672×941.

Rejected ImageGen-based Portra experiments are archived under `rejected_variants/` and are not part of the delivery.
