# PLATFORM_MAP — the app framework, declared and derived

**What this is.** One page of everything Avra plans to do that Rails,
NestJS, Phoenix, Django and Laravel do, and where each piece is
designed in detail. This page holds no design. It points. Epic
`avra-8sb5.64`.

**Status words:** **built** (on main) · **building** (a lane is on it) ·
**designed** (a doc exists, no code) · **gap** (no doc yet).
**Doc state:** *(draft)* = uncommitted in main's checkout; *(landing)* =
committed on a branch in the landing train.

## 1. The idea

Declare a thing once. Everything else is derived from it, and any
derived piece can be overridden where you want it different.

```avra
@model type Order = { @range(1, 99) qty: int, … }     // the data
@action fn place(o: Order) -> Created<Order> { … }    // the behaviour
```

From those two declarations: a table and its migrations, a validated
HTTP route, a form and its error slots, a CLI command, an MCP tool for
agents, an admin screen, a typed client, OpenAPI, docs and test
factories. Each is a **projection**, and a projection is free because
the compiler already holds the facts (P10, P12).

## 2. The map

### Language foundations

| area | status | detail |
|---|---|---|
| Components: a library's block syntax (`server app { … }`) | built | `docs/2026_09_23_COMPONENT_EXPANSION.md`, `avra-8sb5.33` |
| Derives and projections in the compiler | built | `docs/2026_09_26_ADDING_A_PROJECTION.md` |
| Errors: one `Error` trait, unions, `catch` | building | `docs/2026_09_25_ERROR_UNIONS_PHASE{1,2}_DESIGN.md`, `avra-8sb5.40` |
| Fibers and cores: `spawn`, `Task`, one process per core | built | `docs/2026_09_22_FIBERS_DESIGN.md` |
| Laws, fork-join, SIMD, GPU | designed | `docs/2026_09_22_BEND_LAWS_PARALLEL_AND_BEYOND.md` |
| The runtime in Avra | designed | `docs/2026_09_30_AVRA_ALL_THE_WAY_DOWN.md` *(landing)*, `avra-8sb5.62` |

### Data

| area | status | detail |
|---|---|---|
| Models (`@model`), relations, typed queries, migrations | building | `docs/2026_09_24_ORM.md` *(draft)*, `avra-8sb5.44` |
| State at every scale; the database as constitution | designed | `docs/2026_09_24_AUTONOMOUS_SYSTEMS_AND_STATE.md` *(draft)* |
| Validation for every format | building | `docs/2026_09_30_STD_VALIDATE.md` *(landing)*, `avra-8sb5.63` |
| JSON, TOML, SQLite | built | `@std/json`, `@std/toml`, `@std/sqlite` |

### Web

| area | status | detail |
|---|---|---|
| HTTP/1.1, HTTP/2, HTTPS, streaming, SSE, WebSocket, client | built / landing | `docs/2026_09_29_HTTP_ROADMAP.md`, `avra-8sb5.1` |
| Typed route functions, settings not builders, one import | designed | `docs/2026_09_30_HTTP_ROUTES_DX.md` *(landing)*, `avra-8sb5.1.33` |
| Cookies, static files, compression, CORS | building | HTTP roadmap H6, `avra-8sb5.1.29` |
| Realtime pub/sub (Phoenix Channels, ActionCable) | gap | `avra-8sb5.64.3` |

### Behaviour

| area | status | detail |
|---|---|---|
| Actions, impact, safeguards, receipts (authorization) | designed | `docs/2026_09_29_AUTHORITY_AND_RECEIPTS.md` *(draft)* |
| Authentication: sessions, OAuth, passkeys, API keys | gap | `avra-8sb5.64.4` |
| Jobs, queues, retries, cron | gap | `avra-8sb5.64.1` |
| Mail, file storage, caching | gap | `avra-8sb5.64.5` |

### Surfaces (the projections)

| area | status | detail |
|---|---|---|
| UI on every surface: web, iOS, Android, terminal | designed | `docs/2026_09_29_UI.md`, `docs/2026_09_29_UI_TOUR.md`, `docs/2026_09_29_WEB_UI.md` *(draft)*, `avra-8sb5.59` |
| Forms and actions with no JS; MCP tools from actions | designed | UI doc, `avra-8sb5.59.5`, `.59.7` |
| CLI: `cli app { command … }` | built | `@std/cli` |
| Derived admin UI | gap | `avra-8sb5.64.6` |
| Docs as a compile target | building | `docs/2026_09_24_DOCUMENTATION.md`, `avra-8sb5.7` |

### Across machines

| area | status | detail |
|---|---|---|
| One `spawn` / `parallel` with three placements: thread, process, machine | designed | Bend doc §7.3 |
| Typed channels and queues with a location (`order \|> orders`) | gap | `avra-8sb5.64.2` |

### Operations

| area | status | detail |
|---|---|---|
| Config, secrets, feature flags, i18n | gap | `avra-8sb5.64.7` |
| Observability: request ids, logs, traces | designed | HTTP roadmap H6, `avra-8sb5.1.29.8` |
| Deploy: one binary, the manifest as a projection, no container required | gap | `avra-8sb5.64.9` |

### Testing

| area | status | detail |
|---|---|---|
| spec/given/then, program tests, eval == native | built | CLAUDE.md |
| Laws with shrunk counterexamples | designed | Bend doc §3 |
| Factories, request specs, fixed time | gap | `avra-8sb5.64.8` |

## 3. Against the mature frameworks

| capability | Rails | NestJS | Phoenix | Django | Avra |
|---|---|---|---|---|---|
| Routing | routes.rb | decorators | router | urls.py | typed fns in a server block |
| Models / ORM | ActiveRecord | TypeORM/Prisma | Ecto | ORM | `@model`, typed queries |
| Validation | model validations | class-validator | changesets | forms | `@std/validate`, rules in the type |
| Migrations | hand-written | hand-written | hand-written | generated | derived from the type diff |
| Background jobs | ActiveJob | BullMQ | Oban | Celery | gap |
| Realtime | ActionCable | gateways | Channels | Channels | gap (WebSocket built) |
| Auth | Devise | Passport | phx.gen.auth | built in | gap (authorization designed) |
| Admin | gems | — | — | built in | derived (gap) |
| API docs | gems | Swagger module | — | DRF | OpenAPI derived |
| Agent tools (MCP) | — | — | — | — | derived from actions |
| Typed client | — | — | — | — | derived from routes |
| Distribution | — | microservices module | BEAM | — | placements + typed channels |
| Deploy | Kamal | Docker | releases | — | one binary, derived manifest |

## 4. Open questions for the owner

1. Which gap first? Proposal: auth and jobs, since almost every app needs
   them, then realtime.
2. The network primitive's spelling: `|>` as a send, or a method
   (`orders.send(order)`)?
3. How far the admin goes: read-only by default, or full CRUD derived?
4. Containers: generate an OCI image from the manifest, or leave packaging
   to users?
