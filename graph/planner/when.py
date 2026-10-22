"""The time a question asks about, chosen by calendar containment.

The model never writes a date. Anchored on the instant the question was asked,
it chooses the asking instant or a year around it, then narrows through the
calendar, taking at each step the whole span or one part: a month of the year,
a week touching the month, a day of the week. Every option is calendar arithmetic labelled with the standard
library's names; nothing here lists words. The answer is a half-open UTC
millisecond range with its TIMEX3 value, or None when the question asks about
the time it was asked.
"""
import datetime
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "extract"))
import timex  # noqa: E402
from catalog import PARAMETERS  # noqa: E402
from structured import best  # noqa: E402

NOW = "the time it was asked: the answer holds now"


def ms(at):
    return int(at.timestamp() * 1000)


def span(start, end, value, zone):
    """A local calendar span as a half-open UTC millisecond range and its TIMEX3 value."""
    begin = datetime.datetime.combine(start, datetime.time(), zone)
    finish = datetime.datetime.combine(end, datetime.time(), zone)
    return {"value": value, "start_ms": ms(begin), "end_ms": ms(finish)}


def year_span(year, zone):
    return span(datetime.date(year, 1, 1), datetime.date(year + 1, 1, 1), str(year), zone)


def month_span(year, month, zone):
    after = datetime.date(year + month // 12, month % 12 + 1, 1)
    return span(datetime.date(year, month, 1), after, f"{year}-{month:02d}", zone)


def week_span(monday, zone):
    iso = monday.isocalendar()
    return span(monday, monday + datetime.timedelta(days=7), f"{iso[0]}-W{iso[1]:02d}", zone)


def day_span(day, zone):
    return span(day, day + datetime.timedelta(days=1), day.isoformat(), zone)


def weeks_of(year, month):
    """The Mondays of every ISO week that touches the month."""
    first = datetime.date(year, month, 1)
    last = datetime.date(year + month // 12, month % 12 + 1, 1) - datetime.timedelta(days=1)
    monday = first - datetime.timedelta(days=first.weekday())
    out = []
    while monday <= last:
        out.append(monday)
        monday += datetime.timedelta(days=7)
    return out


def week_label(monday):
    sunday = monday + datetime.timedelta(days=6)
    return f"the week of {timex.day_label(monday)} to {timex.day_label(sunday)}"


def narrowed(chooser, trail, whole, parts):
    """The whole span (index -1) or one of its parts (its index)."""
    return best(chooser, trail, "Which part of that time?", [f"all of {whole}"] + parts) - 1


def asked_time(chooser, question, now_ms, timezone=None):
    """The calendar span the question's answer must hold over, or None for the asking instant."""
    zone = timex.zone_of(timezone) or datetime.timezone.utc
    local = timex.anchor_of(now_ms).astimezone(zone)
    note = "" if timex.zone_of(timezone) else f" ({timex.UNKNOWN_ZONE})"
    trail = (f"Question: {question}\n"
             f"Asked {local.strftime('%H:%M')} on {timex.day_label(local.date())}{note}.")
    reach = PARAMETERS["question_years"]
    years = list(range(local.year - reach, local.year + reach + 1))
    pick = best(chooser, trail, "What time must the answer hold at?", [NOW] + [str(y) for y in years])
    if pick == 0:
        return None
    year = years[pick - 1]
    months = list(range(1, 13))
    m = narrowed(chooser, trail, str(year), [datetime.date(year, n, 1).strftime("%B %Y") for n in months])
    if m < 0:
        return year_span(year, zone)
    month = months[m]
    mondays = weeks_of(year, month)
    w = narrowed(chooser, trail, datetime.date(year, month, 1).strftime("%B %Y"), [week_label(d) for d in mondays])
    if w < 0:
        return month_span(year, month, zone)
    monday = mondays[w]
    days = [monday + datetime.timedelta(days=i) for i in range(7)]
    d = narrowed(chooser, trail, week_label(monday), [timex.day_label(x) for x in days])
    return week_span(monday, zone) if d < 0 else day_span(days[d], zone)
