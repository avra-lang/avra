"""Witnesses for the time-candidate generator: fixed anchors, gold picked."""
import datetime
import unittest

import timex

TUESDAY = int(datetime.datetime(2026, 10, 20, 9, 30, tzinfo=datetime.timezone.utc).timestamp() * 1000)
THURSDAY = int(datetime.datetime(2026, 10, 22, 16, 5, tzinfo=datetime.timezone.utc).timestamp() * 1000)


def pick(options, value):
    """A stand-in for the closed choice: the option whose value is gold."""
    return next(i for i, o in enumerate(options) if o["normalization"] and o["normalization"]["value"] == value)


class Candidates(unittest.TestCase):
    def test_next_friday_depends_on_the_anchor(self):
        tuesday = timex.candidates(TUESDAY, window_days=10)
        thursday = timex.candidates(THURSDAY, window_days=10)
        self.assertNotEqual([o["label"] for o in tuesday], [o["label"] for o in thursday])
        # Gold for "next Friday", as the fixture reads it: from Tuesday 20 Oct
        # the Friday of that week; from Thursday 22 Oct the Friday after.
        on_tuesday = timex.chosen(tuesday, pick(tuesday, "2026-10-23"))
        on_thursday = timex.chosen(thursday, pick(thursday, "2026-10-30"))
        self.assertEqual(on_tuesday["value"], "2026-10-23")
        self.assertEqual(on_thursday["value"], "2026-10-30")
        self.assertEqual(on_tuesday["reference"], "2026-10-20T09:30:00Z")
        self.assertEqual(on_thursday["reference"], "2026-10-22T16:05:00Z")
        self.assertEqual(thursday[pick(thursday, "2026-10-30")]["label"], "Friday 30 October 2026")

    def test_window_and_order(self):
        options = timex.candidates(TUESDAY, window_days=3)
        dates = [o["normalization"]["value"] for o in options if o["normalization"] and o["normalization"]["timex_type"] == "DATE"]
        self.assertEqual(dates, ["2026-10-17", "2026-10-18", "2026-10-19", "2026-10-20", "2026-10-21", "2026-10-22", "2026-10-23"])
        self.assertEqual(options[-3]["normalization"]["timex_type"], "TIME")
        self.assertEqual(options[-3]["normalization"]["value"], "2026-10-20T09:30:00Z")
        self.assertEqual([o["label"] for o in options[-2:]], [timex.NOT_SPECIFIC, timex.UNKNOWN])
        self.assertIsNone(timex.chosen(options, len(options) - 1))

    def test_declared_window_is_the_default(self):
        default = timex.candidates(TUESDAY)
        days = timex.parameter("time_window_days")
        self.assertEqual(len(default), 2 * days + 1 + 3)

    def test_calendar_edges(self):
        new_year = int(datetime.datetime(2026, 12, 31, 23, 59, 59, 250000, tzinfo=datetime.timezone.utc).timestamp() * 1000)
        options = timex.candidates(new_year, window_days=1)
        self.assertEqual(options[2]["normalization"]["value"], "2027-01-01")
        self.assertEqual(options[3]["normalization"]["value"], "2026-12-31T23:59:59.250Z")
        before_epoch = timex.candidates(-86400000, window_days=0)
        self.assertEqual(before_epoch[0]["normalization"]["value"], "1969-12-31")
        with self.assertRaises(ValueError):
            timex.candidates(TUESDAY, window_days=-1)


if __name__ == "__main__":
    unittest.main()
