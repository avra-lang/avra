R=/tmp/ior; find $R -delete 2>/dev/null; mkdir -p $R/p/src/lib
printf '[package]\nname = "p"\nversion = "0.1.0"\n' > $R/p/avra.toml
printf 'use @std.io.{read_text}\nexport fn got(p: string) -> string { match read_text(p) { .Ok(t) -> t, .Err(_) -> "" } }\n' > $R/p/src/lib/a.av
printf 'use @std.io.{env}\nuse lib.{got}\nprintln(got(env("HOME") ?? "/"))\n' > $R/p/src/main.av
for v in check build; do
  ./avra $v $R/p >/dev/null 2>&1
  printf '// e1\n' >> $R/p/src/main.av
  echo "== $v edit main"; ./avra $v --time $R/p 2>&1 | grep -E "^error|held |^read|^  " | head
  printf '// e2\n' >> $R/p/src/lib/a.av
  echo "== $v edit lib"; ./avra $v --time $R/p 2>&1 | grep -E "^error|held |^read|^  " | head
done
