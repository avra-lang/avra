#!/bin/bash
out=$(ls -S /tmp/cg.out.* | head -1)
[ -s /tmp/cg.tree ] || callgrind_annotate --inclusive=yes --tree=caller "$out" 2>/dev/null > /tmp/cg.tree
for fn in provided_words file_ensured adopt_facts wire_decl grow_to Workspace.view_parts parsed_under_blocks restored_refs held_items_of_file; do
  echo "=== $fn"
  grep -n "\* .*$fn " /tmp/cg.tree | head -2 | while IFS=: read ln rest; do sed -n "$((ln-6)),${ln}p" /tmp/cg.tree; done
done
