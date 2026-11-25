export LLVM_PREFIX=/usr/lib/llvm-22
build/avra build packages/cli > /tmp/gen.log 2>&1 || exit 1; cp packages/cli/src/main build/avra
make -o avra libs > /dev/null 2>&1
mkdir -p /tmp/gs/src; printf '[package]\nname = "gs"\nversion = "0.0.1"\n\n[bin]\nname = "gs"\npath = "src/main.av"\n' > /tmp/gs/avra.toml
cat > /tmp/gs/src/main.av <<'P'
use @std.avrac.compiler.{analyze_source}
let base = "trait View {\n    fn name() -> string\n}\ntype Text = { content: string }\ntype Button = { label: string }\nimpl View for Text {\n    fn name() -> string { \"t\" }\n}\nimpl View for Button {\n    fn name() -> string { \"b\" }\n}\ntype Html = { tag: string = \"\" }\ntrait Realize<T> {\n    fn draw(t: T) -> string\n}\nimpl Realize<Text> for Html {\n    fn draw(t: Text) -> string { t.content }\n}\nimpl Realize<Button> for Html {\n    fn draw(t: Button) -> string { t.label }\n}\nlet a: dyn View = Text { content: \"x\" }\nlet b: dyn View = Button { label: \"y\" }\n"
fn said(src: string) -> string {
    match analyze_source(src).run() {
        .Ok(text) -> "ok [${text}]"
        .Err(why) -> "err [${why}]"
    }
}
let tails = ["[Html {}.draw(v) for v in [a, b]].join(\"\")", "let h = Html {}\n[h.draw(v) for v in [a, b]].join(\"\")", "[Html {}.draw(Text { content: \"s\" }) for i in 0..1].join(\"\")", "Html {}.draw(a)", "let h = Html {}\nh.draw(a) + h.draw(b)"]
[said(base + t) for t in tails].join(" | ")
P
build/avra run /tmp/gs > /tmp/gs.out 2>&1; grep -vE "^(warning|   |──|help:|s*[0-9]+ │)" /tmp/gs.out | grep -v "^s*$" | tail -60
