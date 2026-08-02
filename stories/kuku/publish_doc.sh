#!/bin/bash
# publish_doc.sh <output-name> <md-file> [<md-file2> ...] — markdown → PLAIN html on the tailnet.
# Deliberately unstyled: the author wants to read the content, not a theme. Only a width cap,
# a readable line height, and enough table/pre rules that markdown structures stay legible.
out="$1"; shift
/tmp/kv/bin/python - "$out" "$@" <<'PY'
import sys, markdown
out=sys.argv[1]; files=sys.argv[2:]
md=markdown.Markdown(extensions=['tables','fenced_code','sane_lists'])
body='\n<hr>\n'.join(md.reset().convert(open(f,encoding='utf-8').read()) for f in files)
title=open(files[0],encoding='utf-8').readline().lstrip('# ').strip() or out
html=f'''<!doctype html>
<html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title}</title>
<style>
body {{ max-width: 42em; margin: 1.5em auto; padding: 0 1em; line-height: 1.6; }}
pre  {{ white-space: pre-wrap; padding: .8em; background: #f2f2f2; overflow-x: auto; }}
table {{ border-collapse: collapse; }}
th, td {{ border: 1px solid #bbb; padding: .3em .6em; text-align: left; vertical-align: top; }}
img {{ max-width: 100%; }}
</style></head><body>
{body}
</body></html>'''
open(f'/Users/dusty/kuku-serve/{out}.html','w',encoding='utf-8').write(html)
print(f'rendered {out}.html from', len(files),'doc(s)')
PY
