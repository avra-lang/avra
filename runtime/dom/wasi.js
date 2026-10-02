// The browser's WASI preview1 surface, as small as a program that prints,
// reads the clock, and gets randomness needs. Signatures are the standard
// preview1 ones. A call this surface does not answer is REFUSED by name by
// instantiate(), never silently a no-op.

const dec = new TextDecoder();
const enc = new TextEncoder();

// `memory()` reads the module's exported memory; `exit` ends the run.
export function wasiPreview1(memory, exit) {
  const view = () => new DataView(memory().buffer);
  const bytes = () => new Uint8Array(memory().buffer);
  const write32 = (ptr, v) => view().setUint32(ptr, v, true);

  return {
    args_sizes_get(argc, buf) { write32(argc, 0); write32(buf, 0); return 0; },
    args_get() { return 0; },
    environ_sizes_get(count, buf) { write32(count, 0); write32(buf, 0); return 0; },
    environ_get() { return 0; },
    fd_write(fd, iovs, iovs_len, nwritten) {
      let out = "", written = 0;
      const dv = view(), mem = bytes();
      for (let i = 0; i < iovs_len; i++) {
        const base = dv.getUint32(iovs + i * 8, true);
        const len = dv.getUint32(iovs + i * 8 + 4, true);
        out += dec.decode(mem.subarray(base, base + len));
        written += len;
      }
      write32(nwritten, written);
      if (fd === 2) console.error(out); else console.log(out.replace(/\n$/, ""));
      return 0;
    },
    fd_read() { return 0; },
    fd_close() { return 0; },
    fd_seek(_fd, _offset, _whence, out) { view().setBigUint64(out, 0n, true); return 0; },
    fd_fdstat_get(fd, buf) {
      // filetype 2 = CHARACTER_DEVICE, so isatty-style checks go down the
      // unbuffered path rather than pretending to be a file.
      view().setUint8(buf, 2);
      return 0;
    },
    clock_time_get(_id, _precision, out) {
      const now = BigInt(Date.now()) * 1000000n;
      view().setBigUint64(out, now, true);
      return 0;
    },
    random_get(buf, len) { crypto.getRandomValues(bytes().subarray(buf, buf + len)); return 0; },
    // The preopen scan: EBADF (8) is how libc learns there are no preopens.
    // A browser program has no filesystem, so it opens nothing.
    fd_prestat_get() { return 8; },
    fd_prestat_dir_name() { return 8; },
    sched_yield() { return 0; },
    proc_exit(code) { exit(code); },
  };
}

// The bytes of a string, for a caller that wants to print from JS.
export function utf8(s) { return enc.encode(s); }
