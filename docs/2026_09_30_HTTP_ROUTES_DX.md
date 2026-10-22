# HTTP routes: typed functions, one import, no ceremony

**Status:** design, 2026-09-30. Sub-epic of the HTTP epic `avra-8sb5.1`.
The router (§6) is implemented; the typed-fn route surface is not
scheduled. Validation is `docs/2026_09_30_STD_VALIDATE.md`.

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

## 6. A router is a library component

A router is a named group of routes with no prefix of its own, declared once
and listed by name wherever routes go:

```avra
router tasks {
    get "/" { _ -> tasks_all() }
    post "/" { req -> tasks_add(req.params) }
}

server site {
    routes: [tasks, admin]          // by name, in written order
}

group "/api" { tasks }              // the same router under a prefix
group "/v2" { tasks }               // and under another
```

A body of routes lists anything that is `Routes` — a route, a group (already
under its prefix), a router — so the slot is `List<dyn Routes>` and the trait
is the whole of the surface:

```avra
trait Routes { fn routes() -> List<Route> }
impl Routes for Route { … }         // one route stands for itself
impl Routes for Mounted { … }       // a group's routes, prefix already applied
impl Routes for router { … }        // a router gathers its own lines

fn mounted(routes: List<Route>) -> Mounted    // a list, as one item of a body
```

THE ELEMENT BEING A TRAIT AND NOT A COMPONENT IS WHAT KEEPS THE COMPILER OUT
OF IT, and that is why the router is a library component rather than language
surface. A component slot would need the compiler to route each component's
lines into the slot, and it cannot even see a component declared in another
file (`avra-8sb5.57.297`); a slot over a trait is ordinary typing, so a
router is declared once and listed wherever it is in scope — under one
prefix, two prefixes, or another router — with no language rule per shape.

What falls out:

- WRITTEN ORDER IS THE ORDER across routers, groups and routes in one slot —
  and specificity decides before it, so embedding a router never changes
  which route answers (`2026_09_06_STD_HTTP_TYPED_ROUTES.md`, "Routing is
  decided by specificity").
- A ROUTER CARRIES NO PREFIX. Prefixing is `group`'s; one router mounts at
  `/api/tasks` and `/v2/tasks` as two groups and its own lines are unchanged.
- A ROUTER IS A VALUE, BUILT ONCE at startup, so the `dyn` box costs nothing
  a request sees. `mounted(routes)` is how a list a fn built joins a body as
  one item, so no caller spells a wrapper type by name.

The `server`'s `routes` slot is `List<dyn Routes>` for the same reason, and a
caller that reads it back walks `gathered(web.routes)`. Implemented in
`packages/std-http/src/route.av` (PR #1103, `http-router`); witness
`tests/http_router` — a router at the server root, the same router under two
prefixes, a router nested in a router, and a miss answering 404.

## 7. Prerequisites

- `export use` (avra-8sb5.10.6), for `use @std.http`.
- Trait impls over generic types (F2031), for `Respond` on `Created<T>`,
  `Result<T, E>`, `Stream<T>`.
- Codec derivation at a seat: the compiler mints a type's decoder where
  a route needs it.
- Fn annotations that register a route with a group.
