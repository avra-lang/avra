#!/usr/bin/env python3
# tool-witness: run by witness_compiler_release.sh
"""THE COMPILER, PUBLISHED WHERE EVERY REF CAN REACH IT.

A GitHub Actions cache restores only from the run's own ref and the default
branch, so a run that missed the cache — a PR on its own ref, a lane —
fetches the exact binary main published instead of rebuilding it. A release
asset is not ref-scoped: publish the binary under the key
`tools/compiler_paths.sh --key` computes, and any run fetches the exact
binary that key names.

    compiler_release.py fetch   <key> <dest>   # 0 and the file, or nonzero
    compiler_release.py latest  <dest>         # the newest published compiler
    compiler_release.py publish <key> <file>   # the release, created once
    compiler_release.py install [<rev> | --key <key>] [--into <dir>]
                                               # the compiler published for a commit's source
                                               # (default origin/main) or a key, installed as
                                               # <dir>/avra (default build), the standing one
                                               # kept as avra.pre; Linux only
    compiler_release.py key-of <rev>           # the key a commit's compiler source has
    compiler_release.py probe <key>            # 0 when a compiler is published for the key
    compiler_release.py route <dirty> <head-key> <base-key>
                                               # how a run's compiler is got: published:<key>,
                                               # mergebase:<key> (install it, then one
                                               # generation), or build

`install`, `probe` and `route` read the repository's public release asset
(`FETCH_URL`, `releases/download/avrac-KEY/avra`), so they need no token; a
`file://` FETCH_URL points them at a local file for the witness.

`fetch` reads the release named by the key — the tree's OWN compiler, so a
hit needs no build. A tree that differs from main (a train, or a PR that
touches the compiler's source) has a key no release can carry, because only
a push to main publishes; `latest` answers main's newest compiler instead.
That one is not the tree's, so it is the STARTING point an incremental
build reads, never a reason to skip the build.

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
import subprocess
import sys
import time
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


def fetch_latest(base, dest):
    """Place the newest published compiler at dest. 1, with a word, when
    no release carries one. Only a push to main publishes, so the newest
    release is main's latest compiler — a train's or a PR's own key is
    never published, and this is the starting point its incremental build
    reads, never the tree's own compiler."""
    try:
        release = _newest(base)
    except urllib.error.URLError as e:
        print(f"compiler-release: latest: release API unreachable ({e})", file=sys.stderr)
        return 1
    if release is None:
        print("compiler-release: latest: no published release carries an avra asset", file=sys.stderr)
        return 1
    asset = next(a for a in release["assets"] if a.get("name") == ASSET)
    tag = release.get("tag_name", "?")
    tmp = dest + ".part"
    try:
        with _request(asset["url"], accept="application/octet-stream") as r, open(tmp, "wb") as f:
            shutil.copyfileobj(r, f)
    except urllib.error.URLError as e:
        print(f"compiler-release: latest {tag}: asset unreachable ({e})", file=sys.stderr)
        _unlink(tmp)
        return 1
    os.replace(tmp, dest)
    os.chmod(dest, 0o755)
    print(f"compiler-release: latest {tag}: fetched {os.path.getsize(dest)} bytes from release")
    return 0


def _newest(base):
    """The newest published release carrying the compiler asset, or None.
    Releases are listed newest-first by GitHub, but the order is sorted
    here so the choice reads from the data, not from the API's promise."""
    with _request(f"{base}/releases?per_page=100") as r:
        releases = json.load(r)
    ranked = sorted(
        (rel for rel in releases if _has_asset(rel) and not rel.get("draft")),
        key=lambda rel: rel.get("created_at") or "",
        reverse=True,
    )
    return ranked[0] if ranked else None


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


# ---- the public asset: no token, the door `install`, `probe` and `route` use ----

def _asset_url(key):
    template = os.environ.get(
        "FETCH_URL",
        "https://github.com/%s/releases/download/avrac-KEY/avra"
        % os.environ.get("GITHUB_REPOSITORY", "avra-lang/avra"),
    )
    return template.replace("KEY", key)


def _asset_there(url):
    if url.startswith("file://"):
        return os.path.isfile(url[len("file://"):])
    try:
        req = urllib.request.Request(url, method="HEAD")
        with urllib.request.urlopen(req, timeout=30):
            return True
    except (urllib.error.URLError, OSError):
        return False


