#!/usr/bin/env python3
"""Native fixture-app startup and manual-fact storage; not NLP evaluation."""
import json
import pathlib
import subprocess
import tempfile


BINARY = pathlib.Path(__file__).parent / "src/main"


def main():
    with tempfile.TemporaryDirectory(prefix="avra-personal-app-") as directory:
        root = pathlib.Path(directory)
        database, request_file = root / "graph.db", root / "request.json"

        def call(request, success=True):
            request_file.write_text(json.dumps(request))
            result = subprocess.run(
                [str(BINARY), "request", "--db", str(database), str(request_file)],
                text=True, capture_output=True, timeout=15,
            )
            assert (result.returncode == 0) == success, (result.stdout, result.stderr)
            return json.loads(result.stdout)

        schema = call({"op": "schema"})
        models = {model["name"]: model for model in schema["models"]}
        personal = {"Pet", "Appointment", "Trip", "TravelBooking", "Event", "PersonalTask", "Commitment"}
        assert personal <= models.keys()
        assert all(models[name]["description"] for name in personal)
        assert len(models["PersonalTask"]["properties"]) == 9
        source = {
            "contract": 1, "source": {"observation": "manual-witness", "revision": 1},
            "received_at_ms": 1, "media_type": "text/plain", "author": None,
            "authored_at_ms": None,
            "content": "Fig has a confirmed check-up. Rowan promised to book dinner.",
        }
        admitted = call({"op": "ingest", "source": source})
        records = [
            {"id": "rowan", "model": "Person", "value": {"name": "Rowan Vale"}},
            {"id": "fig", "model": "Pet", "value": {"name": "Fig", "species": "cat", "owner": "rowan"}},
            {"id": "vet", "model": "Appointment", "value": {
                "pet": "fig", "purpose": "check-up", "status": "confirmed",
                "scheduled_at_ms": 1792148400000,
            }},
            {"id": "dinner", "model": "PersonalTask", "value": {
                "summary": "Book dinner", "assignee": "rowan", "status": "promised",
                "requested_reservation_at_ms": 1792783800000,
            }},
        ]
        publication = {
            "op": "publish", "id": "manual", "producer": "smoke", "scope": "all",
            "input": "manual-witness", "input_revision": 1,
            "schema": schema["fingerprint"], "expected_revision": admitted["graph_revision"],
            "records": records,
        }
        published = call(publication)
        assert call(publication) == published
        assert call({"op": "value", "id": "vet"})["attended"] is None
        assert call({"op": "value", "id": "vet"})["diagnosis"] is None
        task = call({"op": "value", "id": "dinner"})
        assert task["status"] == "promised" and task["completed_at_ms"] is None
        assert task["confirmation_recorded"] is None
        assert "confirmation_recorded" not in call({"op": "get", "id": "dinner"})["fields"]
        invalid = {**records[-1], "value": {**records[-1]["value"], "completed_at_ms": 1}}
        refused = call({**publication, "id": "invalid", "expected_revision": published["revision"],
                        "records": [invalid]}, success=False)
        assert "completion time" in refused["error"]
        assert call({"op": "schema"})["revision"] == published["revision"]
    print("personal fixture app: schema, restart, manual facts, unknowns and refusal passed")


if __name__ == "__main__":
    main()
