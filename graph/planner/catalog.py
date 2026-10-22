"""The catalog as the planner reads it: model descriptors from the graph's
`schema` op, their reference shapes and declared relation bindings; and the
planner's parameters, each with the declaration it comes from."""
import json
import pathlib

PARAMETERS = {k: v["value"] for k, v in
              json.loads((pathlib.Path(__file__).with_name("parameters.json")).read_text()).items()}


class Refusal(Exception):
    """A draft the graph refuses: its problem code and message."""

    def __init__(self, code, message):
        super().__init__(f"{code}: {message}")
        self.code, self.message = code, message


def models_of(schema):
    """The catalog's model descriptors from a `schema` op answer or a bare list."""
    models = schema.get("models", schema) if isinstance(schema, dict) else schema
    return {m["name"]: m for m in models}


def base_shape(shape):
    while isinstance(shape, dict) and "optional" in shape:
        shape = shape["optional"]
    return shape


def reference_target(shape):
    shape = base_shape(shape)
    if isinstance(shape, dict) and "list" in shape:
        shape = base_shape(shape["list"])
    return shape.get("reference") if isinstance(shape, dict) else None


def relation_words(model):
    """(word, forward) for every relationship type a relation binding declares."""
    relation = ((model.get("semantics") or {}).get("relation")) or {}
    for label in relation.get("labels", []):
        for word in [label["value"], *label.get("forward", [])]:
            yield word.lower(), True
        for word in label.get("reverse", []):
            yield word.lower(), False


def relation_ends(model):
    relation = ((model.get("semantics") or {}).get("relation")) or {}
    ends = [relation.get("from") or [], relation.get("to") or []]
    if any(len(path) != 1 for path in ends):
        return None
    props = {p["name"]: p for p in model["properties"]}
    targets = [reference_target(props[path[0]]["shape"]) if path[0] in props else None for path in ends]
    return None if None in targets else targets
