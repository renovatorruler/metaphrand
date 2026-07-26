#!/bin/bash
# publish_doc.sh <output-name> <md-file> [<md-file2> ...] — render markdown → styled HTML on tailnet
out="$1"; shift
/tmp/kv/bin/python - "$out" "$@" <<'PY'
import sys, markdown
out=sys.argv[1]; files=sys.argv[2:]
md=markdown.Markdown(extensions=['tables','fenced_code','toc','sane_lists'])
body='\n<hr class="docsep">\n'.join(md.reset().convert(open(f,encoding='utf-8').read()) for f in files)
title=open(files[0],encoding='utf-8').readline().lstrip('# ').strip() or out
html=f'''<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title}</title>
<style>
:root{{color-scheme:light dark}}
body{{max-width:44em;margin:0 auto;padding:1.2em 1.1em 4em;
 font-family:"Georgia","Kohinoor Devanagari","Noto Serif Devanagari",serif;
 font-size:1.06em;line-height:1.62;color:#2a2118;background:#faf6ec}}
@media(prefers-color-scheme:dark){{body{{color:#e8e0d2;background:#1a1712}}
 a{{color:#e0b34c}} h1,h2,h3{{color:#f0d68a}} th{{background:#2a2419}} code,pre{{background:#241f17}}
 blockquote{{border-color:#5a4a2a;color:#c8bdaa}} .docsep{{border-color:#3a3225}}}}
h1{{font-size:1.7em;line-height:1.2;border-bottom:3px solid #e0b34c;padding-bottom:.3em;margin-top:1.2em}}
h2{{font-size:1.32em;color:#8a5a00;margin-top:1.6em;border-bottom:1px solid #e5d8b8;padding-bottom:.2em}}
h3{{font-size:1.12em;color:#6a4a10;margin-top:1.3em}}
strong{{color:#7a3f00}}
em{{color:#5a5145}}
blockquote{{border-left:4px solid #e0b34c;margin:1em 0;padding:.3em 1em;background:#f3ead4;border-radius:0 8px 8px 0;font-style:italic}}
table{{border-collapse:collapse;width:100%;margin:1em 0;font-size:.95em}}
th,td{{border:1px solid #d8c9a0;padding:.5em .7em;text-align:left;vertical-align:top}}
th{{background:#f0e6c8}}
code{{background:#efe7d2;padding:.1em .4em;border-radius:4px;font-size:.9em}}
pre{{background:#efe7d2;padding:1em;border-radius:8px;overflow-x:auto}}
ul,ol{{padding-left:1.4em}}
li{{margin:.35em 0}}
hr{{border:none;border-top:1px solid #e5d8b8;margin:1.5em 0}}
.docsep{{border:none;border-top:3px dashed #d8c088;margin:3em 0}}
</style></head><body>
{body}
</body></html>'''
open(f'/Users/dusty/kuku-serve/{out}.html','w',encoding='utf-8').write(html)
print(f'rendered {out}.html from', len(files),'doc(s)')
PY
