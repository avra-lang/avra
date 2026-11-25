#!/bin/sh
# pin.sh <case-name> <source-file>: a refusal witness pinned from the old path
R=/work/avra/tools/program-refusals
mkdir -p $R/$1/src && sed "s/decl_const_cycle/$1/" $R/decl_const_cycle/avra.toml > $R/$1/avra.toml && cp $2 $R/$1/src/main.av
