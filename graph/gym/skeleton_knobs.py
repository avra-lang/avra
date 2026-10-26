"""Gym parameters, each declared with its provenance in knobs.json."""
import json
import pathlib

KNOBS = {k: v["value"] for k, v in json.loads((pathlib.Path(__file__).with_name("knobs.json")).read_text()).items()}
