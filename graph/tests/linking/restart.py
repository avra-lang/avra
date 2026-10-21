#!/usr/bin/env python3
"""Run the public linking API in independent native processes on a private file."""
import os
import pathlib
import sqlite3
import subprocess
import tempfile


BINARY = pathlib.Path(__file__).parent / "src/main"


def run(database, stage, expected):
    result = subprocess.run(
        [str(BINARY)],
        env={**os.environ, "GRAPH_LINK_DB": str(database), "GRAPH_LINK_STAGE": stage},
        text=True, capture_output=True, timeout=15,
    )
    assert result.returncode == 0, (result.stdout, result.stderr)
    assert result.stdout.strip() == expected, (result.stdout, expected)


def snapshot(database):
    with sqlite3.connect(database) as connection:
        assert connection.execute("PRAGMA integrity_check").fetchone() == ("ok",)
        return list(connection.iterdump())


def main():
    with tempfile.TemporaryDirectory(prefix="avra-exact-links-") as directory:
        database = pathlib.Path(directory) / "graph.db"
        run(database, "seed", "seeded")
        before = snapshot(database)
        run(database, "probe", "linked 1 false")
        assert snapshot(database) == before, "linking mutated persisted state"
        run(database, "revise", "revised")
        before = snapshot(database)
        run(database, "probe", "linked 2 true")
        run(database, "probe", "linked 2 true")
        assert snapshot(database) == before, "continuity lookup mutated persisted state"
    print("native linking restart: current and same-stream historical associations; no writes")


if __name__ == "__main__":
    main()
