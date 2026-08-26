#set page(width: 600pt, height: 700pt, margin: 0pt, fill: none)
#page[#place(center + horizon)[
  #for off in ((-6pt,0pt),(6pt,0pt),(0pt,-6pt),(0pt,6pt),(-4pt,-4pt),(4pt,4pt),(-4pt,4pt),(4pt,-4pt)) {
    place(center + horizon, dx: off.at(0), dy: off.at(1), text(font: "Kohinoor Devanagari", size: 420pt, weight: "bold", fill: white)[च])
  }
  #place(center + horizon, text(font: "Kohinoor Devanagari", size: 420pt, weight: "bold", fill: rgb("f5b301"))[च])
]]
