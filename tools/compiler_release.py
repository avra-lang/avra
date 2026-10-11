#!/usr/bin/env python3
"""THE COMPILER, PUBLISHED WHERE EVERY REF CAN REACH IT.

A GitHub Actions cache restores only from the run's own ref and the default
branch, so a merge-queue train — which stands on its own
`gh-readonly-queue/...` ref — can never read the compiler main built. A
release asset is not ref-scoped: publish the binary under the key
`tools/compiler_paths.sh --key` computes, and any run fetches the exact
binary that key names.

    compiler_release.py fetch   <key> <dest>   # 0 and the file, or nonzero
    compiler_release.py publish <key> <file>   # the release, created once

The key is the compiler's OWN SOURCE digest, so one key is one binary: the
artifact is immutable and `publish` never overwrites what already answers a
key. A second build of the same key is a no-op.

The releases API is reached with the run's token (`GH_TOKEN` or
`GITHUB_TOKEN`); `GITHUB_REPOSITORY` names the repo. `--api` and
`--self-test` exist so the whole path is provable against a local fake.
"""

import argparse
import json
import os
import shutil
import sys
import urllib.error
import urllib.parse
import urllib.request

ASSET = "avra"
BODY = (
    "The Avra compiler named by `tools/compiler_paths.sh --key`. "
    "Immutable: one key is one source digest, so the asset is never replaced."
)


def _headers(accept):
    h = {
        "Accept": accept,
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "avra-compiler-release",
    }
    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    if token:
        h["Authorization"] = f"Bearer {token}"
    return h


def _request(url, method="GET", data=None, accept="application/vnd.github+json", extra=None):
    h = _headers(accept)
    if extra:
        h.update(extra)
    return urllib.request.urlopen(
        urllib.request.Request(url, data=data, headers=h, method=method), timeout=120
    )


def _release(base, key):
    """The release for a key, or None when the tag does not exist."""
    url = f"{base}/releases/tags/{urllib.parse.quote(key, safe='')}"
    try:
        with _request(url) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        raise


def _has_asset(release):
    return any(a.get("name") == ASSET for a in release.get("assets", []))


def fetch(base, key, dest):
    """Place the key's compiler at dest. 1, with a word, when it is absent."""
    try:
        release = _release(base, key)
    except urllib.error.URLError as e:
        print(f"compiler-release: {key}: release API unreachable ({e})", file=sys.stderr)
        return 1
    if release is None:
        print(f"compiler-release: {key}: no release", file=sys.stderr)
        return 1
    asset = next((a for a in release.get("assets", []) if a.get("name") == ASSET), None)
    if asset is None:
        print(f"compiler-release: {key}: release has no {ASSET} asset", file=sys.stderr)
        return 1
    tmp = dest + ".part"
    try:
        with _request(asset["url"], accept="application/octet-stream") as r, open(tmp, "wb") as f:
            shutil.copyfileobj(r, f)
    except urllib.error.URLError as e:
        print(f"compiler-release: {key}: asset unreachable ({e})", file=sys.stderr)
        _unlink(tmp)
        return 1
    os.replace(tmp, dest)
    os.chmod(dest, 0o755)
    size = os.path.getsize(dest)
    print(f"compiler-release: {key}: fetched {size} bytes from release")
    return 0


def _unlink(path):
    try:
        os.unlink(path)
    except OSError:
        pass


def publish(base, key, path):
    """Create the key's release with the compiler, once. Existing is success."""
    data = open(path, "rb").read()
    release = _release(base, key)
    if release is not None and _has_asset(release):
        print(f"compiler-release: {key}: already published — left as is")
        return 0
    if release is None:
        payload = json.dumps(
            {"tag_name": key, "name": key, "body": BODY, "draft": False, "prerelease": False}
        ).encode()
        try:
            with _request(
                f"{base}/releases",
                method="POST",
                data=payload,
                extra={"Content-Type": "application/json"},
            ) as r:
                release = json.load(r)
        except urllib.error.HTTPError as e:
            if e.code != 422:
                raise
            release = _release(base, key)
            if release is None:
                raise
            if _has_asset(release):
                print(f"compiler-release: {key}: already published — left as is")
                return 0
    upload = release["upload_url"].split("{")[0] + "?name=" + urllib.parse.quote(ASSET)
    with _request(
        upload,
        method="POST",
        data=data,
        extra={"Content-Type": "application/octet-stream"},
    ) as r:
        r.read()
    print(f"compiler-release: {key}: published {len(data)} bytes")
    return 0


def _api_for(repo, override):
    return override or f"https://api.github.com/repos/{repo}"


# ---- the witness: the whole path, against a local fake of the API -------

