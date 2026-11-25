import sys, re
text=open(sys.argv[1]).read(); drop=sys.argv[2]
blocks=re.split(r'\n\n(?=(?:warning|error)\[)', text.strip('\n'))
kept=[b for b in blocks if b and drop not in b.split('\n')[1]]
sys.stdout.write("\n\n".join(kept)+("\n" if kept else ""))
