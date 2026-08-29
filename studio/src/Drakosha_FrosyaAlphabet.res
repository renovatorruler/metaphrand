/* Rebuild and verify Frosya's composable Episode 1 alphabet assets.

   The graphite PNG is always the master geometry. Ignition states are derived
   from its alpha mask with ffmpeg. The accepted Episode 1 full-magic set is
   frozen in the v1 export and restored byte-for-byte during production builds;
   later glow experiments must remain in qa/ and never overwrite that set.

   Usage from studio/:
     rescript && node src/Drakosha_FrosyaAlphabet.res.mjs build
     rescript && node src/Drakosha_FrosyaAlphabet.res.mjs build-magic-a
     rescript && node src/Drakosha_FrosyaAlphabet.res.mjs compare-magic-a
     rescript && node src/Drakosha_FrosyaAlphabet.res.mjs glow-lab-a
     rescript && node src/Drakosha_FrosyaAlphabet.res.mjs lineup-a
     rescript && node src/Drakosha_FrosyaAlphabet.res.mjs verify
     rescript && node src/Drakosha_FrosyaAlphabet.res.mjs build-full
     rescript && node src/Drakosha_FrosyaAlphabet.res.mjs verify-full
     rescript && node src/Drakosha_FrosyaAlphabet.res.mjs review-full
*/

open Cinema_Backends

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exit: int => unit = "exit"

let root = "../stories/drakosha/production/alphabet/frosya"
let canvas = 2048
let safety = 307 // 15% of 2048, rounded up
let canonicalMagicArchive = root ++ "/exports/frosya_ep1_alphabet_v1.zip"

let episode1Letters = ["А", "О", "М", "С", "К", "Т", "Л", "Б"]

let letters = [
  "А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й",
  "К", "Л", "М", "Н", "О", "П", "Р", "С", "Т", "У", "Ф",
  "Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь", "Э", "Ю", "Я",
]

let remainingLetters = letters->Belt.Array.keep(letter =>
  !(episode1Letters->Belt.Array.some(approved => approved == letter))
)

let canonicalMagicHashes = [
  ("А", "a26add0aaf9841f538c7df5359c229d1f59d876bc7c1931334894b853514108a"),
  ("О", "300f0502cfb1e490aaee443991d442677f0ad4f61168a0675a2c6f0899a2c48a"),
  ("М", "3d718c3a33aa6a497bb1deae46335b79ecf7d25820599c78aa18d4901fdd5218"),
  ("С", "1aacd47576b21941013fd2a7c96b8fcbd663bfd0dc7cf6b57be9eeb4fcfb2a6f"),
  ("К", "74f1db41ff1e0d98330ee683c62287acba2a05a99581039b5f4f5eb541e094a6"),
  ("Т", "7959905b27363bf2a5ddf40d1e31814bb7e09bb0ded4ca98414c46bb16b6319a"),
  ("Л", "d0ca1a41faa6b71fac3b8217c76f083c7d3a6cc72c6b3355a25c8df16481df9d"),
  ("Б", "7920a4ce9aa37307b45aecd7e745a1def1309a483a36623c7a9b0a6221b2e45b"),
]

type glowState = {
  dir: string,
  core: string,
  inner: string,
  tight: string,
  medium: string,
  broad: string,
  trace: string,
  coreColor: string,
  innerColor: string,
  tightColor: string,
  mediumColor: string,
  broadColor: string,
  particles: string,
  innerSigma: int,
  tightSigma: int,
  mediumSigma: int,
  broadSigma: int,
}

let states = [
  {
    dir: "ignite_25",
    core: "0.25",
    inner: "0.10",
    tight: "0.15",
    medium: "0.03",
    broad: "0.01",
    trace: "0.65",
    coreColor: "0xFFFBE8",
    innerColor: "0xFFE36A",
    tightColor: "0xFFB900",
    mediumColor: "0xFF8A00",
    broadColor: "0xD85B00",
    particles: "0",
    innerSigma: 3,
    tightSigma: 10,
    mediumSigma: 30,
    broadSigma: 85,
  },
  {
    dir: "ignite_50",
    core: "0.55",
    inner: "0.35",
    tight: "0.40",
    medium: "0.14",
    broad: "0.06",
    trace: "0.35",
    coreColor: "0xFFFBE8",
    innerColor: "0xFFE36A",
    tightColor: "0xFFB900",
    mediumColor: "0xFF8A00",
    broadColor: "0xD85B00",
    particles: "0",
    innerSigma: 3,
    tightSigma: 10,
    mediumSigma: 30,
    broadSigma: 85,
  },
  {
    dir: "ignite_75",
    core: "1.00",
    inner: "1.00",
    tight: "1.00",
    medium: "0.95",
    broad: "0.52",
    trace: "0.04",
    coreColor: "0xFFFBE8",
    innerColor: "0xFFE36A",
    tightColor: "0xFFB900",
    mediumColor: "0xFF8A00",
    broadColor: "0xD85B00",
    particles: "0.80",
    innerSigma: 3,
    tightSigma: 10,
    mediumSigma: 30,
    broadSigma: 85,
  },
  {
    dir: "ignite_90",
    core: "1.00",
    inner: "1.00",
    tight: "1.00",
    medium: "0.95",
    broad: "0.52",
    trace: "0.04",
    coreColor: "0xFFFBE8",
    innerColor: "0xFFE36A",
    tightColor: "0xFFB900",
    mediumColor: "0xFF8A00",
    broadColor: "0xD85B00",
    particles: "0.80",
    innerSigma: 3,
    tightSigma: 10,
    mediumSigma: 30,
    broadSigma: 85,
  },
  {
    dir: "magic",
    core: "1.00",
    inner: "1.00",
    tight: "1.00",
    medium: "0.95",
    broad: "0.52",
    trace: "0.04",
    coreColor: "0xFFFBE8",
    innerColor: "0xFFE36A",
    tightColor: "0xFFB900",
    mediumColor: "0xFF8A00",
    broadColor: "0xD85B00",
    particles: "0.80",
    innerSigma: 3,
    tightSigma: 10,
    mediumSigma: 30,
    broadSigma: 85,
  },
]

let path = (s: string): path => Path(root ++ "/" ++ s)

let fail = (message: string): unit => {
  Js.Console.error(message)
  exit(1)
}

let runOrFail = (~cmd: string, ~args: array<string>, ~label: string): unit => {
  let result = run(~cmd, ~args)
  if result.code != 0 {
    fail(label ++ " failed\n" ++ result.stderr)
  }
}

let particleShift = (letter: string): (int, int) =>
  switch letter {
  | "А" => (-20, 10)
  | "О" => (30, -30)
  | "М" => (-40, 25)
  | "С" => (0, 0)
  | "К" => (25, 20)
  | "Т" => (-25, -15)
  | "Л" => (35, 10)
  | "Б" => (-10, -25)
  | _ => (0, 0)
  }

let shifted = (value: int, shift: int): string => Belt.Int.toString(value + shift)

type particlePoint = {
  x: int,
  y: int,
  size: int,
}

let sparklePoints = [
  {x: 600, y: 680, size: 0},
  {x: 1440, y: 760, size: 0},
  {x: 1410, y: 1320, size: 0},
  {x: 700, y: 1450, size: 0},
]

let seedFor = (letter: string, base: int, step: int): string => {
  let index = switch Belt.Array.getIndexBy(letters, item => item == letter) {
  | Some(value) => value
  | None => 0
  }
  Belt.Int.toString(base + index * step)
}

/* The accepted eight retain their historical seeds byte-for-byte. New letters
   receive stable per-letter seeds from canonical alphabet order so the dust
   field never repeats across the expanded set. */
let particleSeed = (letter: string): string =>
  switch letter {
  | "А" => "101"
  | "О" => "211"
  | "М" => "307"
  | "С" => "401"
  | "К" => "503"
  | "Т" => "601"
  | "Л" => "701"
  | "Б" => "809"
  | _ => seedFor(letter, 1103, 101)
  }

let coarseParticleSeed = (letter: string): string =>
  switch letter {
  | "А" => "199"
  | "О" => "293"
  | "М" => "389"
  | "С" => "499"
  | "К" => "593"
  | "Т" => "691"
  | "Л" => "787"
  | "Б" => "887"
  | _ => seedFor(letter, 4507, 103)
  }

let hotParticleSeed = (letter: string): string =>
  switch letter {
  | "А" => "313"
  | "О" => "419"
  | "М" => "521"
  | "С" => "601"
  | "К" => "719"
  | "Т" => "811"
  | "Л" => "919"
  | "Б" => "1013"
  | _ => seedFor(letter, 7919, 107)
  }

let flareParticleSeed = (letter: string): string =>
  switch letter {
  | "А" => "733"
  | "О" => "827"
  | "М" => "929"
  | "С" => "1031"
  | "К" => "1129"
  | "Т" => "1229"
  | "Л" => "1327"
  | "Б" => "1429"
  | _ => seedFor(letter, 11443, 109)
  }

let cloudSeed = (letter: string): string =>
  switch letter {
  | "А" => "1571"
  | "О" => "1663"
  | "М" => "1759"
  | "С" => "1861"
  | "К" => "1951"
  | "Т" => "2053"
  | "Л" => "2153"
  | "Б" => "2267"
  | _ => seedFor(letter, 15131, 113)
  }

let coreModulationSeed = (letter: string): string =>
  switch letter {
  | "А" => "2381"
  | "О" => "2477"
  | "М" => "2579"
  | "С" => "2683"
  | "К" => "2791"
  | "Т" => "2897"
  | "Л" => "3001"
  | "Б" => "3109"
  | _ => seedFor(letter, 18839, 127)
  }

