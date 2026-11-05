"""Preview the static release with the same navigation fallback as Cloudflare."""

from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import sys
from urllib.parse import urlsplit


class AppHandler(SimpleHTTPRequestHandler):
    def send_head(self):
        path = Path(self.translate_path(self.path))
        navigation = (
            self.headers.get("Sec-Fetch-Mode") == "navigate"
            or "text/html" in self.headers.get("Accept", "")
            or not Path(urlsplit(self.path).path).suffix
        )
        if not path.exists() and navigation:
            self.path = "/index.html"
        return super().send_head()


if __name__ == "__main__":
    root = Path(__file__).resolve().parent.parent / "build" / "web"
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 52741
    server = ThreadingHTTPServer(
        ("127.0.0.1", port), partial(AppHandler, directory=str(root))
    )
    print(f"Preview: http://127.0.0.1:{port}/", flush=True)
    server.serve_forever()
