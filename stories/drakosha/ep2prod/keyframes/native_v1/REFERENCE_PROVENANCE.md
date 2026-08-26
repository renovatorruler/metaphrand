# Episode 2 native keyframes — reference provenance lock

## Allowed character references

- Frosya: `packet_pages/frosya-05.png`
- Vasya: `packet_pages/vasya-04.png`
- Mama: `packet_pages/mama-06.png`
- Babies: `packet_pages/babies-13.png` plus the deterministic packet crops
- Yaga: `packet_pages/yaga_domovoy-07.png` and `packet_pages/yaga_flight-08.png`
- Papa: `papa_author_packet_v2.png`, an exact crop from the Papa on `packet_v2/page-02.png`

All paths above are under `stories/drakosha/ep1prod/scene1/references/` unless otherwise noted.

## Forbidden character references

No still or crop extracted from a generated video may supply a character design. This specifically excludes every `job10` Mama or Papa frame and every identity crop derived from generated keyframes such as KF12.

## Approval boundary

Attaching an approved packet reference never approves the resulting frame. Every generated Episode 2 image remains an unapproved candidate until the author explicitly approves that exact image. K01–K04 from the first native-image batch are invalid because their reference stack included an unapproved generated-video character frame.
