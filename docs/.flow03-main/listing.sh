# every hashed source with its digest, as tools/sources_hash.sh reads them
find Makefile backend runtime packages -type f \( -name '*.av' -o -name '*.c' -o -name '*.h' -o -name '*.toml' \) ! -path '*/build/*' ! -path '*/vendor/*' 2>/dev/null | LC_ALL=C sort | while IFS= read -r f; do printf '%s %s\n' "$(shasum -a 256 "$f" 2>/dev/null | cut -d' ' -f1 || sha256sum "$f" | cut -d' ' -f1)" "$f"; done
