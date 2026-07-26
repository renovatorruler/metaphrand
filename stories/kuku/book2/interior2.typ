#set page(width: 8.75in, height: 8.75in, margin: 0in)
#set text(font: "ITF Devanagari", size: 21pt, fill: rgb("46321e"))
#let cream = rgb("f7f2e6")
#let kw(w) = text(fill: rgb("c07f00"), weight: "bold", w)
#let textpage(lines) = page(fill: cream)[
  #place(top + right, dx: -0.55in, dy: 0.55in, text(size: 15pt, fill: rgb("c8a45a"))[म])
  #align(center + horizon)[
    #block(width: 6.6in)[
      #for l in lines [
        #par(justify: false, leading: 0.9em)[#align(center)[#l]]
        #v(0.55em)
      ]
    ]
  ]
]
#let wordpill(w) = place(bottom + left, dx: 0.55in, dy: -0.55in,
  block(fill: rgb(255,255,255,225), radius: 14pt, inset: (x: 16pt, y: 10pt),
    text(size: 20pt, fill: rgb("46321e"), weight: "bold")[#text(fill: rgb("c07f00"))[म] #h(2pt) #w]))
#let artpage(path, pill: none) = page(fill: cream)[
  #place(top + left, image(path, width: 8.75in, height: 8.75in, fit: "cover"))
  #if pill != none { wordpill(pill) }
]

#page(fill: cream)[
  #align(center + horizon)[
    #text(size: 44pt, weight: "bold")[म से माँ]
    #v(0.4in)
    #text(size: 22pt)[एक #text(fill: rgb("c07f00"), weight: "bold")[म] वाली कहानी]
    #v(0.8in)
    #text(size: 80pt, fill: rgb("e0b34c"))[म]
  ]
]
#page(fill: cream)[
  #align(center + horizon)[
    #text(size: 24pt)[फ्यूरिया और वैस्पर के लिए]
    #v(0.5em)
    #text(size: 16pt, fill: rgb("8a7355"))[जिनकी कहानियाँ अभी शुरू हुई हैं]
  ]
]
#artpage("b2cover.jpg")
#textpage(([आज अक्षर घाटी में #kw[मेला] है!], [कुकु के पास #kw[माशा] का ख़त आया —], [वो भी बड़े शहर के #kw[मेले] में गई है।],))
#artpage("b201.jpg", pill: [— आज का अक्षर!])
#textpage(([दादी #kw[माया] ने कहा — देखो बच्चों,], [हर झंडे पर आज का अक्षर चमक रहा है।], [ये है #kw[म]! #kw[म] से #kw[मेला]!],))
#artpage("b202.jpg", pill: [से मेला])
#textpage(([पहाड़ी के ऊपर से #kw[मिटासुर] देख रहा था।], [उसने कहा — जो मैं बना नहीं सकता,], [उसे मैं मिटा सकता हूँ!], [और उसने पूरी घाटी का #kw[म] चुरा लिया।],))
#artpage("b203.jpg", pill: [— आज का अक्षर!])
#textpage(([#kw[मिठाई] का स्वाद चला गया।], [#kw[मोर] की पूँछ खुलना भूल गई।], [दादी के बोर्ड से #kw[म] उड़ गया —], [सिर्फ़ 'ठाई' बचा!],))
#artpage("b204.jpg", pill: [से मिठाई])
#textpage(([नन्हा चूज़ा अपनी #kw[माँ] को], [पुकार नहीं पा रहा था।], ['#kw[माँ]' बोलने के लिए भी तो #kw[म] चाहिए!],))
#artpage("b205.jpg", pill: [से माँ])
#textpage(([दादी ने चट्टान के ऊपर], [एक सुनहरा #kw[म] दिखाया।], [देखो — ये है #kw[म]।], [मेरे नाम '#kw[माया]' में भी #kw[म] है!],))
#artpage("b206.jpg", pill: [से माया])
#textpage(([वैस्पर ने धीरे से कहा — that's... M.], [फ्यूरिया ने हँसकर कहा —], [हिंदी में, वैस्पर!], [...#kw[म]।],))
#artpage("b207.jpg", pill: [— आज का अक्षर!])
#textpage(([अक्षर वीर तैयार हुए!], [कालू ने ज़मीन सूँघी], [और चोर का पता ढूँढ लिया।], [सब #kw[मिटासुर] के पीछे दौड़े।],))
#artpage("b208.jpg", pill: [— आज का अक्षर!])
#textpage(([पर वैस्पर रुक गया।], [उसने वो देखा, जो किसी ने नहीं देखा —], [एक #kw[मटके] से सुनहरी रोशनी निकल रही थी।], [किसी ने नहीं सुना... तो वैस्पर ने], [अपनी सबसे ज़ोरदार आवाज़ निकाली — आआआ!],))
#artpage("b209.jpg", pill: [से मटका])
#textpage(([सारी घाटी रुक गई।], [वैस्पर ने शांति से कहा — #kw[म] #kw[मटके] में है।], [#kw[मिटासुर] ने थैला पकड़ लिया —], [नहीं! ये मेरा है!], [मेरे पास अपना कुछ भी नहीं है!],))
#artpage("b210.jpg", pill: [— आज का अक्षर!])
#textpage(([तभी आवाज़ आई —], [#kw[मदद] करो! चूज़ा पानी में गिर जाएगा!], [कुकु ने पैर जमाए — मैं अभी #kw[म] बनाता हूँ!], [सबने कहा — कुकु, तुम कर सकते हो!],))
#artpage("b211.jpg", pill: [से मदद])
#textpage(([कुकु की साँस से एक सुनहरा #kw[म] बना —], [और #kw[म] एक नाव बन गया!], [नाव चूज़े को उसकी #kw[माँ] के पास ले गई।], [#kw[मिटासुर] का थैला फट गया,], [और सारे अक्षर घर लौट आए!],))
#artpage("b212.jpg", pill: [से मोर])
#textpage(([कुकु ने #kw[मिटासुर] से कहा —], [तुम बनाना सीख सकते हो। मैं सिखाऊँगा।], [#kw[मिटासुर] ने धीरे से फूँक मारी —], [और एक नन्हा, टेढ़ा-मेढ़ा #kw[म] बना।], [मैंने... मैंने ख़ुद बनाया!],))
#artpage("b213.jpg", pill: [— आज का अक्षर!])
#textpage(([शाम को पापा ने आकर], [दादी को प्यार किया।], [कुकु ने पूछा — क्या दादी आपकी #kw[माँ] हैं?], [हाँ बेटा। #kw[माँ] तो सबकी होती है —], [बड़ों की भी। शुभ रात्रि, वैस्पर।],))
#artpage("b214.jpg", pill: [से माँ])
#page(fill: cream)[
  #place(top + center, dy: 0.55in, text(size: 28pt, weight: "bold")[आज का अक्षर])
  #place(top + center, dy: 1.15in, text(size: 84pt, fill: rgb("e0b34c"))[म])
  #place(top + center, dy: 2.9in, image("b2lesson.jpg", width: 3.9in))
  #place(top + center, dy: 7.0in, text(size: 21pt)[#kw[म] से माँ · #kw[म] से मेला · #kw[म] से मोर])
  #place(top + center, dy: 7.6in, text(size: 16pt, fill: rgb("8a7355"))[माँ तो सबकी होती है — बड़ों की भी!])
]