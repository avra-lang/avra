"""The pinned local models; one definition for the cascade and its calibration."""
ENCODERS = {
    "large": "fastino/gliner2-large-v1@d7aa8a2850d175a9227ff80358ea380723d03ad2",
    "base": "fastino/gliner2-base-v1@f9634218e53580c56edf0de97ca1a7d3f1c2354e",
}
ENCODER = ENCODERS[__import__("os").environ.get("CASCADE_ENCODER", "large")]
SCORER = "mlx-community/Qwen3-4B-Instruct-2507-4bit@50d427756c6b1b2fe0c0a10f67fbda1fc8e82c1b"
MODEL_ID = f"{ENCODER}+{SCORER}"


def parameter(name):
    """An engineering bound from service_parameters.json, never a literal in code."""
    import json
    import os

    return json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "service_parameters.json")))[name]["value"]
