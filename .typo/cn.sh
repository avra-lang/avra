make try 2>&1 | tail -2
find /tmp/cnr -delete 2>/dev/null; mkdir -p /tmp/cnr/src
printf '[package]\nname = "cn"\nversion = "0.1.0"\n\n[bin]\nname = "cn"\npath = "src/main.av"\n' > /tmp/cnr/avra.toml
printf 'export component box(name: string) {\n    "b"\n    self.name\n}\n' > /tmp/cnr/src/a.av
printf 'use a.{box}\nprintln("x")\n' > /tmp/cnr/src/main.av
for i in 1 2 3; do AVRA_QTRACE=1 ./avra-try check /tmp/cnr 2>/tmp/cnr/t$i >/dev/null; echo "run $i: ComponentNames compute=$(grep -c 'ask.ComponentNames.*compute' /tmp/cnr/t$i) reuse=$(grep -c 'ask.ComponentNames.*reuse' /tmp/cnr/t$i)"; done
ls -R /tmp/cnr/.avra-cache 2>/dev/null | head -5
