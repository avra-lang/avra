error[type.variant_arity]: `.Adopt` carries 2, the pattern names 1
   ╭─[/Users/tristan/projects/tristanMatthias/avra-ui-loop/packages/std-ui/src/realize/dom/tests/snapshot_test.av:91:152]
91 │         .SetAttr(_, _, _) or .DropAttr(_, _) or .SetProp(_, _, _) or .SetText(_, _) or .Listen(_, _) or .Unlisten(_, _) or .Style(_) or .Call(_, _) or .Adopt(_) -> false,
   ·                                                                                                                                                        ┬
   ·                                                                                                                                                        ╰── here
───╯
help: one pattern per payload, in order — `_` for one you do not need

error[type.variant_arity]: `.Adopt` carries 2, the pattern names 1
   ╭─[/Users/tristan/projects/tristanMatthias/avra-ui-loop/packages/std-ui/src/realize/dom/tests/snapshot_test.av:98:206]
98 │         .Create(_, _) or .CreateText(_, _) or .Place(_, _, _) or .Remove(_) or .SetAttr(_, _, _) or .DropAttr(_, _) or .SetProp(_, _, _) or .SetText(_, _) or .Unlisten(_, _) or .Style(_) or .Call(_, _) or .Adopt(_) -> false,
   ·                                                                                                                                                                                                              ┬
   ·                                                                                                                                                                                                              ╰── here
───╯
help: one pattern per payload, in order — `_` for one you do not need

error[type.variant_arity]: `.Adopt` carries 2, the pattern names 1
    ╭─[/Users/tristan/projects/tristanMatthias/avra-ui-loop/packages/std-ui/src/realize/dom/tests/snapshot_test.av:105:205]
105 │         .Create(_, _) or .CreateText(_, _) or .Place(_, _, _) or .Remove(_) or .SetAttr(_, _, _) or .DropAttr(_, _) or .SetProp(_, _, _) or .Listen(_, _) or .Unlisten(_, _) or .Style(_) or .Call(_, _) or .Adopt(_) -> false,
    ·                                                                                                                                                                                                             ┬
    ·                                                                                                                                                                                                             ╰── here
────╯
help: one pattern per payload, in order — `_` for one you do not need
