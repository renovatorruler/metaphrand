#set page(width: 1280pt, height: 720pt, margin: 0pt)
#place(image("thumb_bg.png", width: 1280pt, height: 720pt, fit: "cover"))
// darken the left column for contrast
#place(rect(width: 460pt, height: 720pt, fill: gradient.linear(rgb("46321eee"), rgb("46321e00"), angle: 0deg)))
// the letter, enormous
#place(dx: 40pt, dy: 130pt)[
  #for off in ((-8pt,0pt),(8pt,0pt),(0pt,-8pt),(0pt,8pt),(-6pt,-6pt),(6pt,6pt),(-6pt,6pt),(6pt,-6pt)) {
    place(dx: off.at(0), dy: off.at(1), text(font: "Kohinoor Devanagari", size: 330pt, weight: "bold", fill: white)[न])
  }
  #text(font: "Kohinoor Devanagari", size: 330pt, weight: "bold", fill: rgb("f5b301"))[न]
]
// episode badge
#place(dx: 48pt, dy: 40pt, block(fill: rgb("c0392b"), radius: 16pt, inset: (x: 22pt, y: 12pt),
  text(font: "Kohinoor Devanagari", size: 44pt, weight: "bold", fill: white)[कड़ी 4]))
// episode title
#place(dx: 40pt, dy: 575pt, block(fill: rgb("46321eee"), radius: 18pt, inset: (x: 26pt, y: 14pt),
  text(font: "Kohinoor Devanagari", size: 62pt, weight: "bold", fill: white)[न से नल]))