let particleFilter = (state: glowState, letter: string): string => {
  if state.particles == "0" {
    `[mregion]nullsink;[letter]crop=1434:1434:307:307,` ++
    `pad=2048:2048:307:307:color=black@0,format=rgba[out]`
  } else {
    let (dx, dy) = particleShift(letter)
    let sparkles = sparklePoints
    ->Belt.Array.map(point =>
      `drawbox=x=${shifted(point.x, dx)}:y=${shifted(point.y - 8, dy)}:w=3:h=17:color=0xFFFBE8@${state.particles}:t=fill:replace=1,` ++
      `drawbox=x=${shifted(point.x - 8, dx)}:y=${shifted(point.y, dy)}:w=17:h=3:color=0xFFFBE8@${state.particles}:t=fill:replace=1`
    )
    ->Js.Array2.joinWith(",")
    `[mregion]gblur=sigma=72,lut=y='clip(val*4,0,255)'[particleRegion];` ++
    `color=c=black:s=512x512:d=1,noise=alls=100:allf=u:all_seed=${particleSeed(letter)},` ++
    `format=gray,scale=2048:2048:flags=neighbor,lut=y='if(gt(val,56),255,0)'[noise];` ++
    `[noise][particleRegion]blend=all_expr='A*B/255',dilation,` ++
    `lut=y='val*${state.particles}',format=gray[particleAlpha];` ++
    `color=c=0xFFD34F:s=2048x2048:d=1,format=rgb24[particleColor];` ++
    `[particleColor][particleAlpha]alphamerge[fineParticles];` ++
    `color=c=black:s=2048x2048:d=1,format=rgba,colorchannelmixer=aa=0,` ++
    sparkles ++ `[sparkles];` ++
    `[letter][fineParticles]overlay=format=auto[withFineParticles];` ++
    `[withFineParticles][sparkles]overlay=format=auto,format=rgba[raw];` ++
    `[raw]crop=1434:1434:307:307,` ++
    `pad=2048:2048:307:307:color=black@0,format=rgba[out]`
  }
}

let filterForState = (state: glowState, letter: string): string =>
  `[0:v]split=2[source][residue];` ++
  `[source]alphaextract,split=6[mcore][minner][mtight][mmedium][mbroad][mregion];` ++
  `[mcore]lut=y='val*${state.core}'[acore];` ++
  `[minner]gblur=sigma=${Belt.Int.toString(state.innerSigma)},lut=y='val*${state.inner}'[ainner];` ++
  `[mtight]gblur=sigma=${Belt.Int.toString(state.tightSigma)},lut=y='val*${state.tight}'[atight];` ++
  `[mmedium]gblur=sigma=${Belt.Int.toString(state.mediumSigma)},lut=y='val*${state.medium}'[amedium];` ++
  `[mbroad]gblur=sigma=${Belt.Int.toString(state.broadSigma)},lut=y='val*${state.broad}'[abroad];` ++
  `color=c=${state.broadColor}:s=2048x2048:d=1,format=rgb24[cBroad];` ++
  `[cBroad][abroad]alphamerge[broad];` ++
  `color=c=${state.mediumColor}:s=2048x2048:d=1,format=rgb24[cMedium];` ++
  `[cMedium][amedium]alphamerge[medium];` ++
  `color=c=${state.tightColor}:s=2048x2048:d=1,format=rgb24[cTight];` ++
  `[cTight][atight]alphamerge[tightLayer];` ++
  `color=c=${state.innerColor}:s=2048x2048:d=1,format=rgb24[cInner];` ++
  `[cInner][ainner]alphamerge[innerLayer];` ++
  `color=c=${state.coreColor}:s=2048x2048:d=1,format=rgb24[cCore];` ++
  `[cCore][acore]alphamerge[coreLayer];` ++
  `[residue]format=rgba,colorchannelmixer=aa=${state.trace}[trace];` ++
  `[broad][medium]overlay=format=auto[x1];` ++
  `[x1][tightLayer]overlay=format=auto[x2];` ++
  `[x2][innerLayer]overlay=format=auto[x3];` ++
  `[x3][coreLayer]overlay=format=auto[x4];` ++
  `[x4][trace]overlay=format=auto,format=rgba[letter];` ++
  particleFilter(state, letter)

/* Peak magic is a qualitative phase change, not just a brighter ignition.
   The graphite scratches are merged into one continuous luminous envelope
   without changing the handwritten silhouette. A deeply eroded copy supplies
   the narrow white-hot center. Four deterministic particle scales create gold
   energy dust, brighter motes, and a few soft white flare points. */
let intermediateMagicFilter = (letter: string): string =>
  `[0:v]alphaextract,dilation,dilation,dilation,gblur=sigma=2,` ++
  `lut=y='if(gt(val,18),255,0)',` ++
  `split=11[mcore][mbody][mtight][minner][mmedium][mbroad][mcloud][mfine][mcoarse][mhot][mflare];` ++
  `[mcore]erosion,erosion,erosion,erosion,erosion,erosion,` ++
  `erosion,erosion,erosion,erosion,erosion,erosion,` ++
  `erosion,erosion,erosion,erosion,erosion,erosion[acore];` ++
  `[mbody]null[abody];` ++
  `[mtight]gblur=sigma=7,lut=y='clip(val*1.0,0,255)'[atight];` ++
  `[minner]gblur=sigma=18,lut=y='clip(val*1.0,0,255)'[ainner];` ++
  `[mmedium]gblur=sigma=65,lut=y='clip(val*1.0,0,255)'[amedium];` ++
  `[mbroad]gblur=sigma=160,lut=y='clip(val*0.82,0,255)'[abroad];` ++
  `color=c=0xD45B00:s=2048x2048:d=1,format=rgb24[cBroad];` ++
  `[cBroad][abroad]alphamerge[broad];` ++
  `[mcloud]gblur=sigma=150,lut=y='clip(val*5,0,255)'[cloudRegion];` ++
  `color=c=black:s=256x256:d=1,noise=alls=100:allf=u:all_seed=${cloudSeed(letter)},` ++
  `format=gray,lut=y='if(gt(val,48),clip((val-48)*16,0,210),0)',` ++
  `scale=2048:2048:flags=lanczos,gblur=sigma=12[cloudNoise];` ++
  `[cloudNoise][cloudRegion]blend=all_expr='A*B/255',` ++
  `lut=y='val*0.55',format=gray[cloudAlpha];` ++
  `color=c=0xE58A00:s=2048x2048:d=1,format=rgb24[cloudColor];` ++
  `[cloudColor][cloudAlpha]alphamerge[cloud];` ++
  `color=c=0xF58500:s=2048x2048:d=1,format=rgb24[cMedium];` ++
  `[cMedium][amedium]alphamerge[medium];` ++
  `color=c=0xFFC84A:s=2048x2048:d=1,format=rgb24[cInner];` ++
  `[cInner][ainner]alphamerge[inner];` ++
  `color=c=0xFFEB87:s=2048x2048:d=1,format=rgb24[cTight];` ++
  `[cTight][atight]alphamerge[tight];` ++
  `color=c=0xFFC62E:s=2048x2048:d=1,format=rgb24[cBody];` ++
  `[cBody][abody]alphamerge[body];` ++
  `color=c=0xFFFFF2:s=2048x2048:d=1,format=rgb24[cCore];` ++
  `[cCore][acore]alphamerge[core];` ++
  `[broad][cloud]overlay=format=auto[x0];` ++
  `[x0][medium]overlay=format=auto[x1];` ++
  `[x1][inner]overlay=format=auto[x2];` ++
  `[x2][tight]overlay=format=auto[x3];` ++
  `[x3][body]overlay=format=auto[x4];` ++
  `[x4][core]overlay=format=auto[letter];` ++
  `[mfine]gblur=sigma=140,lut=y='clip(val*5.0,0,255)'[fineRegion];` ++
  `color=c=black:s=1024x1024:d=1,noise=alls=100:allf=u:all_seed=${particleSeed(letter)},` ++
  `format=gray,lut=y='if(gt(val,50),clip((val-50)*30,0,255),0)',` ++
  `scale=2048:2048:flags=lanczos[fineNoise];` ++
  `[fineNoise][fineRegion]blend=all_expr='A*B/255',format=gray[fineAlpha];` ++
  `color=c=0xFFC848:s=2048x2048:d=1,format=rgb24[fineColor];` ++
  `[fineColor][fineAlpha]alphamerge[fineParticles];` ++
  `[mcoarse]gblur=sigma=150,lut=y='clip(val*4.8,0,255)'[coarseRegion];` ++
  `color=c=black:s=512x512:d=1,noise=alls=100:allf=u:all_seed=${coarseParticleSeed(letter)},` ++
  `format=gray,lut=y='if(gt(val,51),clip((val-51)*52,0,255),0)',` ++
  `scale=2048:2048:flags=lanczos,gblur=sigma=0.8[coarseNoise];` ++
  `[coarseNoise][coarseRegion]blend=all_expr='A*B/255',format=gray[coarseAlpha];` ++
  `color=c=0xFFD56A:s=2048x2048:d=1,format=rgb24[coarseColor];` ++
  `[coarseColor][coarseAlpha]alphamerge[coarseParticles];` ++
  `[mhot]gblur=sigma=110,lut=y='clip(val*5,0,255)'[hotRegion];` ++
  `color=c=black:s=256x256:d=1,noise=alls=100:allf=u:all_seed=${hotParticleSeed(letter)},` ++
  `format=gray,lut=y='if(gt(val,53),clip((val-53)*75,0,255),0)',` ++
  `scale=2048:2048:flags=lanczos,gblur=sigma=2[hotNoise];` ++
  `[hotNoise][hotRegion]blend=all_expr='A*B/255',format=gray[hotAlpha];` ++
  `color=c=0xFFF2B2:s=2048x2048:d=1,format=rgb24[hotColor];` ++
  `[hotColor][hotAlpha]alphamerge[hotParticles];` ++
  `[mflare]gblur=sigma=95,lut=y='clip(val*5,0,255)'[flareRegion];` ++
  `color=c=black:s=128x128:d=1,noise=alls=100:allf=u:all_seed=${flareParticleSeed(letter)},` ++
  `format=gray,lut=y='if(gt(val,56),255,0)',` ++
  `scale=2048:2048:flags=lanczos,gblur=sigma=5[flareNoise];` ++
  `[flareNoise][flareRegion]blend=all_expr='A*B/255',` ++
  `lut=y='val*0.72',format=gray[flareAlpha];` ++
  `color=c=0xFFFFF6:s=2048x2048:d=1,format=rgb24[flareColor];` ++
  `[flareColor][flareAlpha]alphamerge[flareParticles];` ++
  `[letter][fineParticles]overlay=format=auto[p1];` ++
  `[p1][coarseParticles]overlay=format=auto[p2];` ++
  `[p2][hotParticles]overlay=format=auto[p3];` ++
  `[p3][flareParticles]overlay=format=auto,format=rgba[peakRaw];` ++
  `[peakRaw]crop=1434:1434:307:307,` ++
  `pad=2048:2048:307:307:color=black@0,format=rgba[out]`

