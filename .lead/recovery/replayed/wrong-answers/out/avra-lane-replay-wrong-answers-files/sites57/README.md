# base57's cold build-cli by site

Measured over snap57 (a6d0d0a04724cfd000bcd9c4c0c3b46f61a36acc), store off, site tables on
(AVRA_CENSUS_SITES=1, AVRA_CENSUS_TOP=400), one core.

- 6abff86d.out          the census report of base57's (6abff86d) cold `build packages/cli`
                        (alloc: 962660360 boxes); its `made:`/`retain:` lines are raw addresses
- 6abff86d.census.bin   the census compiler that ran, to resolve those addresses (`addr2line -f -e`)
- 6abff86d.made.byfn    made-sites summed by fn: `<boxes> <symbol>`, most first
- 6abff86d.retain.byfn  retain-sites summed by fn, the same
- sites58.sh            the script: `sh sites58.sh <id> <commit>` builds that tree's compiler from
                        57's, then its census compiler, then one cold build-cli with the site tables
                        on, and writes <sha8>.out / .made.byfn / .retain.byfn under /tmp/claude-0/s58/

sites58.sh's paths are this machine's: the repo (/work/avra), the standing compiler
(/work/l57final-wt/build/avra.gen2), the build objects it copies (/work/fixA-wt/build) and the
snapshot it extracts; change them where it runs elsewhere. To compare two trees by fn:

    awk 'NR==FNR {a[$2]=$1; next} {d=$1-a[$2]; if (d>0) print d, $1, a[$2]+0, $2}' A.made.byfn B.made.byfn | sort -rn | head
