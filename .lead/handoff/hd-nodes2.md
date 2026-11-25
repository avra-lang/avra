# hd-nodes2 handoff (2026-11-02)
Branch: hd-codec (worktree ../avra-hd-nodes2), pushed at 60c109c3. All committed.
Done: row 7 derived fingerprints; @codec linear cost (fb5cdd35); Loc place door on Scope + scope_spelled table; written_by/read_by/digest_in on every @codec; Diag is THE codec'd diagnostic (DiagFacts gone); NameEnv record; Ids->Scope bridge (ids.as_scope, codec'd fields fold by digest_in); SideTable `window: Window`; TypeFacts @codec (facts_codec.av deleted); Settlement @codec; Wanted.root = Offset + decls.root_of.
Deleted: scalar_wire, id_wire, family_wire, diag_wire, sig_wire, facts_codec, diagnostics/fold.av, part of settlement_wire.
Next: (1) settlement_wire's Wanted wires: @codec on Wanted/Sub/SeatValue/Meta* (hd-decl has the annotations on hd-lowq; build on 60c109c3), then delete wanted_*/held_asks/sub_wire/seat_wire/heap wires; move decl_ref/type_ref/file_ref spellers into facts_scope.av. (2) held asks wait on hd-families2's non-minting FactsScope (`minting` field, goes in facts_scope.av). (3) rows_derive.av dies with db.av (hd-families2). (4) finish Ids->Scope: fingerprint_in(ids) callers left once more types are @codec.
Gate: run 41403802560 (@7f100079) not triaged; earlier runs showed only MAIN_GATE_2026_11_02 items.
Open: tools/codecs.py still flags record.av form_wire (#5, hd-nodes). `x?.f.m()` silent derive cascade logged in ROADMAP sugar backlog.
