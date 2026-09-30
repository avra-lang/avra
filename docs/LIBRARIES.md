# How to build libraries in Avra

A library is the language's showcase. These rules hold for `@std` and
for every package written in its image.

1. **A file is a concern, a directory is a subsystem, the package is
   the surface.** Users import from the package (`use @std.ui.{text}`);
   where a thing lives is the library's business. No file past ~300
   lines; none named after the package.
2. **One definition per idea.** A component's fields are its props,
   its docs and its schema. A type spelled twice — a record beside an
   enum payload, a component beside an `XProps` — is a design defect.
3. **Values, not glue.** Expose declarations: components, types,
   consts, traits. A helper that only assembles a record (`leaf`,
   `boxed`) means the declaration or the language is missing a shape.
4. **Contracts are traits.** What several implementations must
   satisfy — a renderer, a store, a transport — is a trait, one method
   per obligation, so a missing piece fails to compile. Never a
   registry someone must remember to update.
5. **Data is data.** Tokens, tables, defaults, catalogues are values
   (consts, `embed`), never literals inside logic. A theme or a keymap
   is a record a user replaces whole.
6. **Declarative at the top, imperative at the bottom.** The user's
   layer is declarations and settings; the walk, the serializer, the
   state machine live a directory down and are never imported by users.
7. **Extension is composition.** Users extend by composing what
   exists, never by editing a central enum or table. A closed set is a
   versioned platform fact and says so in its doc.
8. **Names are the domain's words.** `Style`, `Theme`, `Screen` — never
   the implementation's (`Setting`, `look`, `leaf`).
9. **Mirror, don't monolith.** A subsystem with several implementations
   mirrors one tree: `components/text.av`, `realize/html/text.av`,
   `realize/tui/text.av`. A new implementation is a new directory;
   nothing it implements changes.
10. **Tests, fixtures and states ship beside the code;** dev tooling
    (galleries, inspectors) is the CLI's, built on the library's
    `testing` module, never inside `@std`.
11. **Idiomatic or it waits.** Every file passes CLAUDE.md's idiom bar.
    When the idiomatic form does not compile, file the language ask
    and design it — never ship the workaround as the design.
