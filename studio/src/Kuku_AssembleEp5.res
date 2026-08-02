/* कुकु और अक्षर — Ep5 «प से पुल». The driver that replaces ep5prod/assemble_ep5.sh.
   Run from studio/:  node src/Kuku_AssembleEp5.res.mjs */

let main = () =>
  Kuku_Assemble.assembleEpisode(
    ~dir="/Users/dusty/Dev/metaphrand/stories/kuku/ep5prod",
    ~edlFile="ep5_edl.json",
    ~dursFile="ep5_durs.json",
    ~outName="KUKU_EP5_V1.mp4",
  )

main()
