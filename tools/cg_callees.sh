#!/bin/bash
for fn in 'Workspace\$2Etyped_named ' 'Workspace\$2Etyped_index ' 'Reach\$2Eadd_all ' 'Workspace\$2Esees_records ' 'Workspace\$2Emodule_stands ' 'Workspace\$2Ekey_parts '; do
  echo "=== $fn"
  ln=$(grep -n "\*  .*$fn" /tmp/cg.calling | head -1 | cut -d: -f1)
  [ -n "$ln" ] && sed -n "${ln},$((ln+10))p" /tmp/cg.calling
done
