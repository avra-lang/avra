"""The schema author: the hosted model writes an invented domain's models in
the real declaration form, the real compiler judges them, and the catalog it
emits is measured against the required hard structure. The reference the
author reads is the engine's own declarations."""
import json
import pathlib
import random
import re
import subprocess

import contam
import features
from cat import Cat
from engine import App
from skeleton_knobs import KNOBS

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
GRAPH = ROOT / "graph"
REFERENCE = [GRAPH / "src/semantics.av", GRAPH / "examples/notes/src/models.av", GRAPH / "acceptance/app/src/models/people.av"]
NOTES = GRAPH / "examples/notes"


def reference_text():
    return "\n\n".join(f"// ---- {p.relative_to(GRAPH)}\n{p.read_text()}" for p in REFERENCE)


def prompt_for(domain_hint, requirements, avoid, feedback):
    wants = "\n".join(f"- at least {n}: {features.definition(k)}" for k, n in requirements.items() if n)
    ban = f"\nThe domain must be unlike: {', '.join(sorted(avoid))}." if avoid else ""
    return (f"You author the data model of an invented domain for a graph database, as Avra declarations in exactly the form of the reference below.\n"
            f"Invent a specific, realistic domain (a workplace, club, service or project); {domain_hint}.{ban}\n"
            f"Write one file, models.av, whose first line is `// domain: <the domain's name>`, then its `use` lines, its embedded models, its documented models (a `///` comment on each model saying what a record means and what an unrecorded value means) "
            f"and the final `export collect models` line. Use the binding types of semantics.av for relations, validity, quantities, times, absences and labels. "
            f"Every name and word is your own invention for this domain; reuse no name from the reference.\n"
            f"The compiled catalog must show:\n{wants}\n{feedback}\n"
            f"Reply with the file's contents only.\n\nREFERENCE\n{reference_text()}")


def package(directory, models_text, name):
    d = pathlib.Path(directory)
    (d / "src").mkdir(parents=True, exist_ok=True)
    (d / "src/models.av").write_text(models_text)
    (d / "src/main.av").write_text((NOTES / "src/main.av").read_text())
    toml = (NOTES / "avra.toml").read_text()
    toml = re.sub(r'name = "graph_notes_example"', f'name = "{name}"', toml)
    toml = re.sub(r'name = "graph-notes"', f'name = "{name}"', toml)
    toml = toml.replace('path = "../.."', f'path = "{GRAPH}"').replace('path = "../../../packages/', f'path = "{ROOT}/packages/')
    (d / "avra.toml").write_text(toml)
    return d / "src/main"


def compile_package(directory, timeout=None):
    done = subprocess.run(["sh", "tools/watch.sh", "3500", "./build/avra", "build", str(directory)], cwd=ROOT, text=True, capture_output=True, timeout=timeout)
    text = done.stdout + done.stderr
    if "refusing to start" in text:
        raise SystemExit("gym: the build lock refused to start (disk or memory floor): " + " ".join(text.split())[:200])
    binary = pathlib.Path(directory) / "src/main"
    errors = [l for l in text.splitlines() if re.match(r"^error", l)]
    detail = "\n".join(text.splitlines()[:60]) if errors else ""
    return (binary if done.returncode == 0 and binary.exists() and not errors else None), (detail or text[-1500:])


def clean_reply(text):
    text = text.strip()
    m = re.search(r"```(?:\w+)?\n(.*?)```", text, re.S)
    return m.group(1) if m else text


def author(llm, d, name, rng, avoid_domains=(), tries=5):
    """models.av text and the catalog it compiles to, or SystemExit after `tries` rounds."""
    requirements = dict(KNOBS["required_structure"])
    if rng.random() < KNOBS["lookalike_relations_rate"]:
        requirements["lookalike_relation_pairs"] = 1
    hint = f"it should start with a letter from {', '.join(sorted(rng.sample('ABCDEFGHIJKLMNOPRSTW', 4)))}"
    feedback, last = "", ""
    for attempt in range(tries):
        text = clean_reply(llm.generate(prompt_for(hint, requirements, avoid_domains, feedback), 6000))
        provenance = dict(llm.last)
        bad = sorted(contam.words(text) & contam.FIXTURE_WORDS)
        if bad:
            feedback = f"\nYour previous file used fixture names {bad}; invent other names.\nPrevious file:\n{text}"
            continue
        package(d, text, name)
        binary, detail = compile_package(d)
        if not binary:
            feedback = f"\nYour previous file did not compile:\n{detail}\nPrevious file:\n{text}\nFix it."
            continue
        catalog = App(binary, d / "probe.db", d).call({"op": "schema"})
        gaps = features.unmet(Cat(catalog), requirements)
        if gaps:
            feedback = f"\nYour previous file compiled but lacks required structure (have, need): {gaps}.\nPrevious file:\n{text}\nRevise it."
            last = text
            continue
        return text, catalog, provenance
    raise SystemExit(f"gym: {name}: no compiling schema with the required structure after {tries} rounds")
