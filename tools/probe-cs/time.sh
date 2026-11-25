cp /home/sprite/avra-compilers/$1/avra build/avra.main
python3 - <<'PY'
import subprocess, resource, time, shutil, os
for k in range(3):
    for who in ["avra.main", "avra"]:
        for d in ["/tmp/mt/.avra-cache", "/tmp/mt/packages/cli/.avra-cache", ".avra-cache"]:
            shutil.rmtree(d, ignore_errors=True)
        r0 = resource.getrusage(resource.RUSAGE_CHILDREN); t0 = time.time()
        subprocess.run(["build/" + who, "check", "/tmp/mt/packages/cli"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        r1 = resource.getrusage(resource.RUSAGE_CHILDREN)
        print(f"{who:10} wall {time.time()-t0:6.2f}s user {r1.ru_utime-r0.ru_utime:6.2f}s", flush=True)
PY
