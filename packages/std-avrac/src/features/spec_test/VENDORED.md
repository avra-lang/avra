# ⚠️ VENDORED TOOLCHAIN CODE — NOT OURS, NOT GOOD, DO NOT IMITATE ⚠️

`runner.av` and `reporter.av` are unmodified copies from the bootstrap
tree. `bs2 test` loads them from this exact path — that is the only
reason they exist.

- NEVER reference anything here as style or architecture precedent.
- NEVER edit these files; update by re-copying.
- This entire directory WILL be rebuilt from scratch when the compiler
  owns its own test harness.
