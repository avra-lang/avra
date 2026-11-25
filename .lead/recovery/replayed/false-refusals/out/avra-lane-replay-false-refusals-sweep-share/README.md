# The soundness sweep, half B

For each program-shaped fixture: the OLD `check` (AVRA_PROGRAM=0, net on) and the layer's `build`
(AVRA_PROGRAM=1, AVRA_PROGRAM_NET=0), each bounded at 300 s. One TSV line per fixture: path, old
exit, old first diagnostic, old first error kind, layer exit, layer first diagnostic, layer first
error kind.

The tree is d00e7c64 (land58c), where both paths still stand, built (`make`, so `build/avra`
exists). Paths in the lists are relative to that tree's root.

Files:
- one.sh: runs one fixture. It deletes the fixture's `.avra-cache` after its build, because the
  builds' products filled a disk once.
- fixtures-A.txt, fixtures-B.txt: the two halves (1191 each) of list.txt. That list is every
  avra.toml fixture dir and every `<name>/<name>.av` single-file program at d00e7c64, with
  tools/wasm-* left out (a native build differs from its target by design).
- rank.py: merges results files and ranks them.

Half B, exactly (4 workers; replace TREE with your d00e7c64 checkout, built):

    TREE=/path/to/d00e7c64-tree
    cd /work/sweep-share
    xargs -a fixtures-B.txt -P 4 -I{} sh /work/sweep-share/one.sh "$TREE" /work/sweep-share/out-B {} > /work/sweep-share/results-B.tsv 2>/dev/null

Building the tree, if it isn't built (and the objects a plain `make` leaves out: `make build/sqlite3.o build/sqlite_sentinel.o build/std_compress.a build/std_tls.a`): `cd $TREE && AVRA_PROGRAM_NET=0 make` (from a `build/` that has
an earlier `build/avra` in it: copy one in first, since the seed is the only cold path).

Merged ranking (run by the sweep's owner):

    python3 /work/sweep-share/rank.py 400 /tmp/claude-0/sweep/results.tsv /work/sweep-share/results-B.tsv

Categories: 1 soundness (the old path refuses with an error, the layer builds); 1b the old path
refuses, the layer fails with no diagnostic; 2 wrong words (both refuse, first error kind
differs); 3 false refusal (the layer refuses what the old path accepts); 4/5 a failure with no
diagnostic; timeouts. Struck before ranking: parity-values' A–E and afc3e0a8 (struck.txt).

REVISED one.sh (03:25): a package that declares no entry point (a provider, a vendored library,
a `test_reads` fixture) is CHECKED by the layer, since nothing builds; and the cleanup deletes only
the fixture's own `.avra-cache`, never a nested fixture's, which raced with parallel workers.
Rows made by the first one.sh are rerun by the sweep's owner.
