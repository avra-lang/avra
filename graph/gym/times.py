"""Time encodings as the catalog declares them: how an instant is held in a property."""
import datetime

UTC = datetime.timezone.utc


def parse(text):
    t = text.strip().replace("Z", "+00:00")
    d = datetime.datetime.fromisoformat(t)
    return d if d.tzinfo else d.replace(tzinfo=UTC)


ENCODE = {
    "unix_millis": lambda d: int(d.timestamp() * 1000),
    "iso_date": lambda d: d.astimezone(UTC).strftime("%Y-%m-%d"),
    "iso_instant": lambda d: d.astimezone(UTC).strftime("%Y-%m-%dT%H:%M:%SZ"),
}
DECODE = {
    "unix_millis": lambda v: datetime.datetime.fromtimestamp(v / 1000, UTC),
    "iso_date": parse,
    "iso_instant": parse,
}


def encode(iso, encoding):
    return ENCODE[encoding](parse(iso))


def decode(value, encoding):
    return DECODE[encoding](value)


def day(value, encoding):
    return decode(value, encoding).strftime("%Y-%m-%d")


def shift(value, encoding, days):
    return ENCODE[encoding](decode(value, encoding) + datetime.timedelta(days=days))
