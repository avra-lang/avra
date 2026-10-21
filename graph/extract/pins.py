"""The pinned local models; one definition for the cascade and its calibration."""
ENCODER = "fastino/gliner2-large-v1@d7aa8a2850d175a9227ff80358ea380723d03ad2"
SCORER = "mlx-community/Qwen3-4B-Instruct-2507-4bit@50d427756c6b1b2fe0c0a10f67fbda1fc8e82c1b"
MODEL_ID = f"{ENCODER}+{SCORER}"