def _self_test():
    import http.server
    import tempfile
    import threading

    state = {"next": 1, "releases": {}}

    class Fake(http.server.BaseHTTPRequestHandler):
        def log_message(self, *a):
            pass

        def _json(self, code, body):
            blob = json.dumps(body).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(blob)))
            self.end_headers()
            self.wfile.write(blob)

        def do_GET(self):
            path = self.path
            if path.startswith("/repos/o/r/releases/tags/"):
                key = urllib.parse.unquote(path.rsplit("/", 1)[-1])
                rel = state["releases"].get(key)
                if rel is None:
                    return self._json(404, {"message": "Not Found"})
                return self._json(200, rel)
            if path.startswith("/repos/o/r/releases/assets/"):
                aid = path.rsplit("/", 1)[-1]
                blob = state["blobs"].get(aid)
                if blob is None:
                    return self._json(404, {"message": "Not Found"})
                self.send_response(200)
                self.send_header("Content-Type", "application/octet-stream")
                self.send_header("Content-Length", str(len(blob)))
                self.end_headers()
                self.wfile.write(blob)
                return
            self._json(404, {"message": "Not Found"})

        def do_POST(self):
            n = int(self.headers.get("Content-Length", "0"))
            body = self.rfile.read(n)
            if self.path == "/repos/o/r/releases":
                spec = json.loads(body)
                key = spec["tag_name"]
                if key in state["releases"]:
                    return self._json(422, {"message": "Validation Failed"})
                num = state["next"]
                state["next"] += 1
                state["releases"][key] = {
                    "tag_name": key,
                    "assets": [],
                    "upload_url": f"http://{self.server.server_address[0]}:"
                    f"{self.server.server_address[1]}/upload/repos/o/r/releases/{num}/assets{{?name,label}}",
                }
                return self._json(201, state["releases"][key])
            if self.path.startswith("/upload/repos/o/r/releases/"):
                name = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query).get("name", [""])[0]
                num = self.path.split("/releases/", 1)[1].split("/", 1)[0]
                key = next(
                    k
                    for k, rel in state["releases"].items()
                    if f"/releases/{num}/assets" in rel["upload_url"]
                )
                aid = str(100 + len(state["releases"]))
                state["blobs"][aid] = body
                state["releases"][key]["assets"].append(
                    {"name": name, "url": f"http://{self.server.server_address[0]}:"
                     f"{self.server.server_address[1]}/repos/o/r/releases/assets/{aid}"}
                )
                return self._json(201, {"name": name})
            self._json(404, {"message": "Not Found"})

    state["blobs"] = {}
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Fake)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    base = f"http://127.0.0.1:{server.server_address[1]}/repos/o/r"
    try:
        return _self_test_body(base, state, tempfile)
    finally:
        server.shutdown()


def _self_test_body(base, state, tempfile):
    os.environ.pop("GH_TOKEN", None)
    os.environ.pop("GITHUB_TOKEN", None)
    failures = []

    def check(name, got, want=0):
        ok = got == want
        print(f"compiler_release: {'ok' if ok else 'FAIL'} {name}")
        if not ok:
            failures.append(name)

    with tempfile.TemporaryDirectory() as d:
        one = os.path.join(d, "avra-one")
        dest = os.path.join(d, "avra")
        with open(one, "wb") as f:
            f.write(b"compiler-A")
        check("fetch before publish answers absent", fetch(base, "avrac-aa", dest), 1)
        check("no file is left behind", os.path.exists(dest), False)
        check("publish creates the release", publish(base, "avrac-aa", one))
        check("fetch returns the bytes", fetch(base, "avrac-aa", dest))
        check("the bytes are the published ones", open(dest, "rb").read(), b"compiler-A")
        check("the file is executable", bool(os.stat(dest).st_mode & 0o100), True)

        two = os.path.join(d, "avra-two")
        with open(two, "wb") as f:
            f.write(b"compiler-B")
        check("publish of the same key is a no-op", publish(base, "avrac-aa", two))
        check("the stored bytes stand", state["blobs"]["101"], b"compiler-A")

        check("publish of a second key lands", publish(base, "avrac-bb", two))
        check("the second key reads its own bytes", fetch(base, "avrac-bb", one))
        check("key aa and key bb are distinct", open(one, "rb").read(), b"compiler-B")

    if failures:
        print(f"compiler_release: SELF-TEST FAILED — {', '.join(failures)}", file=sys.stderr)
        return 1
    print("compiler_release: self-test clean")
    return 0


def main(argv):
    if "--self-test" in argv:
        return _self_test()
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    f = sub.add_parser("fetch")
    f.add_argument("key")
    f.add_argument("dest")
    u = sub.add_parser("publish")
    u.add_argument("key")
    u.add_argument("path")
    p.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY", "avra-lang/avra"))
    p.add_argument("--api", default=os.environ.get("AVRA_RELEASE_API", ""))
    args = p.parse_args(argv)
    base = _api_for(args.repo, args.api)
    if args.cmd == "fetch":
        return fetch(base, args.key, args.dest)
    return publish(base, args.key, args.path)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
