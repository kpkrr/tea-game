#!/usr/bin/env python3
"""Tea Rush web spike server (throwaway).

Serves build/ to phones on the LAN with gzip (like a real static host, ADR-0007
assumes compressed .wasm), caches engine files so the reopen step measures a warm
start, and stores POST /report payloads in results/<session>.jsonl.

    python3 prototypes/web-spike/server.py [--port 8000]
"""
import argparse, gzip, json, os, socket, ssl, subprocess, sys, time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.path.dirname(os.path.abspath(__file__))
BUILD = os.path.join(ROOT, "build")
RESULTS = os.path.join(ROOT, "results")
GZ_CACHE = {}
TYPES = {".wasm": "application/wasm", ".js": "text/javascript", ".html": "text/html; charset=utf-8",
         ".pck": "application/octet-stream", ".png": "image/png"}


class Handler(SimpleHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def __init__(self, *a, **kw):
        super().__init__(*a, directory=BUILD, **kw)

    def log_message(self, fmt, *args):
        sys.stderr.write("%s %s\n" % (self.client_address[0], fmt % args))

    def do_GET(self):
        path = self.path.split("?")[0]
        if path == "/":
            path = "/index.html"
        full = os.path.normpath(os.path.join(BUILD, path.lstrip("/")))
        if not full.startswith(BUILD) or not os.path.isfile(full):
            self.send_error(404)
            return
        ext = os.path.splitext(full)[1]
        with open(full, "rb") as f:
            body = f.read()
        encoded = False
        if "gzip" in self.headers.get("Accept-Encoding", "") and ext in (".wasm", ".js", ".pck", ".html"):
            key = (full, os.path.getmtime(full))
            if key not in GZ_CACHE:
                GZ_CACHE[key] = gzip.compress(body, compresslevel=6)
            body, encoded = GZ_CACHE[key], True
        self.send_response(200)
        self.send_header("Content-Type", TYPES.get(ext, "application/octet-stream"))
        self.send_header("Content-Length", str(len(body)))
        if encoded:
            self.send_header("Content-Encoding", "gzip")
        # index.html and the tiny .pck always fresh (rebuilds); engine .wasm/.js cacheable so the reopen step is a warm start
        self.send_header("Cache-Control", "no-cache" if ext in (".html", ".pck") else "public, max-age=86400")
        self.send_header("Timing-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        if self.path != "/report":
            self.send_error(404)
            return
        n = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(n)
        try:
            payload = json.loads(raw)
        except ValueError:
            self.send_error(400)
            return
        os.makedirs(RESULTS, exist_ok=True)
        session = "".join(ch for ch in str(payload.get("session", "unknown")) if ch.isalnum())[:16] or "unknown"
        payload["received_unix"] = time.time()
        payload["client_ip"] = self.client_address[0]
        with open(os.path.join(RESULTS, session + ".jsonl"), "a", encoding="utf-8") as f:
            f.write(json.dumps(payload, ensure_ascii=False) + "\n")
        print(">>> report %-10s session %s from %s" % (payload.get("kind"), session, self.client_address[0]), flush=True)
        self.send_response(204)
        self.send_header("Content-Length", "0")
        self.end_headers()


def lan_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("10.255.255.255", 1))
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8443)
    ap.add_argument("--http", action="store_true", help="plain HTTP (only works on localhost: Godot needs a secure context)")
    args = ap.parse_args()
    ip = lan_ip()
    httpd = ThreadingHTTPServer(("0.0.0.0", args.port), Handler)
    scheme = "http"
    if not args.http:
        # Godot's web loader refuses to start outside a secure context, so the LAN
        # server needs HTTPS. A self-signed cert is enough: after the browser's
        # warning is bypassed the page is still https:// and isSecureContext is true.
        cert, key = os.path.join(ROOT, ".cert.pem"), os.path.join(ROOT, ".key.pem")
        if not os.path.exists(cert):
            subprocess.run(["openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "30",
                            "-keyout", key, "-out", cert, "-subj", "/CN=tea-rush-spike",
                            "-addext", "subjectAltName=IP:%s,DNS:localhost" % ip], check=True, capture_output=True)
        ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        ctx.load_cert_chain(cert, key)
        httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
        scheme = "https"
    print("Tea Rush spike: open %s://%s:%d on the phone (same Wi-Fi)" % (scheme, ip, args.port), flush=True)
    httpd.serve_forever()
