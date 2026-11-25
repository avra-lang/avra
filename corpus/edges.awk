/^edge / { dep[$2]++; byframe[$4" "$2]++; if ($2 == 29) per[$3]++ ; if ($2 == 2) items[$3]++ }
END {
  for (k in dep) print "dep", k, dep[k]
  for (k in byframe) if (byframe[k] > 50000) print "frame dep", k, byframe[k]
  split("4 8 16 32 64 128 256", ks, " ")
  for (i in ks) { s = 0; for (r in per) if (per[r] > ks[i]) s += per[r] - ks[i]; print "named over", ks[i], s }
  n = 0; for (r in per) n++; print "named readers", n
  m = 0; for (r in items) m++; print "items readers", m
}
