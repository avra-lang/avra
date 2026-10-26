"""The retrieval ops on their own socket, for a host that does not run the
cascade service (the same ops the cascade answers: link, retrieve, block).

usage: python serve.py [SOCKET]    (default ~/.cache/avra-graph-ml/retrieval.sock)
One JSON line in, one JSON line out, per connection. Holds only the embedder
and reranker; starts no generative model."""
import json
import os
import socket
import sys

import service

PATH = os.path.expanduser("~/.cache/avra-graph-ml/retrieval.sock")


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else PATH
    if os.path.exists(path):
        probe = socket.socket(socket.AF_UNIX)
        try:
            probe.connect(path)
            sys.exit(f"retrieval: a service already answers on {path}")
        except OSError:
            os.unlink(path)
        finally:
            probe.close()
    server = socket.socket(socket.AF_UNIX)
    server.bind(path)
    server.listen(8)
    while True:
        conn, _ = server.accept()
        with conn:
            data = b""
            while not data.endswith(b"\n"):
                chunk = conn.recv(65536)
                if not chunk:
                    break
                data += chunk
            try:
                out = service.answered(json.loads(data))
            except Exception as why:
                out = {"error": f"{type(why).__name__}: {why}"}
            conn.sendall((json.dumps(out) + "\n").encode())


if __name__ == "__main__":
    main()
