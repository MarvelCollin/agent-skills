import gzip
import socket
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PAGE = b'<!doctype html><html lang="en"><head><title>Fixture</title></head><body><h1>Fixture page</h1></body></html>' * 20

SITE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Harbor Notes</title>
<meta name="description" content="Plan your week with notes your whole team can edit.">
<meta property="og:title" content="Harbor Notes">
<meta property="og:description" content="Shared notes for small teams.">
<meta property="og:image" content="{origin}/og.png">
<meta name="twitter:card" content="summary_large_image">
<link rel="canonical" href="{origin}/">
<link rel="icon" href="/favicon.ico">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
</head>
<body>
<h1>Fixture page</h1>
<img src="/hero.png" alt="Three notes on a phone screen">
<img src="/divider.png" alt="">
<script src="/static/app.js"></script>
</body>
</html>
"""

NOT_FOUND = """<!doctype html>
<html lang="en">
<head><title>Page not found | Harbor Notes</title></head>
<body>
<nav><a href="/">Home</a> <a href="/pricing">Pricing</a></nav>
<h1>We could not find that page</h1>
<p>The link may be old. Go back to the <a href="/">home page</a>.</p>
</body>
</html>
"""

ROBOTS = "User-agent: *\nAllow: /\nSitemap: {origin}/sitemap.xml\n"

SITEMAP = """<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
<url><loc>{origin}/</loc></url>
<url><loc>{origin}/pricing</loc></url>
</urlset>
"""

BARE = b'<!doctype html><html><head></head><body><h1>Bare page</h1><img src="/hero.png"><img src="/team.png"><script src="/app.js"></script></body></html>'

PNG = b"\x89PNG\r\n\x1a\nfixture"
ICO = b"\x00\x00\x01\x00fixture"

SECURITY_HEADERS = [
    ("Strict-Transport-Security", "max-age=63072000; includeSubDomains"),
    ("Content-Security-Policy", "default-src 'self'; frame-ancestors 'none'"),
    ("X-Content-Type-Options", "nosniff"),
    ("X-Frame-Options", "DENY"),
    ("Referrer-Policy", "strict-origin-when-cross-origin"),
]


class FixtureHandler(BaseHTTPRequestHandler):
    def reply(self, status, content_type, body, headers=()):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        for name, value in headers:
            self.send_header(name, value)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/redirect":
            self.send_response(301)
            self.send_header("Location", "/")
            self.send_header("Content-Length", "0")
            self.end_headers()
            return

        if self.path == "/plain":
            self.reply(200, "text/html", PAGE)
            return

        host = self.headers.get("Host", "")
        if host.split(":")[0].lower() == "localhost":
            self.bare_site()
        else:
            self.full_site("http://" + host)

    def bare_site(self):
        if self.path == "/.env":
            self.reply(200, "text/plain", b"API_KEY=fixture-not-a-real-key\nDEBUG=true\n")
        elif self.path == "/.git/HEAD":
            self.reply(200, "text/plain", b"ref: refs/heads/main\n")
        elif self.path == "/app.js":
            self.reply(200, "application/javascript", b"console.log('bare')\n//# sourceMappingURL=app.js.map\n")
        elif self.path == "/app.js.map":
            self.reply(200, "application/json", b'{"version":3,"sources":["app.ts"],"mappings":"AAAA"}')
        else:
            self.reply(200, "text/html", BARE)

    def full_site(self, origin):
        path = self.path.split("?")[0]
        if path == "/":
            body = SITE.replace("{origin}", origin).encode()
            headers = [("Cache-Control", "max-age=3600")] + SECURITY_HEADERS
            if "gzip" in self.headers.get("Accept-Encoding", ""):
                body = gzip.compress(body)
                headers.append(("Content-Encoding", "gzip"))
            self.reply(200, "text/html", body, headers)
        elif path == "/robots.txt":
            self.reply(200, "text/plain", ROBOTS.replace("{origin}", origin).encode())
        elif path == "/sitemap.xml":
            self.reply(200, "application/xml", SITEMAP.replace("{origin}", origin).encode())
        elif path == "/favicon.ico":
            self.reply(200, "image/x-icon", ICO)
        elif path in ("/apple-touch-icon.png", "/og.png", "/hero.png", "/divider.png"):
            self.reply(200, "image/png", PNG)
        elif path == "/static/app.js":
            self.reply(200, "application/javascript", b"console.log('harbor')\n")
        else:
            self.reply(404, "text/html", NOT_FOUND.encode(), SECURITY_HEADERS)

    def log_message(self, *args):
        pass


class V6Server(ThreadingHTTPServer):
    address_family = socket.AF_INET6

    def server_bind(self):
        self.socket.bind(self.server_address)
        self.server_name = "localhost"
        self.server_port = self.server_address[1]


server = ThreadingHTTPServer(("127.0.0.1", 0), FixtureHandler)
port = server.server_address[1]
try:
    v6 = V6Server(("::1", port), FixtureHandler)
    threading.Thread(target=v6.serve_forever, daemon=True).start()
except OSError:
    pass
print(port, flush=True)
server.serve_forever()
