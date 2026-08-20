/* Rebuild and verify Frosya's composable Episode 1 alphabet assets.

   The graphite PNG is always the master geometry. Every ignition and magic
   state below is derived from its alpha mask with ffmpeg; no state is drawn or
   generated independently.

   Usage from studio/:
     rescript && node src/Drakosha_FrosyaAlphabet.res.mjs build
     rescript && node src/Drakosha_FrosyaAlphabet.res.mjs build-magic-a
     rescript && node src/Drakosha_FrosyaAlphabet.res.mjs compare-magic-a
     rescript && node src/Drakosha_FrosyaAlphabet.res.mjs glow-lab-a
     rescript && node src/Drakosha_FrosyaAlphabet.res.mjs lineup-a
     rescript && node src/Drakosha_FrosyaAlphabet.res.mjs verify
*/

open Cinema_Backends

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exit: int => unit = "exit"

let root = "../stories/drakosha/production/alphabet/frosya"
let canvas = 2048
let safety = 307 // 15% of 2048, rounded up

let letters = ["А", "О", "М", "С", "К", "Т", "Л", "Б"]

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
  | _ => "123"
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
  | _ => "499"
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
  | _ => "601"
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
  | _ => "733"
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
  | _ => "1571"
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
  | _ => "2381"
  }

let particleFilter = (state: glowState, letter: string): string => {
  if state.particles == "0" {
    `[mregion]nullsink;[letter]null[out]`
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
    `[withFineParticles][sparkles]overlay=format=auto,format=rgba[out]`
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

let build = (): unit => {
  buildPaper()
  letters->Belt.Array.forEach(letter =>
    states->Belt.Array.forEach(state => buildState(letter, state))
  )
  Js.log("Built canonical paper and 40 derived ignition/magic assets.")
}

/* The acceptance loop deliberately works on one glyph. This prevents an
   exploratory treatment from being propagated to the other seven letters and
   makes every candidate cheap enough to reject without hesitation. */
let buildMagicA = (): unit => {
  let magicState = states->Belt.Array.getExn(4)
  buildState("А", magicState)
  Js.log("Built peak-magic candidate for А only.")
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
  if failures->Js.Array2.length > 0 {
    failures->Belt.Array.forEach(Js.Console.error)
    fail(Belt.Int.toString(failures->Js.Array2.length) ++ " alphabet QA failure(s)")
  }
  Js.log(
    "PASS: 48 Episode 1 alphabet assets are 2048x2048 RGBA and keep the outer " ++
    Belt.Int.toString(safety) ++ " px fully transparent.",
  )
}

switch Belt.Array.get(argv, 2) {
| Some("build") => build()
| Some("build-magic-a") => buildMagicA()
| Some("compare-magic-a") => compareMagicA()
| Some("background-preview") => buildBackgroundPreview()
| Some("glow-lab-a") => buildGlowLabA()
| Some("lineup-a") => buildLineupA()
| Some("verify") => verify()
| _ =>
  fail(
    "usage: Drakosha_FrosyaAlphabet.res.mjs " ++
    "build|build-magic-a|compare-magic-a|background-preview|glow-lab-a|lineup-a|verify",
  )
}
