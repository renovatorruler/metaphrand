# Episode 2 selective SFX workflow

This layer is non-destructive and provider-free. It never modifies the V2
spoken master and makes no paid calls.

## Timing-manifest contract

The V2 table-read renderer supplies:

```json
{
  "audio": "EP2_FULL_CAST_TABLE_READ_V2.mp3",
  "duration_seconds": 123.456,
  "blocks": [
    {
      "block_id": "E2SP001",
      "start_seconds": 0.0,
      "end_seconds": 2.4
    }
  ]
}
```

Every one of the 191 spoken block IDs must appear once, in screenplay order.
Cue timestamps are calculated as `block.start_seconds + offset_seconds`.

## Commands

From `studio/`:

```sh
npm run preflight:ep2-sfx
npm run test:ep2-sfx
npm run mix:ep2-sfx
```

The first command validates every source, trim, gain, source ID, and target
block without writing audio. The test command performs a zero-cost end-to-end
mix using synthetic fixtures in a temporary directory. The mix command is used
only after `EP2_FULL_CAST_TABLE_READ_V2.manifest.json` exists. That V2 manifest
is also the timing manifest; its required fields are shown above.

## Outputs

- `EP2_FULL_CAST_TABLE_READ_V2_WITH_SFX.mp3`
- `EP2_FULL_CAST_TABLE_READ_V2_WITH_SFX.manifest.json`

The manifest records the immutable spoken master, source paths and checksums,
licenses, fallback selections, trims, levels, block anchors, offsets, absolute
timestamps, and mix settings.
