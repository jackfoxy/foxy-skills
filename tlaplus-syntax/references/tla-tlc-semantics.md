# TLA+/TLC Semantic Gotchas

- `ASSUME` / `ASSUMPTION`: constant-level formulas. No state variables, primed variables, or temporal operators.
- `INVARIANT` / `INVARIANTS` in `.cfg`: state-level predicates checked in every reachable state.
- `PROPERTY` / `PROPERTIES` in `.cfg`: temporal formulas. If given a bare state predicate `I`, TLC checks it only for initial states; use `INVARIANT I` or `PROPERTY []I` for always.
- Action formulas may contain primed variables and are normally selected through `NEXT` or `[][Next]_vars`.
- TLC requires finite enumerable sets. `Seq(S)` is unbounded even for finite `S`; use bounded model-checking wrappers or overrides.
- TLC does not implement every mathematical TLA+ feature. Check `general/docs/current-tools.md` for divergences from Specifying Systems.
- Multiple workers can make reported diameter nondeterministic on some models.
- Definition replacement in `.cfg` behaves differently for `EXTENDS` and `INSTANCE`; use module-qualified replacement where needed.
