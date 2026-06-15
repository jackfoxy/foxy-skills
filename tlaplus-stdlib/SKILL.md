---
name: tlaplus-stdlib
description: Understand and extend the TLA+ StandardModules and the Java override mechanism by which TLC replaces their TLA+ definitions with native methods. Use when adding/modifying a StandardModule, writing a TLC-specific operator override, or understanding operators like d:>e, @@, Permutations, SortSeq, RandomElement. For consuming these operators in specs see tlaplus-syntax; for broader engine internals see tlaplus-tools-internals.
user-invocable: true
disable-model-invocation: false
---

# Standard Library & the Override Mechanism

The StandardModules are real TLA+ (canonical good style), but TLC **overrides** most of them with Java for speed/decidability. This skill owns the override contract. Using the operators in specs: [[tlaplus-syntax]]; engine internals: [[tlaplus-tools-internals]].

`TLC.tla` states it: *"The definitions of all the operators in this module are overridden by TLC with methods defined in the Java class tlc2.module.TLC. Each definition is overridden with the method of the same name."*

## The contract in three rules
1. **Same name, same arity.** A TLA+ operator is overridden by the `public static Value <Name>(Value ...)` of the same name in `tlc2/module/<Module>.java` (args/return are TLC `Value` types).
2. **Infix ops map via `TLARegistry.put("Method", "op")`** in a `static { }` block (e.g. `d :> e`→`MakeFcn`, `@@`→`CombineFcn`, `\o`→`Concat`).
3. **TLA+ body and Java must stay equivalent** — the TLA+ is the behavioral spec (used by TLAPS etc.), the Java is the implementation.

The full operator table, the file lists for both sides, and the `@TLAPlusOperator` annotation form are in `references/operators-and-overrides.md`.

## Add or modify an override
1. Define/locate the operator in `StandardModules/<Module>.tla`.
2. Add the matching `public static Value <Name>(Value ...)` in `tlc2/module/<Module>.java` (or `@TLAPlusOperator` in `overrides/`). For an infix op, register it via `TLARegistry.put` in the class's `static` block.
3. Ensure the Java result equals the TLA+ definition for all inputs TLC will see.
4. `ant -f customBuild.xml compile compile-test` then targeted `test-set` ([[tlaplus-build-workflow]]); exercise with a small spec that uses the operator.

## Rules
- Method name/arity must exactly match the TLA+ operator; infix needs a `TLARegistry` entry.
- Don't break the TLA+ body when optimizing the Java — they must stay equivalent.
- `TLCGet/TLCSet` are per-worker after init; initialize shared values in `ASSUME`/`Init` (per the `TLC.tla` comment).

## Validation
Add a small override (e.g. a new TLC operator), confirm via a spec that TLC invokes the Java method (not the TLA+ body), and that name/arity/registry mapping are correct; run the targeted module tests.

## References (local)
- `references/operators-and-overrides.md` — operator table, both-side file lists, registry + annotation detail
- `src/tla2sany/StandardModules/*.tla` (esp. `TLC.tla`, `Sequences.tla`, `FiniteSets.tla`)
- `src/tlc2/module/*.java` (esp. `TLC.java`, `Sequences.java`), `src/tlc2/overrides/`, `src/tlc2/tool/impl/TLARegistry.java`
