#!/usr/bin/env python3
"""Local AI Assistant frontend server — localhost-only, stdlib-only.

Serves the SPA in this directory at http://127.0.0.1:8090 and proxies:
  /owui/*    -> Open WebUI  (http://127.0.0.1:8080)
  /ollama/*  -> Ollama      (http://127.0.0.1:11434)
  /sys/stats -> live RAM/CPU snapshot (via PowerShell CIM on Windows)

The proxy exists so the browser talks to one origin (no CORS exposure) and
so system stats are available to the page. Nothing binds beyond loopback.
"""
import http.server
import json
import os
import socketserver
import subprocess
import sys
import time
import urllib.error
import urllib.request
from functools import partial

OWUI = os.environ.get("OWUI_URL", "http://127.0.0.1:8080")
OLLAMA = os.environ.get("OLLAMA_URL", "http://127.0.0.1:11434")
HOST, PORT = "127.0.0.1", int(os.environ.get("FRONTEND_PORT", "8090"))

_stats = {"t": 0.0, "data": {"total": None, "free": None, "cpu": None}}

_PS = (
    "$os=Get-CimInstance Win32_OperatingSystem;"
    "$cpu=(Get-CimInstance Win32_Processor|Measure-Object LoadPercentage -Average).Average;"
    "[pscustomobject]@{total=[math]::Round($os.TotalVisibleMemorySize/1MB,1);"
    "free=[math]::Round($os.FreePhysicalMemory/1MB,1);cpu=[math]::Round($cpu,0)}"
    "|ConvertTo-Json -Compress"
)


def sys_stats():
    if time.time() - _stats["t"] < 5:
        return _stats["data"]
    try:
        out = subprocess.check_output(
            ["powershell", "-NoProfile", "-Command", _PS], timeout=10
        )
        _stats["data"] = json.loads(out)
    except Exception:
        pass  # keep last snapshot (or nulls on non-Windows)
    _stats["t"] = time.time()
    return _stats["data"]


class Handler(http.server.SimpleHTTPRequestHandler):
    protocol_version = "HTTP/1.0"  # one response per connection; SSE ends on upstream close

    def log_message(self, fmt, *args):
        sys.stderr.write("%s %s\n" % (self.log_date_time_string(), fmt % args))

    def _json(self, code, obj):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _proxy(self, base, prefix):
        url = base + self.path[len(prefix):]
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length) if length else None
        req = urllib.request.Request(url, data=body, method=self.command)
        for h in ("Authorization", "Content-Type", "Accept"):
            if self.headers.get(h):
                req.add_header(h, self.headers[h])
        try:
            resp = urllib.request.urlopen(req, timeout=600)
        except urllib.error.HTTPError as e:
            resp = e
        except (urllib.error.URLError, OSError) as e:
            return self._json(502, {"error": "upstream unreachable", "detail": str(e), "target": base})
        self.send_response(resp.code)
        self.send_header("Content-Type", resp.headers.get("Content-Type", "application/octet-stream"))
        self.end_headers()
        try:
            while True:
                chunk = resp.read(8192)
                if not chunk:
                    break
                self.wfile.write(chunk)
                self.wfile.flush()
        except (BrokenPipeError, ConnectionAbortedError, ConnectionResetError):
            pass

    def _route(self):
        if self.path.startswith("/owui/"):
            return self._proxy(OWUI, "/owui")
        if self.path.startswith("/ollama/"):
            return self._proxy(OLLAMA, "/ollama")
        if self.path == "/sys/stats":
            return self._json(200, sys_stats())
        return None

    def do_GET(self):
        if self._route() is None and not self.path.startswith(("/owui/", "/ollama/")):
            super().do_GET()

    def do_POST(self):
        if self._route() is None:
            self.send_error(404)

    do_PUT = do_DELETE = do_PATCH = do_POST


def main():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    with socketserver.ThreadingTCPServer((HOST, PORT), partial(Handler)) as httpd:
        httpd.daemon_threads = True
        print(f"Local AI Assistant frontend: http://{HOST}:{PORT}")
        print(f"  proxy /owui  -> {OWUI}")
        print(f"  proxy /ollama-> {OLLAMA}")
        print("Ctrl+C to stop. Loopback-only binding.")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()
