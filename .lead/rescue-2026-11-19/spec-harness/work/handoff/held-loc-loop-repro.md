# Importing `Loc` loops the resolver (resolve-2)

Base: batch53 (d5062c32) + avra-lane-spec-harness.

1. In packages/std-avrac/src/testing/held.av, change
   `use diagnostics.{Diag, has_errors, loc_at, new_source_file, rendered_among}`
   to
   `use diagnostics.{Diag, Loc, has_errors, loc_at, new_source_file, rendered_among}`
   (adding the type `Loc`, nothing that uses it).
2. `build/avra check packages/std-avrac/src/testing/held.av`

Says (no diagnostics, exits):
  avra: `file_scope` (fs10:@std/avracs19:src/testing/held.av) was asked while it was being answered,
  under file_scope -> package_impls, from `file_scope` (fs10:@std/avracs19:src/testing/held.av)
A sibling spelling seen in the same bisect:
  avra: `package_impls` (s10:@std/avrac) was asked while it was being answered, under package_impls -> file_scope

Importing `loc_at` alone (no `Loc`) checks clean; the type name is the trigger.
