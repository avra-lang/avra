`avra tapes <this dir> --signatures` says `tapes: 4 read, 0 differing` — a module that is both `m.av` and `m/` refuses a `use` of it, and the files of `m/` still read their own module's names.
