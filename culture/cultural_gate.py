"""Culture gate scanner — flag which culture/ doc each scene of a script needs, so the relevant ritual
rules get read BEFORE writing/rendering (and only when actually triggered — see culture/GATE.md).

    python culture/cultural_gate.py stories/amal/EP2_PAGES_HI.md [more.md ...]

Keyword-based; OVER-FLAGS by design (triage, don't trust a non-flag on a subtle scene)."""
import sys, re, os

TRIG = {
 "cremation.md": ["श्मशान", "घाट", "चिता", "दाह-संस्कार", "दाह संस्कार", "अंत्येष्टि", "अंतिम संस्कार", "अर्थी",
                  "बैकुंठी", "मुखाग्नि", "कपाल", "अस्थि", "तेरहवीं", "पगड़ी", "मातम", "विलाप", "रुदाली", "मृत्यु",
                  "लाश", "शव", "पिंडदान", "श्राद्ध", "पितर", "कफ़न", "सुहागन", "विधवा",
                  "cremat", "funeral", "pyre", "ghat", "mourning", "corpse", "shroud", "ashes", "widow"],
 "wedding.md": ["विवाह", "शादी", "ब्याह", "बारात", "फेरे", "सात फेरे", "सप्तपदी", "कन्यादान", "सिंदूर", "मंगलसूत्र",
                "विदाई", "जयमाला", "वरमाला", "सेहरा", "मंडप", "हल्दी", "मेहंदी", "गृहप्रवेश", "तोरण", "घुड़चढ़ी",
                "wedding", "baraat", "phere", "saptapadi", "vidaai", "mandap", "groom", "bride"],
 "matchmaking.md": ["रिश्ता", "कुंडली", "गुण मिलान", "मांगलिक", "दहेज", "लेन-देन", "सगाई", "रोका", "तिलक",
                    "लड़के की फोटो", "लड़का देखने", "लड़की देखने", "हैसियत", "बिकाऊ", "सौदा", "ब्याहना",
                    "rishta", "kundli", "dowry", "proposal", "alliance", "match", "betroth"],
 "birth.md": ["जन्म", "नामकरण", "छठी", "जातकर्म", "अन्नप्राशन", "जापा", "नवजात", "गर्भ",
              "birth", "newborn", "naming", "cradle"],
 "mundan.md": ["मुंडन", "चूड़ाकर्म", "कर्णवेध", "tonsure", "first haircut", "mundan"],
 "amal_kasumba.md": ["कसूम्बा", "कसुम्बा", "कसुम्बे", "कसुंबा", "मनुहार", "हथेली का प्याला", "अमल लेना", "kasumba"],
}

def scenes(text):
    out, title, buf = [], "(head)", []
    for ln in text.splitlines():
        if re.match(r"^#{1,3}\s", ln):
            out.append((title, " ".join(buf))); title, buf = ln.strip("# ").strip(), []
        else:
            buf.append(ln)
    out.append((title, " ".join(buf)))
    return out

def scan(path):
    text = open(path, encoding="utf-8").read()
    flagged = []
    for title, body in scenes(text):
        docs = sorted({d for d, kws in TRIG.items() if any(k in body for k in kws)})
        if docs:
            flagged.append((title, docs))
    return flagged

if __name__ == "__main__":
    for p in sys.argv[1:]:
        print(f"\n=== {os.path.basename(p)} ===", flush=True)
        f = scan(p)
        if not f:
            print("  (no ceremony triggers)")
        for title, docs in f:
            print(f"  {title[:58]:58} -> READ {', '.join('culture/'+d for d in docs)}")
