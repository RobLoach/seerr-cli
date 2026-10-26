#!/usr/bin/env python3
"""A fake Seerr API server for the tests.

Usage: mock_server.py DIR

Listens on a free port on 127.0.0.1 and writes the port number to DIR/port.
Appends each request it receives to DIR/requests as "METHOD PATH BODY".
Responses come from ROUTES, whose JSON files are in fixtures/, and from the
special cases in Handler.route.
"""

import http.server
import json
import os
import sys
import threading
import time

API_KEY = "test-key"
FIXTURES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fixtures")

# "METHOD /path?query" to the fixture file sent back with a 200 status.
ROUTES = {
    "GET /api/v1/status?checkUpdateAvailable=true": "status.json",
    "GET /api/v1/search?query=Dune&page=1": "search-dune.json",
    "GET /api/v1/search?query=Matrix&page=1": "search-matrix.json",
    "GET /api/v1/search?query=1917&page=1": "search-1917.json",
    "GET /api/v1/search?query=Hamlet&page=1": "search-hamlet-1.json",
    "GET /api/v1/search?query=Hamlet&page=2": "search-hamlet-2.json",
    "GET /api/v1/search?query=Hamlet&page=3": "search-hamlet-3.json",
    "GET /api/v1/movie/603": "movie-603.json",
    "GET /api/v1/movie/841": "movie-841.json",
    "GET /api/v1/movie/23383": "movie-23383.json",
    "GET /api/v1/movie/438631": "movie-438631.json",
    "GET /api/v1/movie/530915": "movie-530915.json",
    "GET /api/v1/tv/1399": "tv-1399.json",
    "GET /api/v1/request?take=20&skip=0&mediaType=all&sort=added": "request-list.json",
    "POST /api/v1/request/12/approve": "request-approved.json",
}

# A TV show with only specials, which Seerr won't request as "all" seasons.
SPECIALS_ONLY_SHOW = 79063

log_lock = threading.Lock()


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def respond(self):
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length).decode()
        with log_lock, open(os.path.join(sys.argv[1], "requests"), "a") as log:
            log.write(f"{self.command} {self.path} {body}".rstrip() + "\n")

        if self.headers.get("X-Api-Key") != API_KEY:
            # Seerr says "error" here, not "message".
            return self.send(403, {"status": 403, "error": "You do not have permission to access this endpoint"})
        self.route(body)

    do_GET = do_POST = do_PUT = do_PATCH = do_DELETE = respond

    def route(self, body):
        path = self.path.split("?")[0]
        key = f"{self.command} {self.path}"

        if key in ROUTES:
            with open(os.path.join(FIXTURES, ROUTES[key]), "rb") as fixture:
                return self.send(200, fixture.read())
        if path == "/api/v1/echo":
            return self.send(200, {"method": self.command, "path": self.path, "body": json.loads(body or "null")})
        if key == "GET /api/v1/redirect":
            return self.send(302, b"", headers={"Location": "https://seerr.example.com/"})
        if key == "GET /api/v1/html":
            return self.send(200, b"<html><body>Sign in</body></html>", "text/html")
        if key == "GET /api/v1/slow":
            time.sleep(3)
            return self.send(200, {})
        if key == "DELETE /api/v1/request/12":
            return self.send(204, b"")
        if key == "POST /api/v1/request":
            return self.create_request(json.loads(body))
        if key == "POST /api/v1/issue":
            issue = json.loads(body)
            return self.send(201, {"id": 3, "issueType": issue["issueType"], "status": 1, "media": {"id": issue["mediaId"]}})
        return self.send(404, {"message": "not found"})

    def create_request(self, request):
        if request["mediaId"] == SPECIALS_ONLY_SHOW:
            # Seerr's answer when no seasons are left to request: a 2xx
            # status, but no request.
            return self.send(202, {"message": "No seasons available to request"})
        return self.send(201, {
            "id": 12,
            "status": 1,
            "type": request["mediaType"],
            "is4k": request["is4k"],
            "media": {"mediaType": request["mediaType"], "tmdbId": request["mediaId"], "status": 2},
        })

    def send(self, status, body, content_type="application/json", headers=None):
        if not isinstance(body, bytes):
            body = json.dumps(body).encode()
        try:
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(body)))
            for name, value in (headers or {}).items():
                self.send_header(name, value)
            self.end_headers()
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError):
            # The client gave up waiting, as in the timeout tests.
            pass


server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
port_file = os.path.join(sys.argv[1], "port")
with open(port_file + ".tmp", "w") as f:
    f.write(str(server.server_address[1]))
os.rename(port_file + ".tmp", port_file)
server.serve_forever()
