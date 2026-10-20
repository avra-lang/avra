b=$(build/avra build tools | tail -n 1)
python3 - "$b" <<'P'
import json,subprocess,sys
b=sys.argv[1]; bad=0
for j,e,s,want in json.load(open("tools/gate_golden.tmp.json")):
    r=subprocess.run([b,"ci_path_gate",j,"--event",e],input=s,capture_output=True,text=True)
    if r.stdout!=want: bad+=1; print("DIFF",j,e,repr(s),repr(want),repr(r.stdout),r.stderr[:100])
print("byte-identical" if not bad else "FAILED %d"%bad)
P
make tools-suite 2>&1 | tail -4
