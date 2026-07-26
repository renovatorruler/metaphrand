#set page(width: 600pt, height: 700pt, margin: 0pt, fill: none)
#let glyph(g) = page[#place(center + horizon)[
  #for dx in (-6pt, 6pt, 0pt, 0pt, -4pt, 4pt, -4pt, 4pt) {
    let dy = if dx == 0pt { if dx == 0pt { -6pt } else { 6pt } } else { 0pt }
    place(center + horizon, dx: dx, dy: dy, text(font: "Kohinoor Devanagari", size: 460pt, weight: "bold", fill: white)[#g])
  }
  #place(center + horizon, dx: 0pt, dy: 6pt, text(font: "Kohinoor Devanagari", size: 460pt, weight: "bold", fill: white)[#g])
  #place(center + horizon, text(font: "Kohinoor Devanagari", size: 460pt, weight: "bold", fill: rgb("f5b301"))[#g])
]]
#glyph[म]
#glyph[क]
#glyph[अ]
#glyph[ब]
#glyph[त]
#glyph[ल]