/* The reference reads as a soft incandescent body, not a white neon tube inside
   an orange outline. The approved stroke therefore stays continuous and broad:
   warm cream fills most of it, restrained white heat wanders inside it, and the
   edge dissolves directly into mottled amber bloom. Sparse clustered sparks sit
   inside that bloom rather than forming an even field of pixel dust. */
let finalMagicFilter = (letter: string): string =>
  `[0:v]alphaextract,split=3[rawMask][unifiedInput][rawCoreInput];` ++
  `[rawMask]dilation,dilation,gblur=sigma=3.0,` ++
  `lut=y='clip(val*1.25,0,255)',split=2[mtexture][mhotTexture];` ++
  `[unifiedInput]dilation,dilation,gblur=sigma=2.2,` ++
  `lut=y='if(gt(val,17),255,0)',` ++
  `split=13[mbody][mcore][mhotCore][mtight][minner][mmedium][mbroad][mcloud][mfine][mcoarse][mhot][mflare][mreserve];` ++
  `[mreserve]nullsink;` ++
  `color=c=black:s=64x64:d=1,noise=alls=100:allf=u:all_seed=${coreModulationSeed(letter)},` ++
  `format=gray,lut=y='clip(val*4.5,0,255)',scale=2048:2048:flags=lanczos,` ++
  `gblur=sigma=52,lut=y='clip((val-30)*3.2,0,255)',` ++
  `split=4[hbody][hcore][hhotTexture][hridge];` ++
  `[mbody]gblur=sigma=5.0[bodyShape];` ++
  `[bodyShape][hbody]blend=all_expr='A*(0.12+0.22*B/255)'[abody];` ++
  `[mcore]erosion,erosion,erosion,erosion,erosion,erosion,` ++
  `erosion,erosion,gblur=sigma=2.0,lut=y='val*0.08'[awarmBed];` ++
  `[mtexture][hcore]blend=all_expr='A*(0.04+0.72*B/255)'[acore];` ++
  `[mhotTexture]erosion,erosion,erosion,erosion,erosion,erosion,` ++
  `gblur=sigma=1.2[hotTextureShape];` ++
  `[hotTextureShape][hhotTexture]blend=all_expr='A*(0.03+0.55*B/255)'[ahotCore];` ++
  `[rawCoreInput]lut=y='if(gt(val,22),clip((val-22)*1.35,0,255),0)',` ++
  `gblur=sigma=0.15,split=3[traceBandInput][traceGlowInput][traceInput];` ++
  `[traceBandInput]dilation,dilation,dilation,dilation,` ++
  `gblur=sigma=0.20,lut=y='val*0.62'[ahotBand];` ++
  `[traceGlowInput]dilation,gblur=sigma=1.3,lut=y='val*0.42'[atraceGlow];` ++
  `[traceInput][hridge]blend=all_expr='A*(0.70+0.30*B/255)'[aridgeBase];` ++
  `color=c=black:s=512x512:d=1,noise=alls=100:allf=u:all_seed=${flareParticleSeed(letter)},` ++
  `format=gray,lut=y='clip(205+val*0.75,205,255)',` ++
  `scale=2048:2048:flags=lanczos,gblur=sigma=0.35[ridgeGrain];` ++
  `[aridgeBase][ridgeGrain]blend=all_expr='A*B/255'[aridge];` ++
  `[mhotCore]nullsink;` ++
  `[mtight]gblur=sigma=13,lut=y='val*0.78'[atight];` ++
  `[minner]gblur=sigma=28,lut=y='val*0.90'[ainner];` ++
  `[mmedium]gblur=sigma=82,lut=y='val*0.92'[amedium];` ++
  `[mbroad]gblur=sigma=168,lut=y='val*0.64'[abroad];` ++
  `color=c=0xB96800:s=2048x2048:d=1,format=rgb24[cBroad];` ++
  `[cBroad][abroad]alphamerge[broad];` ++
  `color=c=0xDE8704:s=2048x2048:d=1,format=rgb24[cMedium];` ++
  `[cMedium][amedium]alphamerge[medium];` ++
  `color=c=0xEFA21A:s=2048x2048:d=1,format=rgb24[cInner];` ++
  `[cInner][ainner]alphamerge[inner];` ++
  `color=c=0xFFC34D:s=2048x2048:d=1,format=rgb24[cTight];` ++
  `[cTight][atight]alphamerge[tight];` ++
  `[mcloud]gblur=sigma=135,lut=y='clip(val*4.2,0,255)'[cloudRegion];` ++
  `color=c=black:s=128x128:d=1,noise=alls=100:allf=u:all_seed=${cloudSeed(letter)},` ++
  `format=gray,lut=y='if(gt(val,38),clip((val-38)*15,0,255),0)',` ++
  `scale=2048:2048:flags=lanczos,gblur=sigma=15[cloudNoise];` ++
  `[cloudNoise][cloudRegion]blend=all_expr='A*B/255',lut=y='val*0.80'[cloudAlpha];` ++
  `color=c=0xD18B20:s=2048x2048:d=1,format=rgb24[cloudColor];` ++
  `[cloudColor][cloudAlpha]alphamerge[cloud];` ++
  `color=c=0xFFC248:s=2048x2048:d=1,format=rgb24[cBody];` ++
  `[cBody][abody]alphamerge[body];` ++
  `color=c=0xFFE197:s=2048x2048:d=1,format=rgb24[cWarmBed];` ++
  `[cWarmBed][awarmBed]alphamerge[warmBed];` ++
  `color=c=0xFFD66A:s=2048x2048:d=1,format=rgb24[cCore];` ++
  `[cCore][acore]alphamerge[core];` ++
  `color=c=0xFFEDAE:s=2048x2048:d=1,format=rgb24[cHotCore];` ++
  `[cHotCore][ahotCore]alphamerge[hotCore];` ++
  `color=c=0xFFF0B8:s=2048x2048:d=1,format=rgb24[cHotBand];` ++
  `[cHotBand][ahotBand]alphamerge[hotBand];` ++
  `color=c=0xFFB82A:s=2048x2048:d=1,format=rgb24[cTraceGlow];` ++
  `[cTraceGlow][atraceGlow]alphamerge[traceGlow];` ++
  `color=c=0xFFFFF2:s=2048x2048:d=1,format=rgb24[cRidge];` ++
  `[cRidge][aridge]alphamerge[ridge];` ++
  `[broad][medium]overlay=format=auto[x0];` ++
  `[x0][cloud]overlay=format=auto[x1];` ++
  `[x1][inner]overlay=format=auto[x2];` ++
  `[x2][tight]overlay=format=auto[x3];` ++
  `[x3][body]overlay=format=auto[x4];` ++
  `[x4][warmBed]overlay=format=auto[x5];` ++
  `[x5][core]overlay=format=auto[x6];` ++
  `[x6][hotCore]overlay=format=auto[x7];` ++
  `[x7][traceGlow]overlay=format=auto[x8];` ++
  `[x8][hotBand]overlay=format=auto[x9];` ++
  `[x9][ridge]overlay=format=auto[letter];` ++
  `[mfine]gblur=sigma=125,lut=y='clip(val*4.5,0,255)'[fineRegion];` ++
  `color=c=black:s=512x512:d=1,noise=alls=100:allf=u:all_seed=${particleSeed(letter)},` ++
  `format=gray,lut=y='if(gt(val,46),clip((val-46)*26,0,170),0)',` ++
  `scale=2048:2048:flags=lanczos,gblur=sigma=0.45[fineNoise];` ++
  `[fineNoise][fineRegion]blend=all_expr='A*B/255',lut=y='val*0.48',format=gray[fineAlpha];` ++
  `color=c=0xF1A72A:s=2048x2048:d=1,format=rgb24[fineColor];` ++
  `[fineColor][fineAlpha]alphamerge[fineParticles];` ++
  `[mcoarse]gblur=sigma=115,lut=y='clip(val*4.2,0,255)'[coarseRegion];` ++
  `color=c=black:s=256x256:d=1,noise=alls=100:allf=u:all_seed=${coarseParticleSeed(letter)},` ++
  `format=gray,lut=y='if(gt(val,40),clip((val-40)*21,0,220),0)',` ++
  `scale=2048:2048:flags=lanczos,gblur=sigma=0.7[coarseNoise];` ++
  `[coarseNoise][coarseRegion]blend=all_expr='A*B/255',lut=y='val*0.72',format=gray[coarseAlpha];` ++
  `color=c=0xF7B52B:s=2048x2048:d=1,format=rgb24[coarseColor];` ++
  `[coarseColor][coarseAlpha]alphamerge[coarseParticles];` ++
  `[mhot]gblur=sigma=100,lut=y='clip(val*4.0,0,255)'[hotRegion];` ++
  `color=c=black:s=128x128:d=1,noise=alls=100:allf=u:all_seed=${hotParticleSeed(letter)},` ++
  `format=gray,lut=y='if(gt(val,42),clip((val-42)*25,0,235),0)',` ++
  `scale=2048:2048:flags=lanczos,gblur=sigma=1.0[hotNoise];` ++
  `[hotNoise][hotRegion]blend=all_expr='A*B/255',lut=y='val*0.78',format=gray[hotAlpha];` ++
  `color=c=0xFFD066:s=2048x2048:d=1,format=rgb24[hotColor];` ++
  `[hotColor][hotAlpha]alphamerge[hotParticles];` ++
  `[mflare]gblur=sigma=90,lut=y='clip(val*3.8,0,255)'[flareRegion];` ++
  `color=c=black:s=96x96:d=1,noise=alls=100:allf=u:all_seed=${flareParticleSeed(letter)},` ++
  `format=gray,lut=y='if(gt(val,53),255,0)',` ++
  `scale=2048:2048:flags=lanczos,gblur=sigma=3.5[flareNoise];` ++
  `[flareNoise][flareRegion]blend=all_expr='A*B/255',` ++
  `lut=y='val*0.66',format=gray[flareAlpha];` ++
  `color=c=0xFFFFE9:s=2048x2048:d=1,format=rgb24[flareColor];` ++
  `[flareColor][flareAlpha]alphamerge[flareParticles];` ++
  `[fineParticles][coarseParticles]overlay=format=auto[p1];` ++
  `[p1][hotParticles]overlay=format=auto[p2];` ++
  `[p2][letter]overlay=format=auto[p3];` ++
  `[p3][flareParticles]overlay=format=auto,format=rgba[magicRaw];` ++
  `[magicRaw]crop=1434:1434:307:307,` ++
  `pad=2048:2048:307:307:color=black@0,format=rgba[out]`

