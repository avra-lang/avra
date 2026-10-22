"""What decides an extraction's bytes, as one JSON value: the models, the
fitted parameters, the engineering bounds, the environment the cascade reads
and the code it runs. Two runs with equal identities produce equal results
from equal sources; a cache keyed by it cannot serve a stale entry."""
import ast
import hashlib
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ENTRY = "cascade.py"
LOGGING_ONLY = {"CASCADE_TRACE", "CASCADE_DECISIONS"}
# Programs the service imports to answer planner ops. An extraction never calls
# them, so their code decides no extraction's bytes and stays out of the identity.
SERVES_PLANNER_ONLY = {"planning_ops"}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def named_modules(path):
    """Local programs a file names: an import, or a string literal naming a
    sibling program it launches."""
    names = set()
    for node in ast.walk(ast.parse(open(path).read())):
        if isinstance(node, ast.Import):
            names.update(a.name.split(".")[0] for a in node.names)
        elif isinstance(node, ast.ImportFrom) and node.module and not node.level:
            names.add(node.module.split(".")[0])
        elif isinstance(node, ast.Constant) and isinstance(node.value, str) and node.value.endswith(".py"):
            names.add(node.value[:-3])
    return {n for n in names if os.path.exists(os.path.join(HERE, n + ".py"))}


def closure(entry=ENTRY):
    """Every local program the entry can reach, entry included, sorted."""
    seen, todo = set(), [entry[:-3]]
    while todo:
        name = todo.pop()
        if name not in seen:
            seen.add(name)
            todo.extend(named_modules(os.path.join(HERE, name + ".py")) - SERVES_PLANNER_ONLY)
    return sorted(seen)


def identity():
    import pins

    params = os.environ.get("CASCADE_PARAMS", os.path.join(HERE, "params.json"))
    return {
        "models": {"encoder": pins.ENCODER, "scorer": pins.SCORER},
        "params": digest(open(params, "rb").read()),
        "bounds": digest(open(os.path.join(HERE, "service_parameters.json"), "rb").read()),
        "env": {k: v for k, v in sorted(os.environ.items()) if k.startswith("CASCADE_") and k not in LOGGING_ONLY},
        "code": {n: digest(open(os.path.join(HERE, n + ".py"), "rb").read()) for n in closure()},
    }


if __name__ == "__main__":
    print(json.dumps(identity(), indent=1, sort_keys=True))
