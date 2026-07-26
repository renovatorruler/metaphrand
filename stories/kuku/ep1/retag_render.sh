#!/bin/bash
# Ep1 v9 — full expression-tag acting pass. Re-render all dialogue (except s4, which
# already uses the proof's tagged split-takes) with per-line v3 emotion tags, 4 workers.
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep1
export $(grep ELEVENLABS ../../../.env)

python3 <<'PY'
import json
rows=[l.rstrip('\n').split('\t') for l in open('lines.tsv')]
base={int(r[0]):{'scene':r[1],'who':r[2],'whisper':r[4]=='1','text':r[5]} for r in rows}

CUSTOM={
0:"[playfully] भौं भौं! देखो, ये मेरे कान हैं. मैं कुत्ता हूँ. अभी तो मैं खेल-खेल में कुत्ता हूँ, [wistfully] पर मुझे एक अपना सच्चा कुत्ता चाहिए. [excited] देखो, मैंने काला कुत्ता बनाया है. [pleading] पापा, पापा, देखो वो काला कुत्ता. आप एक कुत्ता मेरे लिए घर ले आओ ना.",
2:"[warmly] अच्छा बनाया है, बेटा. [gently] पर नहीं, कुकु. कुत्ता पालना बहुत काम है, और तुम अभी छोटे हो.",
8:"सब बैठ गए? [warmly] अच्छा, बहुत अच्छा. [brightly] आज का अक्षर है क. बोलो मेरे साथ. क.",
15:"[warmly] वैस्पर, बता तो, आज का अक्षर कौन सा है? [calling out] वैस्पर?",
22:"[proudly] शाबाश, वैस्पर. क. [encouraging] अब सब अपने कान खोलो. आज पूरे दिन हर जगह क ढूँढो.",
33:"[gently] डर मत, छोटू. मैं तुझे निकालता हूँ, धीरे धीरे, बस. [reassuring] देखो, देखो, कुछ नहीं होगा. तू बस थोड़ा रुक, मैं यहीं हूँ तेरे पास.",
37:"[laughs] अरे, ये तो मुझे चाट रहा है. [happily] ये तो अब मेरा दोस्त हो गया. और तू तो पूरा काला है, बिलकुल काला. मैं तुझे कालू बुलाऊँगा, ठीक है?",
39:"भूख लगी है, कालू? ये केला ले ले, ये सबसे अच्छा वाला है, मेरा अपना है. [puzzled] अरे, तूने खाया ही नहीं?",
42:"[whispering] कालू, नीचे आ जा, धीरे. बिलकुल चुप रह, पापा अभी अंदर ही हैं. [exasperated] अरे, तू फिर कूद गया. इतना मत कूद, कालू, गिर जाएगा.",
44:"[exasperated] नहीं नहीं, कीचड़ में मत लोट. अभी अभी तो तुझे साफ़ किया था. [sighs] फिर से गंदा हो गया. तू बस एक मिनट रुक जा.",
54:"[exasperated] हिंदी में, वैस्पर! और गेट पर ध्यान दे!",
57:"[relieved] हाँ पापा, मैं सब रख दूँगा. [worried] पापा शायद ठीक ही कहते थे. कितना काम है ये सब.",
73:"[gently] बस, बेटा, रुको. इतना हाँफो मत, कुछ नहीं हुआ है. मैं कुएँ पर ही था. मैंने सब देख लिया, तुम्हारी वो क भी देख ली. [warmly] सुबह मैंने ना कहा था. वो ना अब नहीं है. [tenderly] कालू तुम्हारा है, कुकु.",
77:"[proudly] हो गया, कालू का कटोरा भर दिया और कंबल भी बिछा दिया. मैं पहले! सबसे तेज़ मैंने ही किया!",
101:"[excited] रुको, मैं आज का अक्षर अपनी किताब में लिखूँगी. मैं पहले! [proudly] देखो, हो गया! मैंने सबसे पहले लिखा, क!",
103:"[gently] चलो अब, सब सो जाओ. शुभ रात्रि कुकु, शुभ रात्रि फूरिया. [softly] और वैस्पर कहाँ चला गया? वैस्पर?",
}
SIMPLE={1:"briskly",3:"sad",4:"cheerfully",5:"cheerfully",6:"excited",7:"eagerly",9:"excited",
10:"confidently",11:"gently",12:"puzzled",13:"warmly",14:"sheepishly",16:"urgently",17:"dreamily",
18:"exasperated",19:"dreamily",20:"warmly",21:"softly",23:"excitedly",24:"excited",25:"excited",
26:"wistfully",27:"calling out",28:"curious",29:"calling out",30:"with concern",31:"excited",
32:"gently",34:"dreamily",35:"exasperated",36:"dreamily",38:"warmly",40:"amused",41:"warmly",
43:"briskly",45:"calmly",46:"calling out",47:"nervously",48:"firmly",49:"excited",50:"urgently",
51:"giggles",52:"urgently",53:"dreamily",55:"dreamily",56:"warmly",58:"softly",59:"tenderly",
72:"nervously",74:"hopefully",75:"warmly",76:"proudly",78:"dreamily",79:"giggles",80:"dreamily",
81:"laughs",82:"giggles",83:"with a warm chuckle",84:"casually",85:"wistfully",86:"tenderly",
87:"warmly",88:"proudly",89:"excited",90:"warmly",91:"happily",92:"excited",93:"warmly",
94:"brightly",95:"proudly",96:"warmly",97:"laughs",98:"warmly",99:"excited",100:"warmly",
102:"warmly",104:"tenderly",105:"softly",106:"tenderly"}

