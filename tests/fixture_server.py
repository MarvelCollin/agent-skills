import gzip
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PAGE = b'<!doctype html><html lang="en"><head><title>Fixture</title></head><body><h1>Fixture page</h1></body></html>' * 20


class FixtureHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/redirect":
            self.send_response(301)
            self.send_header("Location", "/")
            self.send_header("Content-Length", "0")
            self.end_headers()
            return

        body = PAGE
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        if self.path != "/plain":
            self.send_header("Cache-Control", "max-age=3600")
            if "gzip" in self.headers.get("Accept-Encoding", ""):
                body = gzip.compress(PAGE)
                self.send_header("Content-Encoding", "gzip")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


server = ThreadingHTTPServer(("127.0.0.1", 0), FixtureHandler)
print(server.server_address[1], flush=True)
server.serve_forever()