def _asset_fetch(url, dest):
    """The asset, asked up to FETCH_TRIES (5) times with a doubling pause (2 s first). Answers (ok, why):
    why names the last answer, with its HTTP status when there was one."""
    if url.startswith("file://"):
        try:
            shutil.copyfile(url[len("file://"):], dest)
            return True, ""
        except OSError as e:
            return False, f"{url} is not a file ({e})"
    tries = int(os.environ.get("FETCH_TRIES", "5"))
    pause = 2
    why = ""
    for attempt in range(1, tries + 1):
        try:
            with urllib.request.urlopen(url, timeout=int(os.environ.get("FETCH_MAX_S", "600"))) as r, open(dest, "wb") as f:
                shutil.copyfileobj(r, f)
            return True, ""
        except urllib.error.HTTPError as e:
            why = f"HTTP {e.code} after {attempt} attempt(s)"
        except (urllib.error.URLError, OSError) as e:
            why = f"no HTTP answer after {attempt} attempt(s): {e}"
        if attempt < tries:
            time.sleep(pause)
            pause *= 2
    return False, why


def key_of(rev, scratch="build"):
    """The compiler-source key of a commit, read from a temporary index of its tree."""
    os.makedirs(scratch, exist_ok=True)
    env = dict(os.environ, GIT_INDEX_FILE=os.path.join(scratch, "fetch.index"))
    if subprocess.run(["git", "read-tree", rev], env=env, capture_output=True).returncode != 0:
        return None
    got = subprocess.run(["sh", "tools/compiler_paths.sh", "--key"], env=env, capture_output=True, text=True)
    return got.stdout.strip() if got.returncode == 0 and got.stdout.strip() else None


def _refuse(why):
    print(f"compiler-release: REFUSED — {why}", file=sys.stderr)
    return 1


def install(rev, key, into):
    platform = os.environ.get("FETCH_UNAME") or os.uname().sysname
    if platform != "Linux":
        return _refuse(f"the published compiler is a linux binary; this machine is {platform} (run it on a Sprite)")
    if key:
        names = "a key given on the command line"
    else:
        rev = rev or "origin/main"
        if subprocess.run(["git", "rev-parse", "--git-dir"], capture_output=True).returncode != 0:
            return _refuse("no git repository here; read the key where git is (sh tools/compiler_paths.sh --key at the commit) and pass it with --key")
        got = subprocess.run(["git", "rev-parse", "--verify", "--quiet", rev + "^{commit}"], capture_output=True, text=True)
        if got.returncode != 0:
            return _refuse(f"no commit named {rev}")
        names = got.stdout.strip()
        key = key_of(names, into)
        if key is None:
            return _refuse(f"the compiler source of {names} is not listed")
    url = _asset_url(key)
    os.makedirs(into, exist_ok=True)
    fetched = os.path.join(into, "avra.fetch")
    ok, why = _asset_fetch(url, fetched)
    if not ok and "FETCH_URL" not in os.environ:
        # the anonymous door failed: the releases API, with the run's token when it has one, is the second
        base = _api_for(os.environ.get("GITHUB_REPOSITORY", "avra-lang/avra"), os.environ.get("AVRA_RELEASE_API", ""))
        if fetch(base, f"avrac-{key}", fetched) == 0:
            print(f"compiler-release: the anonymous asset failed ({why}); the releases API answered", file=sys.stderr)
            ok = True
    if not ok:
        return _refuse(f"no published compiler for {names} (key {key}): {url} did not answer — last answer {why}")
    os.chmod(fetched, 0o755)
    if subprocess.run([fetched, "--version"], capture_output=True).returncode != 0:
        return _refuse(f"the compiler published for {names} does not run here")
    standing = os.path.join(into, "avra")
    if os.path.exists(standing):
        pre = standing + ".pre"
        if os.path.exists(pre):
            os.replace(pre, f"{pre}.{int(time.time())}")
        os.replace(standing, pre)
    os.replace(fetched, standing)
    data = open(standing, "rb").read()
    import hashlib
    print(f"compiler-release: installed {standing} — key {key} from {names}, {len(data)} bytes, sha256 {hashlib.sha256(data).hexdigest()}")
    return 0


def route(dirty, head_key, base_key):
    if dirty == "0" and head_key and _asset_there(_asset_url(head_key)):
        print(f"published:{head_key}")
    elif base_key and _asset_there(_asset_url(base_key)):
        print(f"mergebase:{base_key}")
    else:
        print("build")
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
            if path.startswith("/repos/o/r/releases?") or path == "/repos/o/r/releases":
                return self._json(200, list(state["releases"].values()))
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
                    "created_at": "2026-01-0%dT00:00:00Z" % num,
                    "draft": False,
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

        check("latest reads a published compiler", fetch_latest(base, dest))
        check("latest is the newest release", open(dest, "rb").read(), b"compiler-B")

    _self_test_install(check, tempfile)

    if failures:
        print(f"compiler_release: SELF-TEST FAILED — {', '.join(failures)}", file=sys.stderr)
        return 1
    print("compiler_release: self-test clean")
    return 0