type masterCell = {
  letter: string,
  centerX: int,
  baselineY: int,
}

/* Coordinates are measured once from the locked 1672 x 941 master sheet.
   Every cell is sampled at the same size and scale. The row baseline maps to
   y=1430; width remains natural, and no per-letter stretching is allowed. */
let masterCells = [
  {letter: "А", centerX: 314, baselineY: 145},
  {letter: "Б", centerX: 521, baselineY: 145},
  {letter: "В", centerX: 730, baselineY: 145},
  {letter: "Г", centerX: 933, baselineY: 145},
  {letter: "Д", centerX: 1144, baselineY: 145},
  {letter: "Е", centerX: 1350, baselineY: 145},
  {letter: "Ё", centerX: 314, baselineY: 299},
  {letter: "Ж", centerX: 521, baselineY: 299},
  {letter: "З", centerX: 730, baselineY: 299},
  {letter: "И", centerX: 933, baselineY: 299},
  {letter: "Й", centerX: 1144, baselineY: 299},
  {letter: "К", centerX: 1350, baselineY: 299},
  {letter: "Л", centerX: 314, baselineY: 454},
  {letter: "М", centerX: 521, baselineY: 454},
  {letter: "Н", centerX: 730, baselineY: 454},
  {letter: "О", centerX: 933, baselineY: 454},
  {letter: "П", centerX: 1144, baselineY: 454},
  {letter: "Р", centerX: 1350, baselineY: 454},
  {letter: "С", centerX: 314, baselineY: 607},
  {letter: "Т", centerX: 521, baselineY: 607},
  {letter: "У", centerX: 730, baselineY: 607},
  {letter: "Ф", centerX: 933, baselineY: 607},
  {letter: "Х", centerX: 1144, baselineY: 607},
  {letter: "Ц", centerX: 1350, baselineY: 607},
  {letter: "Ч", centerX: 314, baselineY: 756},
  {letter: "Ш", centerX: 521, baselineY: 756},
  {letter: "Щ", centerX: 730, baselineY: 756},
  {letter: "Ъ", centerX: 933, baselineY: 756},
  {letter: "Ы", centerX: 1144, baselineY: 756},
  {letter: "Ь", centerX: 1350, baselineY: 756},
  {letter: "Э", centerX: 627, baselineY: 910},
  {letter: "Ю", centerX: 835, baselineY: 910},
  {letter: "Я", centerX: 1044, baselineY: 910},
]

let graphiteExtractionFilter = (cell: masterCell): string => {
  let cropX = Belt.Int.toString(cell.centerX - 95)
  let cropY = Belt.Int.toString(cell.baselineY - 135)
  `[0:v]crop=190:150:${cropX}:${cropY},format=gray,split[ink][background];` ++
  `[background]gblur=sigma=16[localPaper];` ++
  `[localPaper][ink]blend=all_expr='clip(A-B,0,255)',` ++
  `lut=y='if(gt(val,18),clip((val-18)*2.35,0,255),0)',` ++
  `scale=1368:1080:flags=lanczos,gblur=sigma=0.18,` ++
  `lut=y='clip(val*1.12,0,255)'[alpha];` ++
  `color=c=0x424242:s=1368x1080:d=1,format=rgb24[graphite];` ++
  `[graphite][alpha]alphamerge,` ++
  `pad=2048:2048:340:458:color=black@0,format=rgba[out]`
}

let extractGraphite = (cell: masterCell): unit => {
  ensureDirPath(path("assets/graphite"))
  runOrFail(
    ~cmd="ffmpeg",
    ~args=[
      "-y",
      "-i",
      root ++ "/masters/full_alphabet_reference_v1.png",
      "-filter_complex",
      graphiteExtractionFilter(cell),
      "-map",
      "[out]",
      "-frames:v",
      "1",
      root ++ "/assets/graphite/" ++ cell.letter ++ ".png",
    ],
    ~label="graphite extraction/" ++ cell.letter,
  )
}

let extractRemainingGraphite = (): unit => {
  masterCells->Belt.Array.forEach(cell => {
    if remainingLetters->Belt.Array.some(letter => letter == cell.letter) {
      extractGraphite(cell)
    }
  })
}

let buildPaper = (): unit => {
  ensureDirPath(path("paper"))
  runOrFail(
    ~cmd="ffmpeg",
    ~args=[
      "-y",
      "-f",
      "lavfi",
      "-i",
      "nullsrc=s=3840x2160",
      "-vf",
      "geq=r=244:g=225:b=192,format=rgb24",
      "-frames:v",
      "1",
      root ++ "/paper/canonical_flat_paper_16x9.png",
    ],
    ~label="canonical paper",
  )
}

let buildState = (letter: string, state: glowState): unit => {
  ensureDirPath(path("assets/" ++ state.dir))
  let source = root ++ "/assets/graphite/" ++ letter ++ ".png"
  let output = root ++ "/assets/" ++ state.dir ++ "/" ++ letter ++ ".png"
  let filter = switch state.dir {
  | "ignite_90" => intermediateMagicFilter(letter)
  | "magic" => finalMagicFilter(letter)
  | _ => filterForState(state, letter)
  }
  runOrFail(
    ~cmd="ffmpeg",
    ~args=[
      "-y",
      "-i",
      source,
      "-filter_complex",
      filter,
      "-map",
      "[out]",
      "-frames:v",
      "1",
      output,
    ],
    ~label=state.dir ++ "/" ++ letter,
  )
}

let restoreCanonicalMagic = (entry: string): unit => {
  if !exists(Path(canonicalMagicArchive)) {
    fail("missing frozen Episode 1 magic archive: " ++ canonicalMagicArchive)
  }
  ensureDirPath(path("assets/magic"))
  runOrFail(
    ~cmd="bsdtar",
    ~args=["-xf", canonicalMagicArchive, "-C", root, entry],
    ~label="restore frozen Episode 1 magic assets",
  )
}

let build = (): unit => {
  buildPaper()
  episode1Letters->Belt.Array.forEach(letter =>
    states->Belt.Array.forEach(state =>
      if state.dir != "magic" {
        buildState(letter, state)
      }
    )
  )
  restoreCanonicalMagic("assets/magic")
  Js.log("Built canonical paper and 32 ignition assets; restored 8 locked full-magic assets.")
}

let buildFullAlphabet = (): unit => {
  buildPaper()
  extractRemainingGraphite()
  remainingLetters->Belt.Array.forEach(letter =>
    states->Belt.Array.forEach(state => buildState(letter, state))
  )
  restoreCanonicalMagic("assets/magic")
  Js.log(
    "Built 150 new assets for the remaining 25 letters and restored the eight locked Episode 1 magic assets.",
  )
}

/* Production A is locked to the same accepted v1 treatment as the other seven
   Episode 1 letters. Experimental A treatments belong in qa/glow_lab only. */
let buildMagicA = (): unit => {
  restoreCanonicalMagic("assets/magic/А.png")
  Js.log("Restored canonical Episode 1 full-magic А.")
}

let compareMagicA = (): unit => {
  ensureDirPath(path("previews"))
  let reference = root ++ "/qa/reference/approved_peak_magic_A.png"
  let candidate = root ++ "/assets/magic/А.png"
  let paper = root ++ "/paper/canonical_flat_paper_16x9.png"
  let output = root ++ "/previews/peak_magic_reference_vs_matched_A.png"
  if !exists(Path(reference)) {
    fail("missing frozen peak-magic reference: " ++ reference)
  }
  runOrFail(
    ~cmd="ffmpeg",
    ~args=[
      "-y",
      "-i",
      reference,
      "-i",
      candidate,
      "-i",
      paper,
      "-filter_complex",
      "[0:v]scale=400:520:flags=lanczos[reference];" ++
      "[1:v]crop=1050:1250:499:360,scale=400:476:flags=lanczos,format=rgba[glyph];" ++
      "[2:v]scale=400:520:flags=lanczos[paper];" ++
      "[paper][glyph]overlay=0:22:format=auto[candidate];" ++
      "[reference][candidate]hstack=inputs=2,format=rgb24[out]",
      "-map",
      "[out]",
      "-frames:v",
      "1",
      output,
    ],
    ~label="matched А comparison",
  )
  Js.log("Built fixed matched-scale А comparison: " ++ output)
}

let buildBackgroundPreview = (): unit => {
  ensureDirPath(path("previews"))
  let output = root ++ "/previews/magic_ep1_light_vs_dark_brown.png"
  let filter =
    `[0:v]crop=1434:1434:307:307,scale=300:300:flags=lanczos,format=rgba,split=2[l0][d0];` ++
    `[1:v]crop=1434:1434:307:307,scale=300:300:flags=lanczos,format=rgba,split=2[l1][d1];` ++
    `[2:v]crop=1434:1434:307:307,scale=300:300:flags=lanczos,format=rgba,split=2[l2][d2];` ++
    `[3:v]crop=1434:1434:307:307,scale=300:300:flags=lanczos,format=rgba,split=2[l3][d3];` ++
    `[4:v]crop=1434:1434:307:307,scale=300:300:flags=lanczos,format=rgba,split=2[l4][d4];` ++
    `[5:v]crop=1434:1434:307:307,scale=300:300:flags=lanczos,format=rgba,split=2[l5][d5];` ++
    `[6:v]crop=1434:1434:307:307,scale=300:300:flags=lanczos,format=rgba,split=2[l6][d6];` ++
    `[7:v]crop=1434:1434:307:307,scale=300:300:flags=lanczos,format=rgba,split=2[l7][d7];` ++
    `color=c=0xF4E1C0:s=1400x780:d=1,format=rgb24[light0];` ++
    `color=c=0x2B170F:s=1400x780:d=1,format=rgb24[dark0];` ++
    `[light0][l0]overlay=25:105:format=auto[light1];[light1][l1]overlay=365:105:format=auto[light2];` ++
    `[light2][l2]overlay=705:105:format=auto[light3];[light3][l3]overlay=1045:105:format=auto[light4];` ++
    `[light4][l4]overlay=25:445:format=auto[light5];[light5][l5]overlay=365:445:format=auto[light6];` ++
    `[light6][l6]overlay=705:445:format=auto[light7];[light7][l7]overlay=1045:445:format=auto[light8];` ++
    `[dark0][d0]overlay=25:105:format=auto[dark1];[dark1][d1]overlay=365:105:format=auto[dark2];` ++
    `[dark2][d2]overlay=705:105:format=auto[dark3];[dark3][d3]overlay=1045:105:format=auto[dark4];` ++
    `[dark4][d4]overlay=25:445:format=auto[dark5];[dark5][d5]overlay=365:445:format=auto[dark6];` ++
    `[dark6][d6]overlay=705:445:format=auto[dark7];[dark7][d7]overlay=1045:445:format=auto[dark8];` ++
    `[light8][dark8]vstack=inputs=2,format=rgb24[out]`
  runOrFail(
    ~cmd="ffmpeg",
    ~args=[
      "-y",
      "-i", root ++ "/assets/magic/А.png",
      "-i", root ++ "/assets/magic/О.png",
      "-i", root ++ "/assets/magic/М.png",
      "-i", root ++ "/assets/magic/С.png",
      "-i", root ++ "/assets/magic/К.png",
      "-i", root ++ "/assets/magic/Т.png",
      "-i", root ++ "/assets/magic/Л.png",
      "-i", root ++ "/assets/magic/Б.png",
      "-filter_complex", filter,
      "-map", "[out]",
      "-frames:v", "1",
      output,
    ],
    ~label="light and dark-brown letter preview",
  )
  Js.log("Built light and dark-brown Episode 1 letter preview: " ++ output)
}

