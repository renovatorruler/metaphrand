#!/usr/bin/env python
"""Static server for the table read with HTTP Range support (video seeking,
iPhone playback). Prefix-agnostic: works bare or behind a /tableread mount.

Run: python tools/tableread_serve.py <dir> <port>
"""
from __future__ import annotations

import os
import re
import sys
from http.server import HTTPServer, SimpleHTTPRequestHandler

ROOT = os.path.abspath(sys.argv[1])
PORT = int(sys.argv[2])


class RangeHandler(SimpleHTTPRequestHandler):
    def translate_path(self, path):  # strip mount prefix + jail to ROOT
        path = re.sub(r"^/tableread", "", path) or "/"
        path = path.split("?", 1)[0].split("#", 1)[0]
        parts = [p for p in path.split("/") if p and p not in (".", "..")]
        return os.path.join(ROOT, *parts) if parts else os.path.join(ROOT, "index.html")

    def send_head(self):
        path = self.translate_path(self.path)
        if os.path.isdir(path):
            path = os.path.join(path, "index.html")
        if not os.path.exists(path):
            self.send_error(404)
            return None
        size = os.path.getsize(path)
        rng = self.headers.get("Range")
        f = open(path, "rb")
        ctype = self.guess_type(path)
        if rng:
            m = re.match(r"bytes=(\d*)-(\d*)", rng)
            start = int(m.group(1)) if m.group(1) else 0
            end = int(m.group(2)) if m.group(2) else size - 1
            end = min(end, size - 1)
            self.send_response(206)
            self.send_header("Content-Type", ctype)
            self.send_header("Accept-Ranges", "bytes")
            self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
            self.send_header("Content-Length", str(end - start + 1))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            f.seek(start)
            self._range = (f, end - start + 1)
            return f
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Content-Length", str(size))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self._range = None
        return f

    def copyfile(self, source, outputfile):
        if getattr(self, "_range", None):
            f, remaining = self._range
            while remaining > 0:
                chunk = f.read(min(65536, remaining))
                if not chunk:
                    break
                outputfile.write(chunk)
                remaining -= len(chunk)
        else:
            super().copyfile(source, outputfile)

    def log_message(self, *a):  # quiet
        pass


if __name__ == "__main__":
    HTTPServer(("127.0.0.1", PORT), RangeHandler).serve_forever()
