#!/usr/bin/env python
"""fountain2pdf — render our Fountain dialect to a screenplay PDF.

The dialect (as written by the studio pipeline, e.g. SKY KING):
  Title: / Credit: / Author: / Draft date: ...   title-page block, ends at first non-key line
  ===                                            hard page break
  > **CENTERED** <                               centered line (bold markers optional)
  INT. / EXT. / EST. sluglines                   scene headings
  NAME: (also NAME (V.O.):)                      colon-terminated dialogue cue
  (parenthetical)                                actor direction inside a dialogue block
  CUT TO: / SMASH CUT TO: / FADE ...             right-aligned transitions
  everything else                                action

Chrome CLI --print-to-pdf hangs on this Mac (telemetry net); we render with
Playwright page.pdf() per the standing pipeline memory.

Usage:
  /Users/dusty/dev/metaphrand/.venv/bin/python tools/fountain2pdf.py in.fountain out.pdf
"""
from __future__ import annotations

import html
import re
import sys
import tempfile

CUE_RE = re.compile(r"^([A-Z][A-Z0-9 .'\-]{0,30}?)(\s*\((?:V\.O\.|O\.S\.|CONT'D|ON SCREEN|FILTERED)\))?:$")
SLUG_RE = re.compile(r"^(INT\.|EXT\.|EST\.|INT/EXT\.|I/E\.)", re.I)
CENTER_RE = re.compile(r"^>\s*(.*?)\s*<$")
TRANS_RE = re.compile(r"^(CUT TO|SMASH CUT TO|MATCH CUT TO|FADE (IN|OUT|TO)|DISSOLVE TO|WHITE OUT|BLACK)[ A-Z]*:?$")
PAGEBREAK_RE = re.compile(r"^===+$")
TITLEKEY_RE = re.compile(r"^(Title|Credit|Author|Source|Draft date|Contact|Notes):\s*(.*)$", re.I)

CSS = """
@page { size: 8.5in 11in; margin: 1in 1in 1in 1.5in; }
* { box-sizing: border-box; }
body { font-family: 'Courier New', Courier, monospace; font-size: 12pt; line-height: 1.1; color: #000; }
p { margin: 0; padding: 0; white-space: normal; }
.action { margin: 12pt 0 0 0; }
.slug { margin: 24pt 0 0 0; font-weight: bold; }
.cue { margin: 12pt 0 0 2.2in; }
.paren { margin: 0 0 0 1.6in; max-width: 2.0in; }
.dialogue { margin: 0 0 0 1.0in; max-width: 3.5in; }
.center { margin: 12pt 0 0 0; text-align: center; font-weight: bold; }
.trans { margin: 12pt 0 0 0; text-align: right; }
.pagebreak { page-break-after: always; }
.titlepage { text-align: center; margin-top: 3.2in; }
.titlepage .t { font-weight: bold; text-decoration: underline; }
.titlepage p { margin: 6pt 0; }
"""


def _strip_md(s: str) -> str:
    s = re.sub(r"\*\*(.+?)\*\*", r"\1", s)
    s = re.sub(r"\*(.+?)\*", r"\1", s)
    return s


def parse(text: str) -> tuple[dict, list[tuple[str, str]]]:
    """-> (title_block, [(kind, line)]); kinds: slug/cue/paren/dialogue/action/center/trans/pagebreak/blank."""
    lines = text.splitlines()
    i, title = 0, {}
    lastkey = None
    while i < len(lines):
        m = TITLEKEY_RE.match(lines[i].strip())
        if m:
            lastkey = m.group(1).lower()
            title[lastkey] = m.group(2).strip()
            i += 1
        elif lastkey and lines[i].startswith(("   ", "\t")):
            title[lastkey] += "\n" + lines[i].strip()
            i += 1
        else:
            break
    body: list[tuple[str, str]] = []
    in_dialogue = False
    for raw in lines[i:]:
        s = raw.strip()
        if not s:
            in_dialogue = False
            body.append(("blank", ""))
            continue
        if PAGEBREAK_RE.match(s):
            in_dialogue = False
            body.append(("pagebreak", ""))
        elif (m := CENTER_RE.match(s)):
            in_dialogue = False
            body.append(("center", _strip_md(m.group(1))))
        elif SLUG_RE.match(s):
            in_dialogue = False
            body.append(("slug", s))
        elif TRANS_RE.match(s):
            in_dialogue = False
            body.append(("trans", s))
        elif (m := CUE_RE.match(s)):
            in_dialogue = True
            body.append(("cue", (m.group(1) + (m.group(2) or "")).strip()))
        elif in_dialogue and s.startswith("(") and s.endswith(")"):
            body.append(("paren", s))
        elif in_dialogue:
            body.append(("dialogue", _strip_md(s)))
        else:
            body.append(("action", _strip_md(s)))
    return title, _merge_runs(body)


def _merge_runs(body: list[tuple[str, str]]) -> list[tuple[str, str]]:
    """Hard-wrapped source lines are one paragraph until a blank line: join
    consecutive action lines (and consecutive dialogue lines) with spaces so
    only intentional breaks survive."""
    out: list[tuple[str, str]] = []
    for kind, s in body:
        if kind in ("action", "dialogue") and out and out[-1][0] == kind:
            out[-1] = (kind, out[-1][1] + " " + s)
        else:
            out.append((kind, s))
    return out


def to_html(title: dict, body: list[tuple[str, str]]) -> str:
    out = [f"<html><head><meta charset='utf-8'><style>{CSS}</style></head><body>"]
    if title:
        out.append("<div class='titlepage'>")
        if "title" in title:
            out.append(f"<p class='t'>{html.escape(title['title'].upper())}</p>")
        for k in ("credit", "author", "source", "draft date", "contact"):
            if k in title:
                out.append(f"<p>{html.escape(title[k])}</p>")
        out.append("</div>")
        out.append("<div class='pagebreak'></div>")
    klass = {"slug": "slug", "cue": "cue", "paren": "paren", "dialogue": "dialogue",
             "center": "center", "trans": "trans", "action": "action"}
    for kind, s in body:
        if kind == "blank":
            continue
        if kind == "pagebreak":
            out.append("<div class='pagebreak'></div>")
            continue
        out.append(f"<p class='{klass[kind]}'>{html.escape(s)}</p>")
    out.append("</body></html>")
    return "\n".join(out)


def render_pdf(html_text: str, out_pdf: str) -> None:
    from playwright.sync_api import sync_playwright
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False, encoding="utf-8") as f:
        f.write(html_text)
        path = f.name
    with sync_playwright() as pw:
        browser = pw.chromium.launch()
        page = browser.new_page()
        page.goto(f"file://{path}")
        page.pdf(path=out_pdf, format="Letter", print_background=True,
                 margin={"top": "0", "bottom": "0", "left": "0", "right": "0"})
        browser.close()


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    src, dst = sys.argv[1], sys.argv[2]
    text = open(src, encoding="utf-8").read()
    title, body = parse(text)
    render_pdf(to_html(title, body), dst)
    n_cues = sum(1 for k, _ in body if k == "cue")
    n_slugs = sum(1 for k, _ in body if k == "slug")
    print(f"{dst}: {n_slugs} scenes, {n_cues} cues")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