def _self_test_install(check, tempfile):
    """`install`, `probe` and `route` against local files, with no network and no token."""
    import io
    import contextlib

    def said(fn, *a):
        buf, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(err):
            rc = fn(*a)
        return rc, buf.getvalue() + err.getvalue()

    with tempfile.TemporaryDirectory() as d:
        pub = os.path.join(d, "published")
        with open(pub, "w") as f:
            f.write("#!/bin/sh\necho stub-avra\n")
        os.chmod(pub, 0o755)
        for name in ("pub-hk", "pub-mk"):
            open(os.path.join(d, name), "w").write("x")
        os.environ["FETCH_UNAME"] = "Darwin"
        rc, out = said(install, None, "abc123", os.path.join(d, "mac"))
        check("macOS refuses", rc == 1 and "the published compiler is a linux binary" in out, True)
        os.environ["FETCH_UNAME"] = "Linux"
        os.environ["FETCH_URL"] = "file://" + os.path.join(d, "absent")
        rc, out = said(install, None, "abc123", os.path.join(d, "none"))
        check("no published compiler refuses", rc == 1 and "no published compiler for a key given on the command line (key abc123)" in out, True)
        rc, out = said(install, "no-such-commit-here", None, os.path.join(d, "sha"))
        check("an unknown commit refuses", rc == 1 and "no commit named no-such-commit-here" in out, True)
        os.environ["FETCH_URL"] = "file://" + pub
        ok = os.path.join(d, "ok")
        os.makedirs(ok)
        open(os.path.join(ok, "avra"), "w").write("standing\n")
        rc, out = said(install, None, "abc123", ok)
        check("install names the key and the bytes", rc == 0 and "key abc123" in out, True)
        check("the standing compiler moves to avra.pre", open(os.path.join(ok, "avra.pre")).read(), "standing\n")
        check("the fetched compiler is installed as avra", open(os.path.join(ok, "avra")).read(), "#!/bin/sh\necho stub-avra\n")
        os.environ["FETCH_URL"] = "file://" + os.path.join(d, "pub-KEY")
        os.environ["FETCH_URL"] = "http://127.0.0.1:9/none"
        os.environ["FETCH_TRIES"] = "2"
        rc, out = said(install, None, "abc123", os.path.join(d, "retry"))
        check("an unreachable asset is asked again and the answer named", rc == 1 and "after 2 attempt(s)" in out, True)
        os.environ.pop("FETCH_TRIES")
        os.environ["FETCH_URL"] = "file://" + os.path.join(d, "pub-KEY")
        check("a probe finds a published key", _asset_there(_asset_url("hk")), True)
        check("published key takes the published path", said(route, "0", "hk", "mk")[1], "published:hk\n")
        check("a dirty tree takes the merge-base path", said(route, "1", "hk", "mk")[1], "mergebase:mk\n")
        check("an unpublished head takes the merge-base path", said(route, "0", "hkabs", "mk")[1], "mergebase:mk\n")
        check("nothing published builds", said(route, "0", "hkabs", "mkabs")[1], "build\n")
    for name in ("FETCH_URL", "FETCH_UNAME"):
        os.environ.pop(name, None)


def main(argv):
    global ASSET
    if "--self-test" in argv:
        return _self_test()
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    f = sub.add_parser("fetch")
    f.add_argument("key")
    f.add_argument("dest")
    l = sub.add_parser("latest")
    l.add_argument("dest")
    i = sub.add_parser("install")
    i.add_argument("rev", nargs="?")
    i.add_argument("--key")
    i.add_argument("--into", default=os.environ.get("FETCH_BUILD", "build"))
    k = sub.add_parser("key-of")
    k.add_argument("rev")
    pr = sub.add_parser("probe")
    pr.add_argument("key")
    r = sub.add_parser("route")
    r.add_argument("dirty")
    r.add_argument("head_key", nargs="?", default="")
    r.add_argument("base_key", nargs="?", default="")
    u = sub.add_parser("publish")
    u.add_argument("key")
    u.add_argument("path")
    p.add_argument("--asset", default=ASSET, help="the release asset's name")
    p.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY", "avra-lang/avra"))
    p.add_argument("--api", default=os.environ.get("AVRA_RELEASE_API", ""))
    args = p.parse_args(argv)
    ASSET = args.asset
    base = _api_for(args.repo, args.api)
    if args.cmd == "install":
        return install(args.rev, args.key, args.into)
    if args.cmd == "key-of":
        commit = subprocess.run(["git", "rev-parse", "--verify", "--quiet", args.rev + "^{commit}"], capture_output=True, text=True).stdout.strip()
        key = key_of(commit) if commit else None
        if key is None:
            return 1
        print(key)
        return 0
    if args.cmd == "probe":
        return 0 if _asset_there(_asset_url(args.key)) else 1
    if args.cmd == "route":
        return route(args.dirty, args.head_key, args.base_key)
    if args.cmd == "fetch":
        return fetch(base, args.key, args.dest)
    if args.cmd == "latest":
        return fetch_latest(base, args.dest)
    return publish(base, args.key, args.path)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