let twoDigit = (value: int): string =>
  value < 10 ? "0" ++ Belt.Int.toString(value) : Belt.Int.toString(value)

let buildContactSheet = (~state: string, ~background: string, ~output: string): unit => {
  ensureDirPath(path("review"))
  let args: array<string> = ["-y"]
  letters->Belt.Array.forEach(letter => {
    args->Js.Array2.push("-i")->ignore
    args->Js.Array2.push(root ++ "/assets/" ++ state ++ "/" ++ letter ++ ".png")->ignore
  })
  let tiles = letters
    ->Belt.Array.mapWithIndex((index, _) => {
      let i = Belt.Int.toString(index)
      `[${i}:v]scale=400:400:flags=lanczos,format=rgba[g${i}];` ++
      `color=c=${background}:s=400x400:d=1,format=rgb24[b${i}];` ++
      `[b${i}][g${i}]overlay=format=auto[t${i}];`
    })
    ->Js.Array2.joinWith("")
  let stackInputs = letters
    ->Belt.Array.mapWithIndex((index, _) => `[t${Belt.Int.toString(index)}]`)
    ->Js.Array2.joinWith("")
  let layout = letters
    ->Belt.Array.mapWithIndex((index, _) => {
      let row = index / 6
      let column = index - row * 6
      Belt.Int.toString(column * 400) ++ "_" ++ Belt.Int.toString(row * 400)
    })
    ->Js.Array2.joinWith("|")
  let filter =
    tiles ++ stackInputs ++
    `xstack=inputs=33:layout=${layout}:fill=${background},format=rgb24[out]`
  args->Js.Array2.push("-filter_complex")->ignore
  args->Js.Array2.push(filter)->ignore
  args->Js.Array2.push("-map")->ignore
  args->Js.Array2.push("[out]")->ignore
  args->Js.Array2.push("-frames:v")->ignore
  args->Js.Array2.push("1")->ignore
  args->Js.Array2.push(root ++ "/review/" ++ output)->ignore
  runOrFail(~cmd="ffmpeg", ~args, ~label="full alphabet contact sheet " ++ state)
}

let buildReviewTile = (letter: string, index: int): unit => {
  ensureDirPath(path("review/thumbs"))
  let number = twoDigit(index + 1)
  runOrFail(
    ~cmd="ffmpeg",
    ~args=[
      "-y",
      "-i", root ++ "/assets/graphite/" ++ letter ++ ".png",
      "-i", root ++ "/assets/magic/" ++ letter ++ ".png",
      "-filter_complex",
      `[0:v]scale=512:512:flags=lanczos,format=rgba[g];` ++
      `[1:v]scale=512:512:flags=lanczos,format=rgba,split=2[ml][md];` ++
      `color=c=0xF4E1C0:s=512x512:d=1,format=rgb24[p0];` ++
      `color=c=0xF4E1C0:s=512x512:d=1,format=rgb24[p1];` ++
      `color=c=0x2B170F:s=512x512:d=1,format=rgb24[p2];` ++
      `[p0][g]overlay=format=auto[graphite];` ++
      `[p1][ml]overlay=format=auto[light];` ++
      `[p2][md]overlay=format=auto[dark];` ++
      `[graphite][light][dark]hstack=inputs=3,format=rgb24[out]`,
      "-map", "[out]",
      "-frames:v", "1",
      root ++ "/review/thumbs/" ++ number ++ ".png",
    ],
    ~label="review tile " ++ letter,
  )
}

let buildFullReview = (): unit => {
  ensureDirPath(path("review"))
  letters->Belt.Array.forEachWithIndex((index, letter) => buildReviewTile(letter, index))
  buildContactSheet(
    ~state="graphite",
    ~background="0xF4E1C0",
    ~output="graphite_full_alphabet_on_paper.png",
  )
  buildContactSheet(
    ~state="magic",
    ~background="0xF4E1C0",
    ~output="magic_full_alphabet_on_paper.png",
  )
  buildContactSheet(
    ~state="magic",
    ~background="0x2B170F",
    ~output="magic_full_alphabet_on_dark_brown.png",
  )
  let cards = letters
    ->Belt.Array.mapWithIndex((index, letter) => {
      let number = twoDigit(index + 1)
      `<article class="card"><header><span>${number}</span><h2>${letter}</h2></header>` ++
      `<a href="../assets/magic/${letter}.png" target="_blank">` ++
      `<img src="thumbs/${number}.png" alt="${letter}: graphite, magic on paper, magic on dark brown" loading="lazy" decoding="async"></a>` ++
      `<div class="labels"><b>GRAPHITE</b><b>MAGIC / PAPER</b><b>MAGIC / DARK</b></div>` ++
      `<nav><a href="../assets/graphite/${letter}.png" target="_blank">Graphite PNG</a>` ++
      `<a href="../assets/magic/${letter}.png" target="_blank">Magic PNG</a></nav></article>`
    })
    ->Js.Array2.joinWith("\n")
  let html =
    `<!doctype html><html lang="en"><head><meta charset="utf-8">` ++
    `<meta name="viewport" content="width=device-width,initial-scale=1">` ++
    `<title>Frosya — Full Composable Russian Alphabet</title><style>` ++
    `:root{--paper:#f4e1c0;--ink:#382517;--line:#c99850;--card:#fffaf0}` ++
    `*{box-sizing:border-box}body{margin:0;background:#ead6b4;color:var(--ink);font-family:ui-sans-serif,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}` ++
    `.intro{padding:22px max(16px,4vw)}h1{margin:0 0 6px;font-size:clamp(26px,5vw,44px)}.intro p{margin:0;max-width:900px;line-height:1.45}` ++
    `.sheets{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,620px),1fr));gap:18px;padding:0 max(16px,4vw) 24px}.sheet{margin:0;background:var(--card);border:2px solid var(--line);border-radius:16px;padding:12px}.sheet img{display:block;width:100%;height:auto;border-radius:8px}.sheet figcaption{font-weight:800;margin:0 0 9px}` ++
    `main{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,300px),1fr));gap:16px;padding:0 max(12px,3vw) 34px}.card{background:var(--card);border:2px solid var(--line);border-radius:16px;padding:12px;box-shadow:0 7px 20px rgba(79,48,19,.10)}.card header{display:flex;align-items:center;gap:12px;margin-bottom:8px}.card header span{display:grid;place-items:center;width:48px;height:38px;border-radius:9px;background:#4b321d;color:#fff;font-weight:850}.card h2{font-size:30px;margin:0}.card img{display:block;width:100%;height:auto;border-radius:9px;border:1px solid #d8b77f}.labels{display:grid;grid-template-columns:repeat(3,1fr);gap:4px;margin-top:7px;text-align:center;font-size:10px;letter-spacing:.05em}.card nav{display:flex;gap:8px;margin-top:10px}.card nav a{flex:1;text-align:center;padding:8px;border-radius:8px;background:#fff0d4;border:1px solid #b9833f;color:#4b321d;font-weight:750;text-decoration:none}` ++
    `@media(max-width:600px){.intro{padding:14px 12px}.sheets{padding:0 10px 16px}.sheet{padding:8px}main{grid-template-columns:1fr;padding:0 10px 24px}.card{padding:10px}}` ++
    `</style></head><body><section class="intro"><h1>Frosya’s full 33-letter alphabet</h1>` ++
    `<p>Canonical order. The eight approved Episode 1 letters remain locked; the other 25 come from the approved master sheet and use the same deterministic ignition treatment.</p></section>` ++
    `<section class="sheets">` ++
    `<figure class="sheet"><figcaption>Graphite · canonical paper</figcaption><a href="graphite_full_alphabet_on_paper.png" target="_blank"><img src="graphite_full_alphabet_on_paper.png" alt="Full graphite Russian alphabet"></a></figure>` ++
    `<figure class="sheet"><figcaption>Full magic · canonical paper</figcaption><a href="magic_full_alphabet_on_paper.png" target="_blank"><img src="magic_full_alphabet_on_paper.png" alt="Full magical Russian alphabet on paper"></a></figure>` ++
    `<figure class="sheet"><figcaption>Full magic · dark brown</figcaption><a href="magic_full_alphabet_on_dark_brown.png" target="_blank"><img src="magic_full_alphabet_on_dark_brown.png" alt="Full magical Russian alphabet on dark brown"></a></figure>` ++
    `</section><main>${cards}</main></body></html>`
  writeText(path("review/index.html"), html)
  Js.log("Built full 33-letter review gallery: " ++ root ++ "/review/index.html")
}

/* Peak-glow calibration is isolated from the production asset. Every lab
   candidate shares the same fused graphite body, bloom, particles, paper,
   registration, and scale. Only the inner heat construction varies. This
   prevents a core adjustment from silently changing the rest of the look. */
type glowLabVariant = {
  slug: string,
  coreFloor: string,
  coreRange: string,
  coreAlpha: string,
  highlightAlpha: string,
}

