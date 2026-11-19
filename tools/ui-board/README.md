# ui-board

The task board: one view, mounted on a page, with a server beside it.

    make bootstrap                        # once: the compiler, the package C, the wasm runtime
    ./avra dev tools/ui-board --port 8765

`avra dev` builds the page, starts `server/` (the `[dev]` row in
`avra.toml`) and serves both on one origin: the page at `/`, the tasks
at `/tasks`. A save to either is rebuilt without a restart.

`term/` mounts the same view in a terminal; `make ui-board` proves the
page glue headless.
