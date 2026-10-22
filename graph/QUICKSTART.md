# Quickstart

A graph application is two files: the models, and a host. Commands run from the
repository root. Marks: **ran** (executed here, output shown) or **not yet run**
(needs the local model service, which is busy training).

## 1. Declare models  (`examples/quickstart/src/models.av`, 15 lines)

```avra
use @avra.graph.{model, Ref, Registration, registered, Semantics, IdentityBinding, TimeBinding}
use @std.validate.{length, email}

@model(quote { Semantics {
    label: ["name"],
    identities: [IdentityBinding { namespace: "mail", path: ["email"], normalization: .AsciiLowerTrim }],
} })
export type Person = { @length(min: 1) name: string, @email email: string? }

@model(quote { Semantics { times: [TimeBinding { path: ["due_on"], encoding: .IsoDate }] } })
export type Chore = { @length(min: 1) title: string, owner: Ref<Person>?, due_on: string? }

export collect models: List<Registration> = @registered in package as Registration { make: it } by it.name
```

Everything the engine, extractor and planner know about your domain is in these
declarations: names, identities, which property is a date, relation words.
The host (`src/main.av`) is `exit(Exit.Code(run(models)))`.

## 2. Build  (**ran**)

```sh
sh tools/watch.sh 3500 ./build/avra build graph/examples/quickstart
```

## 3. Start the model service  (**not yet run**)

```sh
python3 graph/extract/cascade.py --serve     # keeps both models resident on a local socket
```

The extractor and the planner both share it. Without it the graph still stores,
searches, explains and answers hand-written queries (step 5).

## 4. Connect an assistant over MCP  (**not yet run**: the planner and extractor need step 3)

Claude Code:

```sh
claude mcp add graph -- "$PWD/graph/examples/quickstart/src/main" mcp --db "$HOME/graph.db" \
  --planner "python3 graph/planner/plan.py" \
  --extractor "python3 graph/extract/cascade.py --catalog {schema}" \
  --grantor owner --agent claude --grant ingest,correct
```

Any MCP client (stdio), same command:

```json
{ "mcpServers": { "graph": { "command": "/abs/path/graph/examples/quickstart/src/main",
  "args": ["mcp", "--db", "/abs/path/graph.db",
           "--planner", "python3 graph/planner/plan.py",
           "--extractor", "python3 graph/extract/cascade.py --catalog {schema}",
           "--grantor", "owner", "--agent", "assistant", "--grant", "ingest,correct"] } } }
```

The agent gets `schema`, `search`, `explain`, `correct`, `uncorrect`, `mandates`, plus `ask` and `ingest` when
their commands are named. Each write records the grant it ran under (`mandates` lists them,
`uncorrect` withdraws one). Without a planner or extractor the door still serves (**ran**).

## 5. Feed it a message and ask  (**ran**, with the facts written by hand)

Until step 3 runs, the extractor's job is played by one `publish` request. `sh graph/examples/quickstart/try.sh`
ingests "Ada Okafor <ada@example.test>: Please send the report to Sam by 2026-11-05.", publishes
Ada, Sam and a Chore (each with a source locator), then asks
`MATCH (c:Chore) WHERE c.title CONTAINS 'report' RETURN c.title AS chore, c.due_on AS due` and prints:

```json
{ "status": "answered", "read_revision": 3,
  "fields": [
    { "path": ["report", "chore"], "value": "Send the report", "basis": "observed", "citations": ["c4:by-hand-1"] },
    { "path": ["report", "due"],   "value": "2026-11-05",      "basis": "observed", "citations": ["c6:by-hand-1"] } ],
  "citations": [ { "id": "c4:by-hand-1", "source": { "observation": "mail:1", "revision": 1 }, "claim": "4", "run": "by-hand-1" }, … ],
  "problems": [], "absent": [] }
```

Every value cites the source it came from. A value the graph lacks comes back in `absent` with
the model's declared code; nothing is guessed.

## The whole slice at once

`sh graph/demo.sh` builds the fixture app, requires the step-3 service, ingests five messages
through the MCP `ingest` tool and asks four questions through `ask` (**not yet run**; it
exits 2 and says how to start the service when none answers — **ran**).
