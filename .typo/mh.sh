R=/tmp/mhr; find $R -delete 2>/dev/null; mkdir -p $R
ed() { python3 - "$1" "$2" "$3" <<'PY'
import sys; p,a,b=sys.argv[1:]; s=open(p).read(); open(p,'w').write(s.replace(a,b,1))
PY
}
S() { ./avra build $R/$2 >/dev/null 2>&1; }
MH() { echo "== $1"; AVRA_QTRACE=1 ./avra build --time $R/mh 2>$R/trace; grep -E "^read|^  |PROBE.*show" $R/trace | head -30; }
mkdir -p $R/mhl/src $R/mh/src
printf '[package]\nname = "@rt/mhl"\nversion = "0.1.0"\n\n[lib]\nname = "rt-mhl"\npath = "src/lib.av"\n' > $R/mhl/avra.toml
cat > $R/mhl/src/pad.av <<'AV'
export fn pad() -> int { 3 }
fn priv() -> int { 5 }
AV
cat > $R/mhl/src/lib.av <<'AV'
use pad.{pad}
export fn host() -> int { pad() + priv() }
AV
printf '[package]\nname = "rt-mh"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/mhl" = { path = "../mhl" }\n"@rt/mht" = { path = "../mht" }\n' > $R/mh/avra.toml
mkdir -p $R/mht/src
printf '[package]\nname = "@rt/mht"\nversion = "0.1.0"\n\n[lib]\nname = "rt-mht"\npath = "src/lib.av"\n\n[dependencies]\n"@rt/mhl" = { path = "../mhl" }\n' > $R/mht/avra.toml
printf 'export trait Tell { fn tell() -> int }\n' > $R/mht/src/lib.av
cat > $R/mht/src/tell_pt.av <<'AV'
use @rt.mhl.{Pt}
fn tbase() -> int { 100 }
impl Tell for Pt { fn tell() -> int { self.v + tbase() } }
AV
printf 'use @rt.mht.{Tell}\nuse @rt.mhl.{Pt}\nexport fn told() -> int {\n    let s: dyn Tell = Pt { v: 5 }\n    s.tell()\n}\n' > $R/mh/src/third.av
printf 'use @rt.mhl.{host}\nexport fn shown() -> int { host() }\n' > $R/mh/src/show.av
cat > $R/mhl/src/pt.av <<'AV'
export trait Say { fn say() -> int }
export type Pt = { v: int }
AV
cat > $R/mhl/src/pt_say.av <<'AV'
use pt.{Say, Pt}
fn base() -> int { 1 }
impl Say for Pt { fn say() -> int { self.v + base() } }
AV
printf 'use @rt.mhl.{Say, Pt}\nexport fn said() -> int {\n    let s: dyn Say = Pt { v: 4 }\n    s.say()\n}\n' > $R/mh/src/dyn.av
printf 'println("mh ${shown()} ${said()} ${told()}")\n' > $R/mh/src/main.av
S "cold mh: a sibling reaches one file by use, another by no use at all" mh
S "mh: warm no-op" mh
ed $R/mhl/src/pad.av "{ 3 }" "{ 30 }"
MH "mh: pad's body only moves — lib.av stays held" lib.av held
ed $R/mhl/src/pad.av "{ 30 }" "{ 3 }"
MH "mh: and back" lib.av held
ed $R/mhl/src/pad.av "export fn pad() -> int { 3 }" "export fn pad(n: int = 0) -> int { 3 }"
MH "mh: pad's EXPORTED signature moves (reached through a use) — lib.av re-reads, show.av never named it" lib.av read show.av held
ed $R/mhl/src/pad.av "export fn pad(n: int = 0) -> int { 3 }" "export fn pad() -> int { 3 }"
MH "mh: and back" lib.av held show.av held
ed $R/mhl/src/lib.av "export fn host() -> int" "export fn host(n: int = 0) -> int"
MH "mh: host's signature moves — show.av names it, and re-reads" show.av read
ed $R/mhl/src/lib.av "export fn host(n: int = 0) -> int" "export fn host() -> int"
MH "mh: and back" show.av held
ed $R/mhl/src/pad.av "fn priv() -> int { 5 }" "fn priv(n: int = 0) -> int { 5 }"
MH "mh: priv's NON-exported signature moves (reached with no use at all) — lib.av re-reads" lib.av read show.av held
ed $R/mhl/src/pad.av "fn priv(n: int = 0) -> int { 5 }" "fn priv() -> int { 5 }"
MH "mh: and back, cold no more" lib.av held
ed $R/mhl/src/pt_say.av "self.v + base() }" "self.v + base() + 1 }"
