// A framed word-picture, transparent background, for compositing over a scene
// shot while the child answers «त से…?». Same rounded brown frame as the recap
// cards, so the inset and the end-of-episode recap read as the same object.
// Rendered once per word:  typst compile --input pic=wordpics/tota.png ...
#set page(width: 520pt, height: 520pt, margin: 10pt, fill: none)
#let brown = rgb("46321e")
#place(center + horizon)[
  #box(radius: 30pt, clip: true, stroke: 10pt + brown,
       image(sys.inputs.pic, width: 460pt, height: 460pt, fit: "cover"))
]
