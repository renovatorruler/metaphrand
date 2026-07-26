#set page(width: 8.75in, height: 8.75in, margin: 0in)
#set text(font: "ITF Devanagari", size: 21pt, fill: rgb("46321e"))
#let cream = rgb("f7f2e6")
#let kw(w) = text(fill: rgb("c07f00"), weight: "bold", w)
#let textpage(lines) = page(fill: cream)[
  #place(top + right, dx: -0.55in, dy: 0.55in, text(size: 15pt, fill: rgb("c8a45a"))[क])
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
    text(size: 20pt, fill: rgb("46321e"), weight: "bold")[#text(fill: rgb("c07f00"))[क] #h(2pt) #w]))
#let artpage(path, pill: none, overlay: none) = page(fill: cream)[
  #place(top + left, image(path, width: 8.75in, height: 8.75in, fit: "cover"))
  #if overlay != none {
    place(top + left, dx: overlay.at(0), dy: overlay.at(1),
      text(size: overlay.at(2), fill: rgb("ffd246"), stroke: 0.6pt + white)[क])
  }
  #if pill != none { wordpill(pill) }
]

#page(fill: cream)[
  #align(center + horizon)[
    #text(size: 44pt, weight: "bold")[कुकु और काला कुत्ता]
    #v(0.4in)
    #text(size: 22pt)[एक #text(fill: rgb("c07f00"), weight: "bold")[क] वाली कहानी]
    #v(0.8in)
    #text(size: 80pt, fill: rgb("e0b34c"))[क]
  ]
]
#page(fill: cream)[
  #align(center + horizon)[
    #text(size: 24pt)[फ़ूरिया और वैस्पर के लिए]
    #v(0.5em)
    #text(size: 16pt, fill: rgb("8a7355"))[जिनकी कहानियाँ अभी शुरू हुई हैं]
  ]
]
#artpage("bpcover.jpg")
#textpage(([सुबह के समय #kw[कुकु] बगीचे की गीली घास पर #kw[कुत्ता] बनकर घूम रहा था।], [उसके सिर पर #kw[कागज़] के दो #kw[कान] बँधे थे और वह भौंक रहा था।], [#kw[कुकु] को एक अपना सच्चा #kw[कुत्ता] चाहिए था।],))
#artpage("bp01.jpg", pill: [से कान])
#textpage(([#kw[कुकु] ने अपना #kw[काला] #kw[कुत्ता] वाला चित्र पापा को दिखाया।], [पापा ने प्यार से देखा, फिर धीरे से मना कर दिया।], ["पर नहीं, #kw[कुकु]। #kw[कुत्ता] पालना बहुत #kw[काम] है, और तू अभी छोटा है।"],))
#artpage("bp02.jpg", pill: [से कुत्ता])
#textpage(([दादी माया की धूप वाली चट्टान पर सब बच्चे आकर बैठ गए।], [दादी ने कपड़ा हटाया और एक बड़ा सुनहरा क सामने खड़ा था।], ["आज का अक्षर है क।"],))
#artpage("bp03.jpg", pill: [— आज का अक्षर!], overlay: (3.75in, 5.3in, 120pt))
#textpage(([दादी ने बताया कि हिंदी का हर अक्षर सिर पर एक टोपी पहनता है।], [सब बच्चों ने हवा में ऊपर एक सीधी लकीर खींची, यही तो टोपी थी।], [फूरिया ने कहा कि वह सबसे तेज़ क ढूँढेगी।],))
#artpage("bp04.jpg", pill: [— आज का अक्षर!])
#textpage(([#kw[कुकु] और फूरिया रास्ते पर क वाले शब्द ढूँढ रहे थे।], [सपने में खोया वैस्पर सबसे पीछे बादलों को देख रहा था।], [अचानक वैस्पर रुका और बोला, "वहाँ... कोई रो रहा है।"],))
#artpage("bp05.jpg", pill: [से कान])
#textpage(([पुराने #kw[कुएँ] के पास #kw[कीचड़] में एक छोटा #kw[काला] पिल्ला फँसा हुआ था।], [उसके #kw[कान] नीचे लटके थे और वह डर से काँप रहा था।], [फूरिया धीरे से उसके पास बैठ गई और नरम आवाज़ में बोली।],))
#artpage("bp06.jpg", pill: [से कीचड़])
#textpage(([#kw[कुकु] ने अपने दोनों हाथों से पिल्ले को #kw[कीचड़] से बाहर निकाला।], [पिल्ला बिलकुल #kw[काला] था, इसलिए #kw[कुकु] ने उसका नाम #kw[कालू] रखा।], [#kw[कालू] ने #kw[केला] सूँघकर मुँह मोड़ लिया, "#kw[कुत्ता] #kw[केला] नहीं खाता, #kw[कुकु]।"],))
#artpage("bp07.jpg", pill: [से केला])
#textpage(([घर के आँगन में #kw[कालू] कूदता, भागता और #kw[कीचड़] में लोटता रहा।], [भागते हुए #kw[कालू] से दादी के सारे स्टील के #kw[कटोरे] गिर गए।], [सब बच्चे जल्दी से #kw[कटोरे] उठाने लगे ताकि पापा न सुनें।],))
#artpage("bp08.jpg", pill: [से कटोरा])
#textpage(([पापा आवाज़ सुनकर दरवाज़े तक आए, पर #kw[कुकु] ने #kw[कालू] को #kw[कंबल] में छुपा दिया।], [पापा खेत चले गए और आँगन फिर से शांत हो गया।], [#kw[कुकु] ने सोते #kw[कालू] को गोद में लिया और सोचा कि सच में बहुत #kw[काम] है।],))
#artpage("bp09.jpg", pill: [से कंबल])
#textpage(([शाम को #kw[कुकु] #kw[कालू] के साथ #kw[कुएँ] वाले रास्ते पर टहल रहा था।], [अचानक एक मोटा #kw[कबूतर] उड़ा और #kw[कालू] उसके पीछे दौड़ पड़ा।], [#kw[कालू] के पैर चिकने पत्थर पर फिसले और वह #kw[कुएँ] में गिरने लगा।],))
#artpage("bp10.jpg", pill: [से कुआँ])
#textpage(([फूरिया सबसे पहले चट्टान पर लेट गई और हाथ नीचे बढ़ाए।], [पर उसके हाथ छोटे पड़ गए और #kw[कालू] तक नहीं पहुँच पाए।], [वैस्पर ने कहा, "ऊपर से कोई हुक जैसी चीज़ नीचे जाए।"],))
#artpage("bp11.jpg", pill: [से कुआँ])
#textpage(([फूरिया ने #kw[कुकु] का हाथ थामा और मंत्र बोलना सिखाया।], [#kw[कुकु] ने लंबी साँस ली और हवा में एक चमकता क बना दिया।], ["साँस... टोपी... अक्षर! क!"],))
#artpage("bp12.jpg", pill: [— आज का अक्षर!], overlay: (1.85in, 1.55in, 120pt))
#textpage(([चमकते क ने अपनी पूँछ से #kw[कालू] को ऊपर उठाकर बचा लिया।], [पापा ने सब कुछ देख लिया था और प्यार से मुस्कुराए।], ["#kw[कालू] तुम्हारा है, #kw[कुकु]।"],))
#artpage("bp13.jpg", pill: [से कालू])
#textpage(([रात को तारों के नीचे बच्चों ने दिन भर के क वाले शब्द गिनाए।], [फूरिया ने अपनी #kw[किताब] में सबसे पहले टोपी वाला क लिखा।], [#kw[कालू] के पास सोते वैस्पर पर #kw[कंबल] डालकर दादी बोलीं, "शुभ रात्रि, वैस्पर।"],))
#artpage("bp14.jpg", pill: [से किताब])
#page(fill: cream)[
  #place(top + center, dy: 0.55in, text(size: 28pt, weight: "bold")[आज का अक्षर])
  #place(top + center, dy: 1.15in, text(size: 84pt, fill: rgb("e0b34c"))[क])
  #place(top + center, dy: 2.9in, image("bplesson.jpg", width: 3.9in))
  #place(top + center, dy: 7.0in, text(size: 21pt)[#kw[क] से कुत्ता · #kw[क] से कान · #kw[क] से केला])
  #place(top + center, dy: 7.6in, text(size: 16pt, fill: rgb("8a7355"))[हिंदी का हर अक्षर टोपी पहनता है!])
]