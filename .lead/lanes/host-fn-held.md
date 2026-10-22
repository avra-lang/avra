[2026-10-13T01:30:40Z] host-fn-held: PR #664 draft; attack lh fails on main (cold nm 2 symbols, warm 0), green with fix; cause: -u/listing read from read files only; Sprite runs pending (none free)

[items-kept] drafted attack (avra-e4uc): a host fn in a held module is missing from the linked program after a warm build. Repro on main/eager tree:
  mkdir -p R/lh/src/x; printf '[package]\nname = "rt-lh"\nversion = "0.1.0"\n' > R/lh/avra.toml
  printf 'extern fn avra_lh_event(who: int) -> int { who + 1 }\n' > R/lh/src/x/host.av ; printf 'println("lh")\n' > R/lh/src/main.av
  cold: bin=$(avra build R/lh | tail -1); nm "$bin" | grep -c avra_lh_event   -> 2 (av_avra_lh_event, avra_lh_event)
  warm: printf '// moved\n' >> R/lh/src/main.av; avra build R/lh (host.av held, 2/3): nm | grep -c avra_lh_event -> 0, and the build prints no 'host fn:' line.
cache_attacks.sh form (add as a section; S builds, then):
  S "lh: only main.av read" lh
  case "$(nm $R/lh/src/main 2>/dev/null)" in *avra_lh_event*) ok ;; *) fails=$((fails+1)); echo "FAIL  lh: a host fn in a held module is missing from the linked program" ;; esac
