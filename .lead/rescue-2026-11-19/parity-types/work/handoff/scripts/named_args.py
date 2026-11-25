def sub(p, a, b, n=1):
    s = open(p).read()
    assert s.count(a) == n, (p, a[:90], s.count(a))
    open(p, 'w').write(s.replace(a, b))

w = '/work/avra/packages/std-avrac/src/compiler/item_writes.av'
# fed places labelled arguments by the seats' names
sub(w, '''    mut fn fed(marks: List<bool>, args: List<ExprId>, callee: string) {
        if args.length > marks.length ||
            args.any((a) -> self.store.arg_label(a) != null || self.store.spread_operand(a) != null) {
            if self.hands_receiver(args) { self.unread(handed_unread(callee)) }
            return
        }
        for j, a in args { if marks[j] && self.rooted(a) { self.written = true } }
    }''', '''    mut fn fed(marks: List<bool>, args: List<ExprId>, callee: string, names: List<string?> = []) {
        let labelled = args.any((a) -> self.store.arg_label(a) != null)
        let placed = labelled && names.length == marks.length && names.all(it != null)
        if args.any((a) -> self.store.spread_operand(a) != null) ||
            labelled && !placed ||
            !labelled && args.length > marks.length {
            if self.hands_receiver(args) { self.unread(handed_unread(callee)) }
            return
        }
        if !placed {
            for j, a in args { if marks[j] && self.rooted(a) { self.written = true } }
            return
        }
        let plan = self.store.seat_plan(args, [n! for n in names])
        for j, at in plan { if at >= 0 && marks[j] && self.rooted(self.store.unnamed(args[at])) { self.written = true } }
    }''')
# the callers that know their seats' names hand them
sub(w, '''            return self.fed(marks, args, name)
        }''', '''            return self.fed(marks, args, name, self.called_names(ty, name))
        }''')
sub(w, '''        self.fed([s.mutable for s in seats.drop(1)], args, name)
    }''', '''        self.fed([s.mutable for s in seats.drop(1)], args, name, [s.name for s in seats.drop(1)])
    }''')
sub(w, '''        self.fed([p.promises.mutable for p in item.store.fn_parts(s)!.params], args, name)''',
    '''        let params = item.store.fn_parts(s)!.params
        self.fed([p.promises.mutable for p in params], args, name, [p.name.of for p in params])''')
sub(w, '''        let marks? = written_seats(self.engine, d) else { return }
        self.fed(marks, args, callee)''', '''        let marks? = written_seats(self.engine, d) else { return }
        self.fed(marks, args, callee, seat_names(self.engine, d))''')
sub(w, '''    /// Which seats of a call of `name` through the type `ty` are `mut`: its static's, or none of a
    /// variant's.''', '''    /// The names of the seats a call of `name` on a value of `ty` fills, in order: its method's past the
    /// receiver, or a static's through the type; none where they aren't known.
    fn called_names(ty: SignedType, name: string) -> List<string?> {
        let described = ty.described()
        if described != null { return [s.name for s in static_type(self.engine, described!, name)?.seats ?? []] }
        if self.field_of(ty, name)?.ty?.callable() ?? false { return [] }
        [s.name for s in (self.method_seats(ty, name) ?? []).drop(1)]
    }

    /// Which seats of a call of `name` through the type `ty` are `mut`: its static's, or none of a
    /// variant's.''')
sub(w, '''/// The types the language owns whose values a seat copies.''', '''/// The names of the seats of the fn `d` names, in order, as `written_seats` reads them.
fn seat_names(engine: QueryEngine, d: DeclaredName) -> List<string?> {
    let item = read_item(engine, d.file, d.item)
    let external = [p! for s in item.stmts for p in [item.store.extern_parts(s)] if p != null && p!.name == d.name]
        .first()
    if external != null { return [p.name.of for p in external!.params] }
    let declared? = [p! for s in item.stmts for p in [item.store.fn_parts(s)] if p != null && p!.name == d.name]
        .first() else { return [] }
    [p.name.of for p in declared.params]
}

/// The types the language owns whose values a seat copies.''')
print('applied')
