# Sprite sessions

> Superseded as the single source by `docs/2026_10_11_THE_PIPELINE.md`
> (Sprites, provisioning, the seed path). Kept as the design record.

A Sprite is a persistent Linux microVM (stock Ubuntu, no custom base
image). One command provisions this tree there:

```sh
make sprite          # sh tools/sprite-provision.sh
```

It installs LLVM 22, points the tree's `${LLVM_PREFIX}` default at it,
and leaves a working `build/avra`. On macOS it is a no-op.

## Fast and slow paths

`make recover` links `bootstrap/seed.ll` into a compiler in ~20 s. That
compiler IS this tree's compiler exactly when the tree is the source the
seed came from — `bootstrap/seed.sources` records that as a hash of
every input the build reads.

- **match** (clean checkout at the seed's commit): apt + recover,
  ~75 s, **no build**.
- **mismatch** (uncommitted edits, or a branch off the seed): recover +
  **one** build, ~4 min. The product is verified before it is trusted.

`make sprite-check` says which path this tree takes. `make seed`
refreshes `seed.ll` and `seed.sources`, restoring the fast path. The seed
is refreshed on a CADENCE, and whenever it can no longer compile HEAD —
not on every landing, since a refresh per landing conflicts every other
branch on the seed. Between refreshes a fresh Sprite takes the one-build
path.

## Agent sessions (herdr)

The [herdr Sprites plugin](https://github.com/superfly/herdr-sprites-plugin)
creates a fresh Sprite per pane, uploads the worktree, and runs a
project `setup` command before the agent starts. In
`~/.config/herdr/plugins/config/sprites/config.json`:

```json
{ "org": "<your org>", "agent": "claude",
  "setup": ["sh tools/sprite-provision.sh"] }
```

The `setup` key is not upstream yet — `.pi/herdr-sprites-setup.patch`
carries the hook (a `setup` array run in the worktree during
`finishSetup`). Sprites persist and wake warm in 100–500 ms, so
reconnecting costs far less than creating a new Sprite.

## Why not a base image

`POST /v1/sprites` accepts only `name` and `url_settings`: there is no
base image, checkpoint fork, template, or prewarm. The platform's answer
is persistence — install once, reuse the Sprite.
