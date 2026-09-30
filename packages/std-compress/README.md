# @std/compress

gzip, zlib and brotli: octets encoded, and decoded under a ceiling
that turns a decompression bomb into a refusal.

## The vendored engines

- **zlib 1.3.1**, zlib licence (`vendor/zlib/LICENSE`).
  sha256 `9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23`
  (`zlib-1.3.1.tar.gz`).
- **brotli 1.1.0**, MIT (`vendor/brotli/LICENSE`).
  sha256 `e720a6ca29428b803f4ad165371771f5398faba397edf6778837a18599ea13ff`
  (`brotli-1.1.0.tar.gz`).
- `vendor/import.sh <zlib tarball> <brotli tarball>` rebuilds `vendor/`
  from those two files and nothing else. To upgrade, re-run it with
  the new tarballs.

Each upstream unit compiles as its own object through a one-line
wrapper (`vendor/zlib_<unit>.c`, `vendor/brotli_<dir>_<unit>.c`). The
objects are archived with this package's C as `build/std_compress.a`,
so a program links only the members it reaches. `@std/http` does not
link this package. HTTP content coding lives in `@std/http_compress`.
