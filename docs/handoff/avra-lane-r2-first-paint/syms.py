import subprocess, sys, json, os
S = sys.argv[1]
N = "/usr/lib/llvm-22/bin/llvm-nm"
out = {}
def scan(path, label):
    r = subprocess.run([N, "-A", "--defined-only", path], capture_output=True, text=True).stdout
    for line in r.splitlines():
        head, _, rest = line.rpartition(": ")
        parts = rest.split()
        if len(parts) < 2: continue
        name = parts[-1]; typ = parts[-2]
        if typ.lower() not in ("t", "w"): continue
        member = head.split(":")[-1] if path.endswith(".a") else os.path.basename(path)
        out.setdefault(name, f"{label}:{member}")
scan("/home/user/avra/build/wasm32/libavra_runtime.a", "runtime")
for o in ["std_io.o", "std_io_watch.o", "std_time.o"]:
    scan(f"/home/user/avra/build/wasm32/{o}", "pkgC")
for l in ["c", "setjmp", "wasi-emulated-mman", "wasi-emulated-signal", "wasi-emulated-getpid"]:
    scan(f"{S}/wasi/wasi-sysroot-27.0/lib/wasm32-wasi/lib{l}.a", "lib" + l)
import glob
crt = glob.glob("/usr/lib/llvm-22/lib/clang/22/lib/*wasi*/*.a") + glob.glob("/usr/lib/llvm-22/lib/clang/22/lib/wasi/*.a")
for c in crt: scan(c, "compiler-rt")
json.dump(out, open(f"{S}/census/syms.json", "w"))
print(len(out), crt)
