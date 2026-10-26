import socket,json,os,sys
s=socket.socket(socket.AF_UNIX);s.settimeout(180);s.connect(os.path.expanduser("~/.cache/avra-graph-ml/cascade.sock"))
s.sendall((json.dumps(json.loads(sys.argv[1]))+"\n").encode())
d=b""
while not d.endswith(b"\n"):
    c=s.recv(65536)
    if not c:break
    d+=c
print(d[:600])
