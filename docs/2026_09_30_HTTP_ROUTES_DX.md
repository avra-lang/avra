# HTTP routes: typed functions, one import, no ceremony

**Status:** design, 2026-09-30, not scheduled. Sub-epic of the HTTP
epic `avra-8sb5.1`. Validation is `docs/2026_09_30_STD_VALIDATE.md`.

## 1. The shape

The server block, groups and middleware stay. A route can also be a
typed function, and its signature is its contract.

```avra
use @std.http

type Idea = { @length(1, 200) title: string, votes: int = 0 }

enum IdeaError {
    @status(404) Missing
    @status(409) Duplicate(title: string)
}

export server app {
    port: 443
    tls: cert("certs/site.pem")
    cors: ["https://app.example"]
    compress: true
    guarded                                   // middleware on everything
    static "/assets" from "public/"

    get "/health" { _req -> "ok" }            // inline routes stay

    group "/api" {
        authed                                // middleware on this group
        rate: 100 per minute
        idea
        add
        list
    }
}

@get("/ideas/{id}")
fn idea(id: IdeaId) -> Idea? { ideas.find(id) }

@post("/ideas")
fn add(idea: Idea, user: Session<User>) -> Result<Created<Idea>, IdeaError> {
    ideas.add(idea, by: user)?
}

@get("/ideas")
fn list(page: int = 1, tag: string? = null) -> List<Idea> { ideas.page(page, tag) }
```

## 2. What the signature decides

| part | rule |
|---|---|
| path `{id}` | must name a parameter; the parameter's type parses it |
| a record parameter | is the body, decoded and validated by `@std/validate`; a refusal is a 400 listing every issue |
| a defaulted scalar | is a query parameter |
| a `Session<User>`, `Bearer`, `Header<"x">` | is extracted by a trait; a route nothing can extract for does not compile |
| `T` | 200 with `T` encoded by the negotiated codec |
| `T?` | 404 when null |
| `Created<T>` | 201 and `Location` |
| `Result<T, E>` | E's `@status` picks the status |
| `Stream<T>` | SSE or NDJSON by `Accept` |

A group lists middleware and routes in order; a route function lands at
its group's prefix. The inline `get "/x" { … }` is the same typed
function, anonymous.

## 3. One declaration, every projection

- a plain call in tests: `idea(IdeaId(1))`, no socket
- a typed client: `let api = client(app, "https://…")`, then `api.idea(IdeaId(7))?`
- OpenAPI with every rule
- typed links: `link(idea, id: 7)` does not compile for a missing route
- an MCP tool per route (the UI epic's agent door)
- the client-side validator, identical messages

## 4. The client

The spec's shape, with defaults: `http.get(url)?`, a default pool and
verified TLS. `Options` only when you mean it.

## 5. What goes away

`limits(), timing()`, `netted`, `tls_carried`, `json_body(req, T.from_json)`,
`Response.json(v.to_json())`, six submodule imports.

## 6. Prerequisites

- `export use` (avra-8sb5.10.6), for `use @std.http`.
- Trait impls over generic types (F2031), for `Respond` on `Created<T>`,
  `Result<T, E>`, `Stream<T>`.
- Codec derivation at a seat: the compiler mints a type's decoder where
  a route needs it.
- Fn annotations that register a route with a group.