let glowLabVariants = [
  {
    slug: "01_continuous_hot_band",
    coreFloor: "220",
    coreRange: "0.14",
    coreAlpha: "0.94",
    highlightAlpha: "0.16",
  },
  {
    slug: "02_layered_white_ridges",
    coreFloor: "145",
    coreRange: "0.46",
    coreAlpha: "0.76",
    highlightAlpha: "0.88",
  },
  {
    slug: "03_broken_incandescent_heat",
    coreFloor: "75",
    coreRange: "0.72",
    coreAlpha: "0.84",
    highlightAlpha: "0.58",
  },
]

let glowLabFilter = (variant: glowLabVariant): string =>
  `[0:v]alphaextract,split=2[rawBody][rawHighlight];` ++
  `[rawBody]lut=y='if(gt(val,22),255,0)',` ++
  `dilation,dilation,dilation,dilation,dilation,dilation,` ++
  `erosion,erosion,erosion,erosion,erosion,erosion,` ++
  `split=7[mBody][mHotInput][mCore][mTight][mMedium][mBroad][mParticle];` ++
  `[mBody]gblur=sigma=2.2,lut=y='val*0.58'[aBody];` ++
  `[mHotInput]erosion,erosion,` ++
  `split=2[mHot][mHotClip];` ++
  `[mHot]lut=y='val*0.92'[aHot];` ++
  `[mCore]erosion,erosion,erosion,erosion,erosion,erosion[coreShape];` ++
  `color=c=black:s=64x64:d=1,noise=alls=100:allf=u:all_seed=407,` ++
  `format=gray,lut=y='clip(${variant.coreFloor}+val*${variant.coreRange},0,255)',` ++
  `scale=2048:2048:flags=lanczos,gblur=sigma=14[coreHeat];` ++
  `[coreShape][coreHeat]blend=all_expr='A*B/255',` ++
  `lut=y='val*${variant.coreAlpha}'[aCore];` ++
  `[rawHighlight]lut=y='if(gt(val,38),clip((val-38)*1.55,0,255),0)'[rawHot];` ++
  `[rawHot][mHotClip]blend=all_expr='A*B/255',` ++
  `lut=y='val*${variant.highlightAlpha}'[aHighlight];` ++
  `[mTight]gblur=sigma=10,lut=y='val*0.78'[aTight];` ++
  `[mMedium]gblur=sigma=36,lut=y='val*0.55'[aMedium];` ++
  `[mBroad]gblur=sigma=100,lut=y='val*0.28'[aBroad];` ++
  `[mParticle]gblur=sigma=82,lut=y='clip(val*4.0,0,255)',` ++
  `split=3[fineRegion][sparkRegion][glintRegion];` ++
  `color=c=black:s=512x512:d=1,noise=alls=100:allf=u:all_seed=211,` ++
  `format=gray,lut=y='if(gt(val,47),clip((val-47)*27,0,180),0)',` ++
  `scale=2048:2048:flags=lanczos,gblur=sigma=0.45[fineNoise];` ++
  `[fineNoise][fineRegion]blend=all_expr='A*B/255',` ++
  `lut=y='val*0.66'[aFine];` ++
  `color=c=black:s=256x256:d=1,noise=alls=100:allf=u:all_seed=307,` ++
  `format=gray,lut=y='if(gt(val,43),clip((val-43)*24,0,225),0)',` ++
  `scale=2048:2048:flags=lanczos,gblur=sigma=0.85[sparkNoise];` ++
  `[sparkNoise][sparkRegion]blend=all_expr='A*B/255',` ++
  `lut=y='val*0.76'[aSpark];` ++
  `color=c=black:s=96x96:d=1,noise=alls=100:allf=u:all_seed=503,` ++
  `format=gray,lut=y='if(gt(val,54),255,0)',` ++
  `scale=2048:2048:flags=lanczos,gblur=sigma=1.7[glintNoise];` ++
  `[glintNoise][glintRegion]blend=all_expr='A*B/255',` ++
  `lut=y='val*0.70'[aGlint];` ++
  `color=c=0xD97805:s=2048x2048:d=1,format=rgb24[cBroad];` ++
  `[cBroad][aBroad]alphamerge[broad];` ++
  `color=c=0xED930F:s=2048x2048:d=1,format=rgb24[cMedium];` ++
  `[cMedium][aMedium]alphamerge[medium];` ++
  `color=c=0xFFC03A:s=2048x2048:d=1,format=rgb24[cTight];` ++
  `[cTight][aTight]alphamerge[tight];` ++
  `color=c=0xFFC247:s=2048x2048:d=1,format=rgb24[cBody];` ++
  `[cBody][aBody]alphamerge[body];` ++
  `color=c=0xFFE39B:s=2048x2048:d=1,format=rgb24[cHot];` ++
  `[cHot][aHot]alphamerge[hot];` ++
  `color=c=0xFFF7DD:s=2048x2048:d=1,format=rgb24[cCore];` ++
  `[cCore][aCore]alphamerge[core];` ++
  `color=c=0xFFFFFF:s=2048x2048:d=1,format=rgb24[cHighlight];` ++
  `[cHighlight][aHighlight]alphamerge[highlight];` ++
  `color=c=0xF2A31F:s=2048x2048:d=1,format=rgb24[cFine];` ++
  `[cFine][aFine]alphamerge[fine];` ++
  `color=c=0xFFC64A:s=2048x2048:d=1,format=rgb24[cSpark];` ++
  `[cSpark][aSpark]alphamerge[spark];` ++
  `color=c=0xFFF6CC:s=2048x2048:d=1,format=rgb24[cGlint];` ++
  `[cGlint][aGlint]alphamerge[glint];` ++
  `[broad][medium]overlay=format=auto[x0];` ++
  `[x0][tight]overlay=format=auto[x1];` ++
  `[x1][body]overlay=format=auto[x2];` ++
  `[x2][hot]overlay=format=auto[x3];` ++
  `[x3][core]overlay=format=auto[x4];` ++
  `[x4][highlight]overlay=format=auto[x5];` ++
  `[x5][fine]overlay=format=auto[x6];` ++
  `[x6][spark]overlay=format=auto[x7];` ++
  `[x7][glint]overlay=format=auto,format=rgba[labRaw];` ++
  `[labRaw]crop=1434:1434:307:307,` ++
  `pad=2048:2048:307:307:color=black@0,format=rgba[out]`

let buildGlowLabA = (): unit => {
  ensureDirPath(path("qa/glow_lab"))
  let source = root ++ "/assets/graphite/А.png"
  glowLabVariants->Belt.Array.forEach(variant =>
    runOrFail(
      ~cmd="ffmpeg",
      ~args=[
        "-y",
        "-i",
        source,
        "-filter_complex",
        glowLabFilter(variant),
        "-map",
        "[out]",
        "-frames:v",
        "1",
        root ++ "/qa/glow_lab/" ++ variant.slug ++ ".png",
      ],
      ~label="glow lab " ++ variant.slug,
    )
  )
  let reference = root ++ "/qa/reference/approved_peak_magic_A.png"
  let paper = root ++ "/paper/canonical_flat_paper_16x9.png"
  let output = root ++ "/qa/glow_lab/A_core_glow_lab_numbered.png"
  runOrFail(
    ~cmd="ffmpeg",
    ~args=[
      "-y",
      "-i",
      reference,
      "-i",
      root ++ "/qa/glow_lab/01_continuous_hot_band.png",
      "-i",
      root ++ "/qa/glow_lab/02_layered_white_ridges.png",
      "-i",
      root ++ "/qa/glow_lab/03_broken_incandescent_heat.png",
      "-i",
      paper,
      "-filter_complex",
      "[0:v]scale=400:520:flags=lanczos[reference];" ++
      "[4:v]scale=400:520:flags=lanczos,split=3[p1][p2][p3];" ++
      "[1:v]crop=1050:1250:499:360,scale=400:476:flags=lanczos,format=rgba[g1];" ++
      "[p1][g1]overlay=0:22:format=auto," ++
      "drawbox=x=12:y=12:w=18:h=18:color=0x3B2815@0.85:t=fill[c1];" ++
      "[2:v]crop=1050:1250:499:360,scale=400:476:flags=lanczos,format=rgba[g2];" ++
      "[p2][g2]overlay=0:22:format=auto," ++
      "drawbox=x=12:y=12:w=18:h=18:color=0x3B2815@0.85:t=fill," ++
      "drawbox=x=36:y=12:w=18:h=18:color=0x3B2815@0.85:t=fill[c2];" ++
      "[3:v]crop=1050:1250:499:360,scale=400:476:flags=lanczos,format=rgba[g3];" ++
      "[p3][g3]overlay=0:22:format=auto," ++
      "drawbox=x=12:y=12:w=18:h=18:color=0x3B2815@0.85:t=fill," ++
      "drawbox=x=36:y=12:w=18:h=18:color=0x3B2815@0.85:t=fill," ++
      "drawbox=x=60:y=12:w=18:h=18:color=0x3B2815@0.85:t=fill[c3];" ++
      "[reference][c1]hstack=inputs=2[top];" ++
      "[c2][c3]hstack=inputs=2[bottom];" ++
      "[top][bottom]vstack=inputs=2,format=rgb24[out]",
      "-map",
      "[out]",
      "-frames:v",
      "1",
      output,
    ],
    ~label="numbered glow lab sheet",
  )
  Js.log("Built locked-layer А core glow lab: " ++ output)
}

type lineupEntry = {
  number: string,
  title: string,
  image: string,
  compareWithReference: bool,
}

