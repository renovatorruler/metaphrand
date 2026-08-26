# Codex ImageGen prompt package — bright v2

Generation mode: Codex built-in ImageGen, one 16:9 edit per asset. No external service. For every frame, use the v1 frame as Image 1 (exact edit target) and the corresponding v2 master as Image 2 (identity, world, light, and palette reference). Concatenate the relevant common lock and frame delta.

## Performance common lock

> Use case: lighting-weather. Asset type: 16:9 image-to-video source frame. Image 1 is the exact edit target; Image 2 is the bright v2 identity, lighting, palette, Phad, and dafli reference. Restyle into the same bright, well-lit prestige Indian historical-epic cinematic world shown by the v2 master: luminous royal-cobalt blue hour, warm amber key, cool shadow fill, fine gold rim, rich saffron, vermilion, antique gold and peacock green, clear skin and fabric detail, elegant contrast, restrained mythological grandeur, photorealistic and expensive. Change only lighting, atmosphere, tonal balance, and production polish. Preserve the target composition, crop, camera angle, subject pose, expression, hands, object placement, and action. Preserve the exact Mangu identity and costume, one real physical Phad cloth, the same dafli, exactly two poles, and one visible lamp. No crushed blacks, muddy grade, ravanhatta, bow, string instrument, extra person, extra lamp, torch, halo, deity, supernatural portal, text, logo, illustration, or CGI.

### Performance frame deltas

| Frame | Delta |
|---|---|
| P01 | Preserve the extreme-wide locked composition: full barefoot body, entire Phad, both poles, one lamp, generous earth, distant silhouettes, and broad royal-blue sky. Mangu quietly sings with the dafli at chest height. Reveal the Phad and earth clearly while retaining believable blue hour. |
| P02 | Use `canon/mangu_phad_dafli_master_v2_bright.png` directly. |
| P03 | Preserve the collarbone-to-waist detail, exact five-fingered hand resting across the dafli skin, other hand gripping the rim, silver cuffs and rings, neckpiece, red silk, pom-poms, hide texture, lacing, and blurred Phad. Do not create a striking motion. |
| P04 | Preserve the head-and-shoulders singing crop, off-camera gaze, moustache, open grey beard, saffron safa and turra, red silk shoulder, necklaces, tiny dafli rim, and defocused Phad. Illuminate both eyes and all age texture without beauty smoothing. |
| P05 | Preserve medium framing and natural unpitched speech. Dafli remains lowered and vertical in the left hand; right arm hangs empty and away from the skin. No musical gesture. |
| P06 | Preserve the extreme-wide closing composition. Lips fully closed; dafli vertical beside the left thigh; right arm empty; inward expression; no singing, speech, or performance gesture. |

## Story common lock

> Use case: lighting-weather. Asset type: 16:9 image-to-video source frame. Image 1 is the exact edit target; Image 2 is the bright v2 commander, horse, army, river, lighting, and palette reference. Change only illumination, sky and atmosphere, tonal balance, color richness, and prestige historical-cinematic polish. Preserve the target composition, camera height, crop, action, geography, left-to-right movement, bodies, hands, horses, pack animals, standard, and object placement. Match radiant late golden hour: luminous saffron-apricot sky with softly sculpted clouds, bright silver-blue river, warm directional sunlight from screen-right, open-sky fill under turbans, fine gold rim, rich madder, indigo, and raw-cotton colors, and clear detail in faces, fabric, horse hair, earth, and water. Photorealistic prestige Indian historical epic with restrained mythological grandeur, bright and dignified rather than gritty. Preserve the exact approximately 70-year-old commander, indigo-black turban, short grey beard, off-white clothing, madder quilted vest, black shawl, ash-grey horse and worn tack. He remains last. Keep exactly one plain emblem-free faded-red standard and exactly two pack animals where visible. No battle, charge, raised weapon, victory pose, extra flag, emblem, extra rider, duplicate commander, palace, fort, temple, halo, deity, divine beam, supernatural effect, text, logo, crushed blacks, illustration, or CGI.

### Story frame deltas

| Frame | Delta |
|---|---|
| S00 | Use `canon/old_leader_army_river_master_v2_bright.png` directly. |
| S01 | Preserve commander large at left and one anatomically natural open right palm raised in a quiet signal. Preserve army, river, one standard, and two pack animals. Gesture is neither blessing nor triumph. |
| S02 | Preserve the very-wide elevated diagonal from mounted commander at lower-left to the single standard near upper-right. Entire column redirects toward the water; commander remains last. No dust spectacle. |
| S03 | Preserve clean lateral left-to-right profile: mounted commander last at far-left, one grounded line, exactly two pack animals, exactly one straight modest standard at right, generous river and sky. |
| S04 | Preserve tight right-facing commander profile at left, both horse ears at lower-right, river and tiny defocused column/standard behind. Illuminate both eyes and weathered texture; never make it a frontal hero portrait. |
| S05 | Preserve elevated wide diagonal crossing. Front ranks calf-deep, two pack animals entering, one standard at upper-right, commander and grey horse last at near waterline. Only low realistic ripples. |
| S06 | Preserve river-dominant final wide. Column and two pack animals recede toward the far bank behind one small standard; commander and horse remain alone and last at lower-left. Departure and acceptance, never victory or divine passage. |
