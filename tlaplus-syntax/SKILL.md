---
name: tlaplus-syntax
description: Read, write, and validate TLA+ modules and standard usage patterns - modules/EXTENDS/INSTANCE, operators, actions with primed variables, invariants vs temporal properties, and level checking. Use when inspecting or editing any .tla file, authoring specs/extensions, or predicting whether SANY will accept a module. Owns the canonical module-example reference for the pack.
user-invocable: true
disable-model-invocation: false
---

# TLA+ Syntax & Spec Reading

Owns module/operator examples. Running a spec: [[tlaplus-model-checking]]; errors: [[tlaplus-debugging]]; stdlib internals: [[tlaplus-stdlib]]. Map constructs to *Specifying Systems* (https://lamport.azurewebsites.net/tla/book.html).

## Validate first: parse with SANY before TLC

```bash
java -cp dist/tla2tools.jar tla2sany.SANY MySpec.tla
```
SANY reports lexical, syntactic, semantic, and **level** errors. A spec must parse cleanly before TLC can check it.

## Module anatomy (book ch. 3-4)

```tla
---------------------------- MODULE DieHard ----------------------------
EXTENDS TLC, Integers          \* import + re-export operators

Min(m, n) == IF m < n THEN m ELSE n   \* operator definition (==)

VARIABLES bigBucket, smallBucket      \* state variables
vars == << bigBucket, smallBucket >>  \* tuple of all vars

Init == /\ bigBucket  = 0             \* state predicate (level 1)
        /\ smallBucket = 0

Next == \/ /\ bigBucket' = 5          \* action: primed = next-state value
           /\ UNCHANGED smallBucket
        \/ /\ smallBucket' = 3
           /\ UNCHANGED bigBucket

Spec == Init /\ [][Next]_vars         \* temporal formula (level 3)
Inv  == bigBucket # 4                  \* invariant (state predicate, level 1)
=============================================================================
```
- `----` header/footer delimit the module; name must match filename.
- `==` defines; `'` = next-state value; `UNCHANGED x` ≡ `x' = x`; `[Next]_vars` allows stuttering.

Notation, the full level-checking rules, invariant-vs-property, the TLC-specific operators, and the standard-module list are in `references/operators-and-levels.md`.

## The level gate (most common semantic rejection)
Expressions are level **0 constant / 1 state / 2 action / 3 temporal**. SANY rejects: priming inside a prime or a temporal operator; an `INVARIANT` that is really level-2/3; `Seq(S)` as an enumerable bound. An `.cfg` `INVARIANT` must be level ≤ 1; a `PROPERTY` is level 3. (Details + table in the reference.)

## Checklist: reading an unfamiliar module
1. Note `EXTENDS`/`INSTANCE` — what vocabulary is in scope.
2. Identify `CONSTANTS`, `VARIABLES`, `ASSUME`.
3. Find `Init`, `Next` (or `vars`/`Spec`); note each operator's level.
4. Separate invariants (level 1) from properties (level 3).
5. Run `tla2sany.SANY` to confirm it parses and is level-correct.

## Validation
Given a module: list its operators with levels, classify each named predicate as invariant vs. property, predict SANY's verdict, then run `tla2sany.SANY` to confirm.

## References (local)
- `references/operators-and-levels.md` — notation, level rules, invariants/properties, TLC ops, stdlib list
- `tlatools/org.lamport.tlatools/src/tla2sany/StandardModules/*.tla` (esp. `TLC.tla`, `Sequences.tla`, `FiniteSets.tla`)
- `tlatools/org.lamport.tlatools/test-model/DieHard.tla` (example only)
- Book: https://lamport.azurewebsites.net/tla/book.html (ch. 2-4 syntax, 16-17 levels)