targets=[i for i in base if not (60<=i<=71)]  # skip s4 (proof takes already tagged)
plan={}
for i in targets:
    b=base[i]
    if i in CUSTOM:
        t=CUSTOM[i]
        if b['whisper'] and not t.startswith('[whisper'): t='[whispers] '+t
    else:
        tag=SIMPLE.get(i,'')
        pre=('[whispers] ' if b['whisper'] else '')+(f'[{tag}] ' if tag else '')
        t=pre+b['text']
    plan[i]={'who':b['who'],'whisper':b['whisper'],'text':t}
json.dump(plan,open('el_plan_v2.json','w'),ensure_ascii=False,indent=1)
print('tagged',len(plan),'lines to re-render (s4 kept as proof takes)')
PY

vid_for() { case "$1" in
  KUKU) echo NbvR1eY6Q8ivACdEO8PV;; FURIA) echo FFmp1h1BMl0iVHA0JxrI;;
  VESPER) echo subIZc6skATBQ1Rbqpi7;; "DADI MAYA") echo nfMYisZqs1GOjTFllho3;;
  PAPA) echo 5ycO0zpSCEkvR4Ri6gk9;; CHEEKU) echo nUX4UWK0Tf1qh5zvFZWR;;
  MUKHIYA) echo THK4VmOwUWou6Ja9qSM4;; RADIO) echo ocf4J1Vk0yOOFNBy3kNq;; *) echo 5ycO0zpSCEkvR4Ri6gk9;; esac; }

python3 -c "
import json
for i,l in json.load(open('el_plan_v2.json')).items():
    t=l['text'].replace('\t',' ').replace(chr(10),' ')
    print(f\"{i}\t{l['who']}\t{t}\")
" > retag_lines.tsv

gen() { local idx="$1" who="$2" text="$3"; local vid
  [ "$(wc -c < el/$idx.mp3 2>/dev/null|tr -d " ")" -gt 2000 ] && { echo "SKIP $idx (already tagged)"; return; }
  vid=$(vid_for "$who")
  local payload; payload=$(python3 -c "import json,sys; print(json.dumps({'text':sys.argv[1],'model_id':'eleven_v3'}))" "$text")
  curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/$vid?output_format=mp3_44100_128" \
    -H "xi-api-key: $ELEVENLABS_API_KEY" -H "Content-Type: application/json" -d "$payload" -o "el/$idx.mp3"
  if [ "$(wc -c < el/$idx.mp3|tr -d ' ')" -lt 2000 ]; then echo "FAIL $idx: $(head -c 90 el/$idx.mp3)"; else echo "OK $idx $who"; fi; }
worker() { while IFS=$'\t' read -r idx who text; do [ $((idx % 4)) -eq "$1" ] && gen "$idx" "$who" "$text"; done < retag_lines.tsv; }
for k in 0 1 2 3; do worker "$k" & done; wait
# retry any failures
while IFS=$'\t' read -r idx who text; do [ "$(wc -c < el/$idx.mp3 2>/dev/null|tr -d ' ')" -lt 2000 ] && { sleep 2; gen "$idx" "$who" "$text"; }; done < retag_lines.tsv
echo "RE-RENDER DONE"
