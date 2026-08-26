#set page(width: 1280pt, height: 60pt, margin: 0pt, fill: rgb("111111"))
#let total = 307.0
#for t in range(0, 310, step: 15) {
  let x = t / total * 1280
  if x < 1270 {
    place(dx: x * 1pt, dy: 0pt, line(start: (0pt, 0pt), end: (0pt, if calc.rem(t, 60) == 0 { 18pt } else { 10pt }), stroke: 1.5pt + white))
    if calc.rem(t, 30) == 0 {
      let m = calc.floor(t / 60)
      let s = t - m * 60
      let label = str(m) + ":" + (if s < 10 { "0" } else { "" }) + str(s)
      place(dx: (x - 14) * 1pt, dy: 24pt, text(fill: white, size: 16pt, font: "Helvetica", weight: "bold", label))
    }
  }
}
