# Old-path idiom-gate coverage: what `reaches_file` does, and the new path's per-file answer

## Correction first
I earlier reported that the old path, checking packages/cli, misses std-http route.av:722 (lists.bool_comprehension_range). That was wrong about the gate.
- Remove only that line from tools/idioms.baseline and the old `check packages/cli --baseline` fails with exactly that one NEW site. So the old gate sees it.
- What the old path omits is the RENDERED warning. My old-path site lists were scraped from rendered warnings, so the "gap" was in what it prints, not in the ratchet.

## What `reaches_file` does (compiler/record.av)
`reaches_file(ws, reached, path)` is true when any of these holds:
- the file is the root package's (`holder_of_path(path) == 0`);
- its module, `ws.module_of(path)`, is in `reached`;
- its package is gathered whole by a reached `collect` (`pkg:<key>`).

`reached` comes from `reached_modules(ws, p)`: the prelude and the root package's modules, closed over every parsed file's `use` lines. Each line contributes `qualified(module_path(u.path), from).text()`, the path exactly as written.

Its one consumer is `stood` (compiler/derive.av):
- `Derived.warnings` keeps a said file's warnings only if `reaches_file`;
- `Derived.unreached` lists the rest;
- `check_said` turns these into `FileSpoke { reached, said: if reached { warnings } else { "" }, findings: s.findings }`.

So `reaches_file` gates the warnings `check` prints. It never gates `findings`, the rule rows `--baseline` reads: every file the program analysed (`all_said` over `p.files`) keeps its findings.

## The defect: a file imported by its own path is never "reached"
- `ws.module_of(path)` (compiler/modules.av `module_in`) names a file by its DIRECTORY module: `packages/std-http/src/route.av` is module `@std.http`.
- A `use` line may name one FILE of a directory module: cli's `use @std.http.route.{Route, mounted, fixed}` names route.av.
- `reached` then holds `@std.http.route`, while `reaches_file` asks for `@std.http`. No match, so every warning in that file is silenced whenever a package imports it file by file. Law warnings and rule warnings alike, while its findings still feed the gate.
- That is why checking packages/cli prints nothing from std-http, std-json, std-text or std-program, but does print std-grammar, std-process, std-relation and std-toml, which are imported by module.

A fix, not made since it's the old path: when `reached_modules` walks a `use` path that resolves to a file of a directory module, add that directory module, i.e. the `module_of` of the file it resolves to, not the path as written. Or have `reaches_file` also accept `module_of(path) + "." + stem(path)`.

## Witnesses (directories beside this note)
Same old-built compiler and new-path compiler from one source.

**witness_byfile:** app imports `use @w.dep.byfile.{first_even, kept}`. dep/src/byfile.av holds one rule site (`nullable.nullable_flag_local`) and one warning site (`type.coalesce_never`).
- `check app`, old path: prints NO warning for byfile.av, neither the rule nor `coalesce_never`.
- `check app --baseline <empty>`, old path: `1 NEW … dep/src/byfile.av [nullable.nullable_flag_local] mut found: int? = null`. The gate sees it.
- `check dep`, old path: prints both warnings.
- `AVRA_PROGRAM=1 check app --baseline <empty>`: the same NEW site, from the per-file rows.

**witness_reach** (control): dep's modules are directories (`used/`, `unused/`); app imports `@w.dep.used`.
- Old `check app`: prints both used.av warnings. The module matches, so it is reached.
- Neither path reads unused/unused.av, a module no file imports; `check dep` reports it. Both paths cover exactly the files the program reads.

## Does the new path's per-file answer cover every file the program reads?
- The new path's rows are `file_rule_rows(f)` for every `f` in `program_files(engine, package)`: the package closure of reached modules, file imports included. A file-imported dependency file is covered (witness_byfile).
- On cli and std-program (one source, sorted file:line:rule): every old-gate site of a rule the program layer holds appears on the new path. dead_parameter and repeated_unwrap now match site for site too.
- File counts for packages/cli: old `program_files=773` (`check --counts`), new 750 (`check --time`). I could not list both sets exactly: the old path opens relative paths, and the new path reads whole module directories for their names.
- What the old path opens beyond the new: std-db and std-sqlite files, which reach the program only as `embed`ded text (testing/std_sources.av). The old gate reports none of their baseline sites: removing their 5 baseline lines leaves `check packages/cli --baseline` at exit 0. So they are data, not sources, and neither path should check them.

## What the new path still doesn't do (not coverage, said for completeness)
- `check --baseline` on the program layer prints rule sites and refuses on law ERRORS, but prints no law WARNINGS (e.g. `type.coalesce_never`). The old path prints those for reached files.
- 6 rules are still unheld (bypass_outside_bracket, one_body_arms, default_override, unused_import, if_null_ternary, unmutated_mut); the check names them and refuses to pass.
