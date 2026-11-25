R=/tmp/crr; find $R -delete 2>/dev/null; mkdir -p $R
HR() { label=$1; verb=$2; pkg=$3; shift 4; echo "== $label"; ./avra $verb --time $R/$pkg 2>&1 | grep -E "held|read:|^  |error" | head -20; }
mkdir -p $R/cr/src/kit $R/cr/src/part
printf '[package]\nname = "rt-cr"\nversion = "0.1.0"\n' > $R/cr/avra.toml
cat > $R/cr/src/kit/kit.av <<'AV'
use @std.meta.{Type, Directive, Declared, composes}

export type Tagged = { tag: string = "" }

export component words {
    items: List<string> = []
}

@composes(Tagged)
export trait Says {
    fn says() -> string

    static fn derive(t: Type) -> Declared {
        let body? = t.body else { return Declared { made: [] } }
        Declared {
            made: [
                Directive {
                    twin: "",
                    name: t.name,
                    at: t.at,
                    source: quote {
                        impl Says for ${t} {
                            fn says() -> string {
                                words made {
                                    ${body}
                                }
                                made.items.join(" ")
                            }
                        }
                    },
                },
            ],
        }
    }
}

export fn said_by(s: dyn Says) -> string { s.says() }
AV
printf 'use kit.{said_by}\n\nexport component note(name: string) {\n    "note"\n    self.name\n}\n\nexport fn noted(n: note) -> string { said_by(n) }\n' > $R/cr/src/part/note.av
printf 'use kit.{said_by}\n\nexport component card(name: string) {\n    said_by(note self.name)\n    "${[said_by(note r) for r in ["a", "b"]].length}"\n}\n' > $R/cr/src/part/card.av
printf 'use kit.{said_by}\nuse part.{card}\nprintln(said_by(card "a"))\n' > $R/cr/src/main.av
HR "cold cr" check cr 0
printf '// moved\n' >> $R/cr/src/main.av
HR "cr: an entry edit holds the components" check cr 0 part/note.av held part/card.av held
cp $R/cr/src/kit/kit.av $R/cr/kit.kept
grep -v '^@composes' $R/cr/kit.kept > $R/cr/src/kit/kit.av
HR "no composes" check cr 1
cp $R/cr/kit.kept $R/cr/src/kit/kit.av
HR "cr: the mark back composes again" check cr 0
sed 's/component note(/component memo(/; s/n: note/n: memo/' $R/cr/src/part/note.av > $R/cr/note.new && cp $R/cr/note.new $R/cr/src/part/note.av
echo "== final"; AVRA_QTRACE=1 ./avra check --time $R/cr 2>$R/trace >$R/out; cat $R/out | head -30; grep -E "^Q.(attempt|parse)" $R/trace | head -40
