#!/usr/bin/env python3
"""Private HTTPS fixture proxy. No connection is forwarded to the Internet."""
import http.server
import json
import socketserver
import ssl
import sys
import time
from urllib.parse import urlsplit

context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain(sys.argv[1], sys.argv[2])


class Api(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def respond(self, payload, content_type="application/json", status=200):
        data = json.dumps(payload).encode() if isinstance(payload, dict) else payload
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        path = urlsplit(self.path).path
        if path == "/api/v1/subtitles":
            self.respond({"data": [{"attributes": {"language": "en", "files": [
                {"file_id": index + 1, "file_name": name}]}}
                for index, name in enumerate(["Show.S01E01.English.srt", "Show.S01E01.EN.srt"])]})
        elif path == "/subtitle.srt":
            time.sleep(0.2)
            self.respond(b"1\n00:00:00,000 --> 00:00:03,000\nM3 native online fixture\n", "text/plain")
        else:
            self.respond({"message": "Unknown fixture path"}, status=404)

    def do_POST(self):
        payload = json.loads(self.rfile.read(int(self.headers.get("Content-Length", "0"))))
        time.sleep(0.2)
        if self.path == "/api/v1/login" and payload == {"username": "fixture-user", "password": "fixture-password"}:
            self.respond({"token": "fixture-token", "base_url": "api.opensubtitles.com"})
        elif self.path == "/api/v1/download" and self.headers.get("Authorization") == "Bearer fixture-token":
            self.respond({"link": "https://downloads.fixture.test/subtitle.srt", "file_name": "Show.S01E01.English.srt"})
        else:
            self.respond({"message": "Invalid fixture request"}, status=400)

    def log_message(self, fmt, *args):
        print(fmt % args, flush=True)


class Proxy(socketserver.StreamRequestHandler):
    def handle(self):
        method, authority, _ = self.rfile.readline().decode().split(" ", 2)
        if method != "CONNECT" or authority not in {"api.opensubtitles.com:443", "downloads.fixture.test:443"}:
            self.wfile.write(b"HTTP/1.1 403 Forbidden\r\nContent-Length: 0\r\n\r\n")
            return
        while self.rfile.readline() not in {b"\r\n", b""}:
            pass
        self.wfile.write(b"HTTP/1.1 200 Connection established\r\n\r\n")
        self.wfile.flush()
        with context.wrap_socket(self.connection, server_side=True) as secure:
            Api(secure, self.client_address, self.server)


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


with Server(("127.0.0.1", 18789), Proxy) as server:
    server.serve_forever()
