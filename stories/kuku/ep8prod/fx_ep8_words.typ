#set page(width: 600pt, height: 700pt, margin: 0pt, fill: none)
#let g(s, size) = page[#place(center + horizon)[
  #for off in ((-6pt,0pt),(6pt,0pt),(0pt,-6pt),(0pt,6pt),(-4pt,-4pt),(4pt,4pt),(-4pt,4pt),(4pt,-4pt)) {
    place(center + horizon, dx: off.at(0), dy: off.at(1), text(font: "Kohinoor Devanagari", size: size, weight: "bold", fill: white)[#s])
  }
  #place(center + horizon, text(font: "Kohinoor Devanagari", size: size, weight: "bold", fill: rgb("f5b301"))[#s])
]]
#g([चील], 300pt)
#g([चाल], 300pt)
#g([चक्कर], 240pt)
#g([चुप], 320pt)
