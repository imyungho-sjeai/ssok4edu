"""Serve only the Shorts DID page and feed on localhost, then open the browser."""
from functools import partial
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import threading
import urllib.request
import webbrowser

ROOT = Path(__file__).resolve().parent
PORT = 18880
URL = "http://127.0.0.1:" + str(PORT) + "/dodam-youtube-did.html"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path == "/health":
            body, content_type = b"DodamYoutubeDID-1", "text/plain"
        elif path in ("/", "/dodam-youtube-did.html", "/dodam-youtube-feed.js"):
            filename = "dodam-youtube-did.html" if path == "/" else path[1:]
            try:
                body = (ROOT / filename).read_bytes()
            except OSError:
                self.send_error(404)
                return
            content_type = "text/html; charset=utf-8" if filename.endswith(".html") else "application/javascript; charset=utf-8"
        else:
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("Referrer-Policy", "strict-origin-when-cross-origin")
        self.end_headers()
        self.wfile.write(body)


def main():
    try:
        server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    except OSError:
        with urllib.request.urlopen("http://127.0.0.1:" + str(PORT) + "/health", timeout=3) as response:
            if response.read() != b"DodamYoutubeDID-1":
                raise RuntimeError("Port 18880 is used by another program")
        webbrowser.open(URL)
        return
    threading.Timer(0.5, partial(webbrowser.open, URL)).start()
    print("Shorts DID: " + URL)
    print("Keep this window open during playback. Ctrl+C stops the local server.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
