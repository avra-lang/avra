# @std/url

A URL as a value: read by RFC 3986, normalized when asked, resolved
against a base, percent-encoded one component at a time, and built up a
parameter at a time. Nothing is repaired behind a caller's back — every
refusal is a typed `UrlError` naming the octet where it stopped.

```avra
use @std.url.{UrlError, parse}

fn canonical(text: string) -> Result<string, UrlError> {
    let u = parse(text)?
    .Ok(u.normalized().text())
}
```

## The laws

- **OCTETS AS WRITTEN.** Every component keeps what arrived — escapes
  undecoded, case unfolded — except the scheme, which is
  case-insensitive and always lowercase. `normalized()` is the one door
  to the canonical form.
- **ABSENT IS NOT EMPTY.** `http://h?` carries an empty query and
  `http://h` none; a component never written is null.
- **STRICT, WITH TYPED REFUSALS.** An octet a component may not carry, a
  `%` opening no escape, a second `@`, an IPv6 zone, a port past 65535 —
  each is a `UrlError` at the octet. A reader that repairs and one that
  refuses disagree about what the text said, and that disagreement is how
  a URL walks one host past a check and connects to another.
- **A HOST THAT ENDS IN A NUMBER IS A DOTTED QUAD OR NOTHING.** `127.1`,
  `0x7f.1` and `2130706433` are names to RFC 3986 but addresses to the
  resolver, so only the strict quad is a `.V4` here; every other numeric
  spelling is refused.
- **`+` IS NOT A SPACE.** That is a form body's encoding, never a URI's:
  `decoded` leaves it alone and `encoded` writes a space as `%20`.
- **DECODE AFTER SPLITTING.** `%00` decodes to a real NUL and `%2F` to a
  `/`, so split on a component's separators first and decode the pieces
  after; what decoding mints can then never move a boundary.

## Surface

All of it is in `src/url.av`, imported as `@std.url`.

| Export | What it is |
|---|---|
| `Url` | An absolute reference: `scheme`, `authority`, `path`, `query`, `fragment`. |
| `Authority` | What follows `//`: `userinfo`, `host`, `port`. |
| `Host` | The host by the grammar that read it: `Name(b)`, `V4(b)`, `V6(b)` (bare, no brackets). |
| `Part` | What `encoded` encodes for, and what a refusal names: `Userinfo`, `Host`, `Path`, `Segment`, `Query`, `Param`, `Fragment`. |
| `UrlError` | Why text is not a URL, at the octet: `Relative`, `Scheme(at)`, `Octet(at, part)`, `Escape(at)`, `Host(at)`, `Port(at)`, `Dots`. Implements `Error`. |
| `parse(text)` | Text to `Result<Url, UrlError>`; the scheme is required. |
| `encoded(b, part)` | `b` with every octet the component does not carry escaped as `%XX` (uppercase). |
| `decoded(b)` | `b` with its escapes spent, or null when a `%` opens none. Octets with no `%` are answered as they arrived. |
| `default_port(scheme)` | 80 for `http`/`ws`, 443 for `https`/`wss`, else null. |

Methods:

| Method | What it does |
|---|---|
| `Url.text()` / `Url.bytes()` | The URL recomposed by RFC 3986 §5.3. |
| `Url.port()` | The port written, or the scheme's default. |
| `Url.hostname()` | The host as a resolver reads it: a name decoded, an address bare; null with no authority. |
| `Url.target()` | The origin-form for a request line: an empty path is `/`, and the fragment is never sent. |
| `Url.normalized()` | The canonical form (§6.2.2–3): host case folded, escapes in one spelling, dot segments spent, a default port dropped. |
| `Url.resolve(reference)` | `reference` resolved against this URL (RFC 3986 §5.2.2). |
| `Url.joined(segment)` | One more path segment, encoded so `/`, `?` and `#` in it are data; a `.` or `..` segment is refused. |
| `Url.with_param(name, value)` | One more query pair, name and value each encoded so `&`, `=`, `+` and `#` in them are data. |
| `Authority.bytes()` / `Authority.normalized(scheme)` | Recomposed / canonical. |
| `Host.bytes()` / `Host.named()` / `Host.normalized()` | Recomposed (IPv6 re-bracketed) / resolver text / canonical. |

## Percent-encoding, per component

`Part` picks the set of octets a component carries as themselves, and
`encoded` escapes every other one as `%XX` with uppercase hex. `%` is
never KEPT — an escape is judged whole — and `Host` is encoded by the
reg-name set. `Segment` is where `/` is data (one path segment),
`Path` where `/` is a separator; `Param` is one name or value of a query
pair, where `&`, `=` and `+` are data. `decoded` answers null on a
malformed escape and never treats `+` as a space.

## How `@std/http` shares it

The router (`@std.http.route`) keeps a capture as RAW OCTETS and never
decodes it: `%2F` must not become a `/` and re-frame the path. A
consumer that wants bytes decodes with `@std/url`'s `decoded` at the
point it asks (`query.av`, `files.av`, `form.av`). The client
(`@std.http.fetch`) parses the request URL with `parse`, derives the
authority field and the origin-form target from it, and encodes form
fields with `encoded(…, .Param)`. One percent-decoder and one
percent-encoder, in `@std/url`, for the whole stack.
