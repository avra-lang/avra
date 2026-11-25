# `export use` of a component from a sibling that imports the root

Compiler: avra-macos-batch51-d251b801 (may be fixed on a newer head — rerun there).
Tree: services at a383a89a7 (in batch 54). Package @std/queue, a LIBRARY (lib root src/queue.av), not an entry.

Edit: in packages/std-queue/src/queue.av, after `use heap.{Heap, Ranked, heap}`, add
    export use schedule.{schedule}
src/schedule.av (sibling file, same package) holds `export component schedule<T> { … }`
and itself imports the root: `use queue.{HomeError, queue}`.  So: root re-exports from a
sibling that imports the root, and the re-exported name is a generic COMPONENT.

Command: ./avra check packages/std-queue

Output:
program-layer false refusal — the old path accepts this program, so what follows is a defect of the program layer:
error[resolve.duplicate_type]: `schedule` is declared more than once
   ╭─[packages/std-queue/src/schedule.av:38:8]
38 │ export component schedule<T> {
   ·        ╰── redeclared here
help: rename one of them
