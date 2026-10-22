"""The extractor's identity ignores the planner-only service ops."""
import json
import os
import shutil
import tempfile
import unittest

import identity


class PlannerOps(unittest.TestCase):
    def test_editing_the_planner_ops_leaves_the_identity_unchanged(self):
        before = json.dumps(identity.identity(), sort_keys=True)
        self.assertNotIn("planning_ops", identity.closure())
        here = tempfile.mkdtemp()
        for name in os.listdir(identity.HERE):
            if name.endswith((".py", ".json")):
                shutil.copy(os.path.join(identity.HERE, name), here)
        with open(os.path.join(here, "planning_ops.py"), "a") as f:
            f.write("\n# edited\n")
        saved, identity.HERE = identity.HERE, here
        try:
            after = json.dumps(identity.identity(), sort_keys=True)
        finally:
            identity.HERE = saved
        self.assertEqual(before, after)

    def test_editing_the_cascade_moves_it(self):
        here = tempfile.mkdtemp()
        for name in os.listdir(identity.HERE):
            if name.endswith((".py", ".json")):
                shutil.copy(os.path.join(identity.HERE, name), here)
        with open(os.path.join(here, "cascade.py"), "a") as f:
            f.write("\n# edited\n")
        saved, identity.HERE = identity.HERE, here
        try:
            moved = json.dumps(identity.identity(), sort_keys=True)
        finally:
            identity.HERE = saved
        self.assertNotEqual(moved, json.dumps(identity.identity(), sort_keys=True))


if __name__ == "__main__":
    unittest.main()