let lineupEntries = [
  {number: "01", title: "Flat cream — FAIL", image: "../iterations/A_01_comparison_FAIL.png", compareWithReference: false},
  {number: "02", title: "Clean gold — CLOSER / FAIL", image: "../iterations/A_02_comparison_CLOSER_FAIL.png", compareWithReference: false},
  {number: "03", title: "Exposed graphite — FAIL", image: "../iterations/A_03_comparison_FAIL.png", compareWithReference: false},
  {number: "04", title: "Fused spark — CLOSER / FAIL", image: "../iterations/A_04_comparison_CLOSER_FAIL.png", compareWithReference: false},
  {number: "05", title: "Intact warm — CLOSER / FAIL", image: "../iterations/A_05_comparison_CLOSER_FAIL.png", compareWithReference: false},
  {number: "06", title: "Richer heat — CLOSER / FAIL", image: "../iterations/A_06_comparison_CLOSER_FAIL.png", compareWithReference: false},
  {number: "07", title: "Gold field — CLOSER / FAIL", image: "../iterations/A_07_comparison_CLOSER_FAIL.png", compareWithReference: false},
  {number: "08", title: "Hot ridge — CLOSER / FAIL", image: "../iterations/A_08_comparison_CLOSER_FAIL.png", compareWithReference: false},
  {number: "09", title: "Three depths — CLOSER / FAIL", image: "../iterations/A_09_comparison_CLOSER_FAIL.png", compareWithReference: false},
  {number: "10", title: "Variable heat — CLOSER / FAIL", image: "../iterations/A_10_comparison_CLOSER_FAIL.png", compareWithReference: false},
  {number: "11", title: "Beaded hotspots — FAIL", image: "../iterations/A_11_comparison_FAIL.png", compareWithReference: false},
  {number: "12", title: "Earlier pending candidate", image: "../iterations/A_12_comparison_PASS_PENDING_USER.png", compareWithReference: false},
  {number: "13", title: "Blurry — FAIL", image: "../iterations/A_13_comparison_blurry_FAIL.png", compareWithReference: false},
  {number: "14", title: "Sharp neon — FAIL", image: "../iterations/A_14_comparison_sharp_neon_FAIL.png", compareWithReference: false},
  {number: "15", title: "Sharp core / fog body — FAIL", image: "../iterations/A_15_comparison_sharp_core_fog_body_FAIL.png", compareWithReference: false},
  {number: "16", title: "Gold body / wire core — FAIL", image: "../iterations/A_16_comparison_gold_body_wire_core_FAIL.png", compareWithReference: false},
  {number: "17", title: "Sharp uniform gold — FAIL", image: "../iterations/A_17_comparison_sharp_uniform_gold_FAIL.png", compareWithReference: false},
  {number: "18", title: "Modulation, no material change — FAIL", image: "../iterations/A_18_comparison_modulation_no_material_change_FAIL.png", compareWithReference: false},
  {number: "19", title: "Closest sharp core / smooth — CLOSER", image: "../iterations/A_19_comparison_closest_sharp_core_smooth_CLOSER_FAIL.png", compareWithReference: false},
  {number: "20", title: "Textured but dim — FAIL", image: "../iterations/A_20_comparison_textured_but_dim_FAIL.png", compareWithReference: false},
  {number: "21", title: "Sharp textured candidate", image: "../iterations/A_21_comparison_sharp_textured_PASS_PENDING_USER.png", compareWithReference: false},
  {number: "22", title: "User rejected: blurry", image: "../iterations/A_22_comparison_user_rejected_blurry.png", compareWithReference: false},
  {number: "23", title: "User rejected: still blurry", image: "../iterations/A_23_comparison_user_rejected_still_blurry.png", compareWithReference: false},
  {number: "24", title: "Crisp multitrace / too thin", image: "../iterations/A_24_comparison_crisp_multitrace_too_thin.png", compareWithReference: false},
  {number: "25", title: "Crisp multitrace review candidate", image: "../iterations/A_25_comparison_review_required_crisp_multitrace.png", compareWithReference: false},
  {number: "26", title: "Glow lab V1 — hard-outline failure", image: "../glow_lab/A_core_glow_lab_v1_common_hard_outline.png", compareWithReference: false},
  {number: "27", title: "Glow lab: continuous hot band", image: "../glow_lab/01_continuous_hot_band.png", compareWithReference: true},
  {number: "28", title: "Glow lab: layered white ridges", image: "../glow_lab/02_layered_white_ridges.png", compareWithReference: true},
  {number: "29", title: "Glow lab: broken incandescent heat", image: "../glow_lab/03_broken_incandescent_heat.png", compareWithReference: true},
]

let lineupCandidateImages = [
  "../iterations/A_01_flat_cream_FAIL.png",
  "../iterations/A_02_clean_gold_CLOSER_FAIL.png",
  "../iterations/A_03_exposed_graphite_FAIL.png",
  "../iterations/A_04_fused_spark_CLOSER_FAIL.png",
  "../iterations/A_05_intact_warm_CLOSER_FAIL.png",
  "../iterations/A_06_richer_heat_CLOSER_FAIL.png",
  "../iterations/A_07_gold_field_CLOSER_FAIL.png",
  "../iterations/A_08_hot_ridge_CLOSER_FAIL.png",
  "../iterations/A_09_three_depths_CLOSER_FAIL.png",
  "../iterations/A_10_variable_heat_CLOSER_FAIL.png",
  "../iterations/A_11_beaded_hotspots_FAIL.png",
  "../iterations/A_12_PASS_PENDING_USER.png",
  "../iterations/A_13_blurry_FAIL.png",
  "../iterations/A_14_sharp_neon_FAIL.png",
  "../iterations/A_15_sharp_core_fog_body_FAIL.png",
  "../iterations/A_16_gold_body_wire_core_FAIL.png",
  "../iterations/A_17_sharp_uniform_gold_FAIL.png",
  "../iterations/A_18_modulation_no_material_change_FAIL.png",
  "../iterations/A_19_closest_sharp_core_smooth_CLOSER_FAIL.png",
  "../iterations/A_20_textured_but_dim_FAIL.png",
  "../iterations/A_21_sharp_textured_PASS_PENDING_USER.png",
  "../iterations/A_22_user_rejected_blurry.png",
  "../iterations/A_23_user_rejected_still_blurry.png",
  "../iterations/A_24_crisp_multitrace_too_thin.png",
  "../iterations/A_25_review_required_crisp_multitrace.png",
  "../glow_lab/A_core_glow_lab_v1_common_hard_outline.png",
  "../glow_lab/01_continuous_hot_band.png",
  "../glow_lab/02_layered_white_ridges.png",
  "../glow_lab/03_broken_incandescent_heat.png",
]

let lineupCard = (entry: lineupEntry, index: int): string => {
  let row = index / 3
  let column = index - row * 3
  let x = 40 + column * 720
  let y = 150 + row * 585
  let imageMarkup = entry.compareWithReference
    ? `<rect x="18" y="92" width="318" height="415" rx="10" fill="#f8f5ee"/>` ++
      `<image href="../reference/approved_peak_magic_A.png" x="24" y="98" width="306" height="397" preserveAspectRatio="xMidYMid meet"/>` ++
      `<rect x="346" y="92" width="336" height="415" rx="10" fill="#f4e1c0"/>` ++
      `<image href="${entry.image}" x="350" y="96" width="328" height="407" preserveAspectRatio="xMidYMid meet"/>`
    : `<rect x="18" y="92" width="664" height="415" rx="10" fill="#f8f5ee"/>` ++
      `<image href="${entry.image}" x="24" y="98" width="652" height="403" preserveAspectRatio="xMidYMid meet"/>`
  `<g transform="translate(${Belt.Int.toString(x)} ${Belt.Int.toString(y)})">` ++
  `<rect width="700" height="545" rx="20" fill="#fffaf0" stroke="#d3ae70" stroke-width="3"/>` ++
  `<rect x="18" y="18" width="76" height="56" rx="12" fill="#4b321d"/>` ++
  `<text x="56" y="57" text-anchor="middle" font-family="Arial, sans-serif" font-size="31" font-weight="700" fill="#fff8e8">${entry.number}</text>` ++
  `<text x="112" y="55" font-family="Arial, sans-serif" font-size="25" font-weight="600" fill="#3b2815">${entry.title}</text>` ++
  imageMarkup ++
  `</g>`
}

