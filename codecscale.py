import os,sys
for n in [int(x) for x in sys.argv[1:]]:
    d=f"scratch_codec/n{n}"
    os.makedirs(d+"/src",exist_ok=True)
    open(d+"/avra.toml","w").write(f'[package]\nname = "scratch-codec-n{n}"\nversion = "0.1.0"\n')
    src=["use @std.relation.{codec}","use @std.meta.{dense}","","@dense\ntype Tid = { index: int }",""]
    for i in range(n):
        src.append(f"@codec\ntype K{i} = {{ a: int, b: string, ids: List<Tid>, c: int? }}\n")
    src.append("type Tbl<V> = { lo: int, hi: int, cells: List<V>, seed: V }\n")
    cols=", ".join(f"c{i}: Tbl<K{i}?>" for i in range(n))
    src.append(f"@codec\ntype Facts = {{ {cols} }}\n")
    src.append('println("x")')
    open(d+"/src/main.av","w").write("\n".join(src)+"\n")
