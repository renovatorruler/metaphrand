#set page(width: 600pt, height: 700pt, margin: 0pt, fill: none)
#let g(s, size) = page[#place(center + horizon)[
  #for off in ((-6pt,0pt),(6pt,0pt),(0pt,-6pt),(0pt,6pt),(-4pt,-4pt),(4pt,4pt),(-4pt,4pt),(4pt,-4pt)) {
    place(center + horizon, dx: off.at(0), dy: off.at(1), text(font: "Kohinoor Devanagari", size: size, weight: "bold", fill: white)[#s])
  }
  #place(center + horizon, text(font: "Kohinoor Devanagari", size: size, weight: "bold", fill: rgb("f5b301"))[#s])
]]
#g([प], 400pt)
#g([प #h(40pt) प], 260pt)
#g([पा], 340pt)
#g([पापा], 200pt)
#g([ा], 400pt)
#g([का], 340pt)
#g([ना], 340pt)
#g([मा], 340pt)
#g([ता], 340pt)
#g([रा], 340pt)
#g([रात], 230pt)
#g([नाम], 230pt)
#g([काम], 230pt)
#g([तारा], 200pt)