let buildLineupA = (): unit => {
  ensureDirPath(path("qa/lineup"))
  let cards = lineupEntries
    ->Belt.Array.mapWithIndex((index, entry) => lineupCard(entry, index))
    ->Js.Array2.joinWith("\n")
  let svg =
    `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="2240" height="6040" viewBox="0 0 2240 6040">` ++
    `<rect width="2240" height="6040" fill="#ead6b4"/>` ++
    `<text x="40" y="68" font-family="Arial, sans-serif" font-size="43" font-weight="700" fill="#3b2815">Frosya А — complete glow iteration lineup</text>` ++
    `<text x="40" y="112" font-family="Arial, sans-serif" font-size="24" fill="#65482d">Reference is on the left in comparison cards. Numbers are stable review IDs.</text>` ++
    cards ++
    `</svg>`
  let output = path("qa/lineup/A_all_iterations_lineup.svg")
  writeText(output, svg)
  let pageSizes = [(0, 9), (9, 9), (18, 9), (27, 2)]
  pageSizes->Belt.Array.forEachWithIndex((pageIndex, (offset, length)) => {
    let pageEntries = Belt.Array.slice(lineupEntries, ~offset, ~len=length)
    let pageCards = pageEntries
      ->Belt.Array.mapWithIndex((index, entry) => lineupCard(entry, index))
      ->Js.Array2.joinWith("\n")
    let pageHeight = 2240
    let pageNumber = pageIndex + 1
    let pageSvg =
      `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="2240" height="${Belt.Int.toString(pageHeight)}" viewBox="0 0 2240 ${Belt.Int.toString(pageHeight)}">` ++
      `<rect width="2240" height="${Belt.Int.toString(pageHeight)}" fill="#ead6b4"/>` ++
      `<text x="40" y="68" font-family="Arial, sans-serif" font-size="43" font-weight="700" fill="#3b2815">Frosya А — glow iteration lineup, page ${Belt.Int.toString(pageNumber)} of 4</text>` ++
      `<text x="40" y="112" font-family="Arial, sans-serif" font-size="24" fill="#65482d">Reference is on the left in comparison cards. Numbers are stable review IDs.</text>` ++
      pageCards ++
      `</svg>`
    writeText(
      path("qa/lineup/A_lineup_page_" ++ Belt.Int.toString(pageNumber) ++ ".svg"),
      pageSvg,
    )
  })
  let galleryCards = lineupEntries
    ->Belt.Array.mapWithIndex((index, entry) => {
      let candidate = Belt.Array.getExn(lineupCandidateImages, index)
      let preview = switch entry.number {
      | "26" => "thumbs/A_26.png"
      | "27" => "thumbs/A_27.png"
      | "28" => "thumbs/A_28.png"
      | "29" => "thumbs/A_29.png"
      | _ => entry.image
      }
      let previewMarkup = entry.compareWithReference
        ? `<div class="pair">` ++
          `<figure><img src="../reference/approved_peak_magic_A.png" alt="Frozen glow reference" loading="lazy" decoding="async"><figcaption>REFERENCE</figcaption></figure>` ++
          `<figure><a href="${candidate}" target="_blank"><img src="${preview}" alt="Candidate ${entry.number}" loading="lazy" decoding="async"></a><figcaption>CANDIDATE ${entry.number}</figcaption></figure>` ++
          `</div>`
        : `<figure class="comparison"><a href="${candidate}" target="_blank"><img src="${preview}" alt="Reference and candidate ${entry.number}" loading="lazy" decoding="async"></a><figcaption>REFERENCE LEFT · CANDIDATE RIGHT</figcaption></figure>`
      `<article class="card" id="version-${entry.number}">` ++
      `<header><span class="number">${entry.number}</span><h2>${entry.title}</h2></header>` ++
      previewMarkup ++
      `<nav><a href="${candidate}" target="_blank">Open native-resolution candidate</a><a href="${entry.image}" target="_blank">Open archived comparison</a></nav>` ++
      `</article>`
    })
    ->Js.Array2.joinWith("\n")
  let gallery =
    `<!doctype html><html lang="en"><head><meta charset="utf-8">` ++
    `<meta name="viewport" content="width=device-width,initial-scale=1">` ++
    `<title>Frosya А — Complete Glow Iteration Gallery</title>` ++
    `<style>` ++
    `:root{color-scheme:light;--ink:#392414;--paper:#f4e1c0;--card:#fffaf0;--line:#c99850}` ++
    `*{box-sizing:border-box}body{margin:0;background:#ead6b4;color:var(--ink);font-family:ui-sans-serif,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}` ++
    `.top{padding:14px 24px 10px;border-bottom:2px solid var(--line)}` ++
    `.top h1{margin:0 0 4px;font-size:clamp(23px,4vw,36px)}.top p{margin:0;font-size:15px}` ++
    `.background-preview{margin:18px 24px 0;padding:16px;background:var(--card);border:2px solid var(--line);border-radius:18px}.background-preview h2{margin:0 0 12px;font-size:22px}.background-preview img{display:block;width:100%;max-width:1000px;height:auto;margin:0 auto;border-radius:10px}` ++
    `main{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,620px),1fr));gap:22px;padding:24px}` ++
    `.card{background:var(--card);border:2px solid var(--line);border-radius:18px;padding:16px;box-shadow:0 8px 28px rgba(79,48,19,.12)}` ++
    `.card header{display:flex;align-items:center;gap:14px;margin-bottom:14px}.card h2{font-size:22px;margin:0}.number{display:grid;place-items:center;min-width:64px;height:48px;border-radius:11px;background:#4b321d;color:white;font-size:26px;font-weight:800}` ++
    `.pair{display:grid;grid-template-columns:1fr 1fr;gap:12px}.pair figure,.comparison{margin:0;display:flex;flex-direction:column;min-width:0}.pair img{display:block;width:100%;aspect-ratio:1/1;object-fit:contain;background:var(--paper);border-radius:10px;border:1px solid #dec59d}.comparison img{display:block;width:100%;height:auto;max-height:520px;object-fit:contain;background:#f7f5ef;border-radius:10px;border:1px solid #dec59d}` ++
    `.pair figure:first-child img{background:#f7f5ef}.pair figcaption,.comparison figcaption{text-align:center;font-size:13px;font-weight:800;letter-spacing:.09em;margin-top:7px;color:#6c4b2c}` ++
    `nav{display:flex;flex-wrap:wrap;gap:10px;margin-top:14px}nav a{display:inline-block;padding:10px 13px;border-radius:9px;background:#fff0d4;border:1px solid #b9833f;color:#4b321d;font-weight:750;text-decoration:none}` ++
    `nav a:first-child{background:#4b321d;color:#fff;border-color:#4b321d}` ++
    `@media(max-width:650px){main{padding:10px;gap:14px}.top{padding:10px 12px 8px}.top p{font-size:13px}.background-preview{margin:10px 10px 0;padding:10px}.background-preview h2{font-size:18px}.card{padding:12px}.card h2{font-size:19px}.number{min-width:54px;height:42px;font-size:23px}}` ++
    `</style></head><body>` ++
    `<section class="top"><h1>Frosya А — glow iterations</h1><p>Reference is on the left. Tap an image or button for the full-resolution candidate.</p></section>` ++
    `<section class="background-preview"><h2>Episode 1 letters: light paper vs dark brown</h2><a href="../../previews/magic_ep1_light_vs_dark_brown.png" target="_blank"><img src="../../previews/magic_ep1_light_vs_dark_brown.png" alt="Episode 1 magical letters on light paper and dark brown"></a></section>` ++
    `<main>${galleryCards}</main></body></html>`
  writeText(path("qa/lineup/index.html"), gallery)
  Js.log("Built complete numbered А iteration lineup: " ++ root ++ "/qa/lineup/A_all_iterations_lineup.svg")
}

let verifyDimensions = (asset: string): option<string> => {
  let result = run(
    ~cmd="ffprobe",
    ~args=[
      "-v",
      "error",
      "-select_streams",
      "v:0",
      "-show_entries",
      "stream=width,height,pix_fmt",
      "-of",
      "csv=p=0",
      asset,
    ],
  )
  let observed = Js.String2.trim(result.stdout)
  observed == "2048,2048,rgba"
    ? None
    : Some(asset ++ ": expected 2048,2048,rgba; observed " ++ observed)
}

let borderFilters = [
  "alphaextract,crop=2048:307:0:0,signalstats,metadata=print",
  "alphaextract,crop=2048:307:0:1741,signalstats,metadata=print",
  "alphaextract,crop=307:2048:0:0,signalstats,metadata=print",
  "alphaextract,crop=307:2048:1741:0,signalstats,metadata=print",
]

let verifyBorder = (asset: string): option<string> => {
  let failed = borderFilters->Belt.Array.some(filter => {
    let result = run(
      ~cmd="ffmpeg",
      ~args=[
        "-v",
        "info",
        "-i",
        asset,
        "-vf",
        filter,
        "-frames:v",
        "1",
        "-f",
        "null",
        "-",
      ],
    )
    result.code != 0 || !Js.String2.includes(result.stderr, "lavfi.signalstats.YMAX=0")
  })
  failed ? Some(asset ++ ": alpha enters the required safety border") : None
}

let verify = (): unit => {
  let failures: array<string> = []
  let dirs = ["graphite", "ignite_25", "ignite_50", "ignite_75", "ignite_90", "magic"]
  dirs->Belt.Array.forEach(dir =>
    episode1Letters->Belt.Array.forEach(letter => {
      let asset = root ++ "/assets/" ++ dir ++ "/" ++ letter ++ ".png"
      if !exists(Path(asset)) {
        failures->Js.Array2.push(asset ++ ": missing")->ignore
      } else {
        switch verifyDimensions(asset) {
        | Some(message) => failures->Js.Array2.push(message)->ignore
        | None => ()
        }
        switch verifyBorder(asset) {
        | Some(message) => failures->Js.Array2.push(message)->ignore
        | None => ()
        }
      }
    })
  )
  canonicalMagicHashes->Belt.Array.forEach(((letter, expected)) => {
    let asset = root ++ "/assets/magic/" ++ letter ++ ".png"
    if exists(Path(asset)) {
      let result = run(~cmd="shasum", ~args=["-a", "256", asset])
      if result.code != 0 || !Js.String2.startsWith(Js.String2.trim(result.stdout), expected) {
        failures->Js.Array2.push(asset ++ ": differs from the locked Episode 1 full-magic asset")->ignore
      }
    }
  })
  if failures->Js.Array2.length > 0 {
    failures->Belt.Array.forEach(Js.Console.error)
    fail(Belt.Int.toString(failures->Js.Array2.length) ++ " alphabet QA failure(s)")
  }
  Js.log(
    "PASS: 48 Episode 1 alphabet assets have valid geometry, and all 8 full-magic " ++
    "assets match the locked v1 set.",
  )
}

let verifyFull = (): unit => {
  let failures: array<string> = []
  let dirs = ["graphite", "ignite_25", "ignite_50", "ignite_75", "ignite_90", "magic"]
  dirs->Belt.Array.forEach(dir =>
    letters->Belt.Array.forEach(letter => {
      let asset = root ++ "/assets/" ++ dir ++ "/" ++ letter ++ ".png"
      if !exists(Path(asset)) {
        failures->Js.Array2.push(asset ++ ": missing")->ignore
      } else {
        switch verifyDimensions(asset) {
        | Some(message) => failures->Js.Array2.push(message)->ignore
        | None => ()
        }
        switch verifyBorder(asset) {
        | Some(message) => failures->Js.Array2.push(message)->ignore
        | None => ()
        }
      }
    })
  )
  canonicalMagicHashes->Belt.Array.forEach(((letter, expected)) => {
    let asset = root ++ "/assets/magic/" ++ letter ++ ".png"
    if exists(Path(asset)) {
      let result = run(~cmd="shasum", ~args=["-a", "256", asset])
      if result.code != 0 || !Js.String2.startsWith(Js.String2.trim(result.stdout), expected) {
        failures->Js.Array2.push(asset ++ ": differs from the locked Episode 1 full-magic asset")->ignore
      }
    }
  })
  if failures->Js.Array2.length > 0 {
    failures->Belt.Array.forEach(Js.Console.error)
    fail(Belt.Int.toString(failures->Js.Array2.length) ++ " full-alphabet QA failure(s)")
  }
  Js.log(
    "PASS: all 198 alphabet assets have valid geometry; all 8 approved Episode 1 magic assets remain hash-locked.",
  )
}

switch Belt.Array.get(argv, 2) {
| Some("build") => build()
| Some("build-full") => buildFullAlphabet()
| Some("build-magic-a") => buildMagicA()
| Some("compare-magic-a") => compareMagicA()
| Some("background-preview") => buildBackgroundPreview()
| Some("review-full") => buildFullReview()
| Some("glow-lab-a") => buildGlowLabA()
| Some("lineup-a") => buildLineupA()
| Some("verify") => verify()
| Some("verify-full") => verifyFull()
| _ =>
  fail(
    "usage: Drakosha_FrosyaAlphabet.res.mjs " ++
    "build|build-full|build-magic-a|compare-magic-a|background-preview|review-full|glow-lab-a|lineup-a|verify|verify-full",
  )
}
