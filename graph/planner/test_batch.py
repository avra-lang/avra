"""Witnesses for the batched choice: several closed choices read from one prompt.

The batch is a speed path, never a different decision, so it is held to the
unbatched picks. The weighing chooser below needs no model; the same letters
read by the real scorer's one prompt are held apart, and skipped where no
scorer can load (python3 test_batch.py).
"""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "extract"))

ASKS = [("Which kind of record holds the answer?", ["p: one kind", "q: another kind", "r: a third"]),
        ("Which of these narrows the records?", ["its name contains 'w'", "no narrowing"])]


def argmax(probabilities):
    return max(range(len(probabilities)), key=probabilities.__getitem__)


class Weighing:
    """A chooser that weighs an option's own text, with a bonus for where it is listed."""

    def __init__(self, bonus=0.0):
        self.bonus, self.asked = bonus, []

    def weigh(self, options):
        raw = [max(1, sum(map(ord, o)) % 17) + self.bonus * (len(options) - i) for i, o in enumerate(options)]
        total = float(sum(raw))
        return [r / total for r in raw]

    def choose(self, context, question, options):
        self.asked.append(tuple(options))
        return self.weigh(options)


class Batcher(Weighing):
    """The same chooser with the one ask: every item's options weighed as given."""

    def choose_many(self, items):
        self.asked.append(tuple(tuple(item["options"]) for item in items))
        return [self.weigh(item["options"]) for item in items]


class Batched(unittest.TestCase):
    def test_one_ask_picks_what_each_ask_picks_alone(self):
        import structured

        apart, together = Batcher(bonus=3.0), Batcher(bonus=3.0)
        alone = [structured.best(apart, "ctx", question, options) for question, options in ASKS]
        self.assertEqual(structured.best_many(together, "ctx", ASKS), alone)

    def test_the_one_ask_holds_every_ask_and_its_reverse(self):
        import structured

        together = Batcher()
        structured.best_many(together, "ctx", ASKS)
        listed = tuple(tuple(options) for _, options in ASKS)
        self.assertEqual(together.asked, [listed + tuple(tuple(options[::-1]) for _, options in ASKS)])

    def test_a_chooser_with_no_batch_asks_each_and_picks_the_same(self):
        import structured

        apart, together = Batcher(bonus=3.0), Weighing(bonus=3.0)
        alone = [structured.best(apart, "ctx", question, options) for question, options in ASKS]
        self.assertEqual(structured.best_many(together, "ctx", ASKS), alone)
        self.assertEqual(apart.asked, together.asked)

    def test_an_ask_with_one_option_is_no_choice(self):
        import structured

        together = Batcher()
        self.assertEqual(structured.best_many(together, "ctx", ASKS + [("Which?", ["only"])]), [1, 1, 0])


class Letters(unittest.TestCase):
    """The same items, read by the scorer's one prompt and one at a time."""

    ITEMS = [{"context": "Match (n0:A)-[:r]->(n1:B). So far: an A.", "question": ASKS[0][0], "options": ASKS[0][1]},
             {"context": "Match (n0:A)-[:r]->(n1:B). So far: an A.", "question": ASKS[1][0], "options": ASKS[1][1]}]

    @classmethod
    def setUpClass(cls):
        try:
            import mlx_lm  # noqa: F401
        except ImportError:
            raise unittest.SkipTest("no scorer here: the batched letters need mlx")
        import cascade

        cls.cascade, cls.scorer = cascade, cascade.Scorer()

    def test_the_one_prompt_reads_the_letter_each_choice_reads_alone(self):
        alone = []
        for item in self.items():
            self.scorer.cache = None
            alone.append(chosen(self.scorer.choose(item["context"], item["question"], item["options"])))
        self.scorer.cache, self.scorer.held = None, []
        introduced = [chosen(p) for p in self.scorer.pick_many(self.items())]
        self.assertEqual(introduced, alone)

    def test_every_item_costs_one_pass_and_no_more(self):
        self.scorer.cache, self.scorer.held, self.scorer.calls = None, [], 0
        self.scorer.pick_many(self.items())
        self.assertEqual(self.scorer.calls, len(self.items()))

    @classmethod
    def items(cls):
        return [dict(item) for item in cls.ITEMS]


def chosen(probabilities):
    return "ABCDEFGHIJKLMNOPQRSTUVWXYZ"[argmax(probabilities)]


if __name__ == "__main__":
    unittest.main()
