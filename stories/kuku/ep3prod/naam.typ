#set page(width: 1100pt, height: 300pt, margin: 0pt, fill: none)
#let nm(t) = page[#place(left + horizon, dx: 40pt)[
  #for off in ((-4pt,0pt),(4pt,0pt),(0pt,-4pt),(0pt,4pt)) {
    place(left + horizon, dx: 40pt + off.at(0), dy: off.at(1), text(font: "Kohinoor Devanagari", size: 190pt, weight: "bold", fill: white)[#t])
  }
  #place(left + horizon, dx: 40pt, text(font: "Kohinoor Devanagari", size: 190pt, weight: "bold", fill: rgb("c0392b"))[#t])
]]
#nm[मिटासु]
#nm[मिटासुर]
