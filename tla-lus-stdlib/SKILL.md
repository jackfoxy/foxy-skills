---
name: tla-lus-stdlib
description: Use and extend the TLA+ standard modules in %tla-lus - Naturals, Integers, Sequences, FiniteSets, Bags, TLC, TLCExt, Randomization - and the lib/stdops override registry keyed [module operator arity] that replaces a vendored TLA+ body with a native implementation. Use when choosing a standard operator, adding or changing an override, or reasoning about value equality, ordering and identity. For consuming these operators in a spec see tla-lus-syntax.
user-invocable: true
disable-model-invocation: false
---

# Standard Library & Overrides

Two files, two jobs:

- `desk/lib/stdmods.hoon` — the **vendored upstream MIT `StandardModules`
  text**, verbatim, with its provenance header. The only vendored upstream text
  in the desk.
- `desk/lib/stdops.hoon` — the **override registry**, the Hoon equivalent of
  tlc2's `tlc2.module` binding. Keyed `[module operator arity]`, never a bare
  name.

- Which operator to use, and the module inventory →
  [references/standard-modules.md](references/standard-modules.md)
- The override mechanism, its machine-checked invariants, and how to add one →
  [references/overrides.md](references/overrides.md)

## The rule that matters

Most `StandardModule` bodies are **deliberate dummies** that the checker
overrides. So:

- An override **beats** the vendored body.
- An operator with neither an override nor an explicit body classification is a
  **typed rejection naming itself** — the dummy is never silently evaluated.
- Three properties are machine-checked against the pin by
  `tools/gen-stdops-tests.py`: every registry key is an operator the pin
  declares and classifies required; the **body-evaluable set equals the pin's
  un-overridden operators**; and each operator's laziness and `minLevel` equal
  its pinned annotation.

Operators needing more than evaluated values — an operator argument, a lazy
set, or an unevaluated `@Evaluation` node — dispatch to `desk/lib/node-eval.hoon`,
which owns the environment and the recursion budget.

## Present modules

`Naturals` `Integers` `Reals` `Sequences` `FiniteSets` `Bags` `TLC` `TLCExt`
`Randomization` `RealTime` `Json` `Toolbox`.

Live registry coverage: arithmetic and comparison from `Naturals`/`Integers`;
`Seq Len Head Tail Append \o SubSeq SelectSeq`; `IsFiniteSet Cardinality`; the
twelve `Bags` operators (`SubBag` evaluates from its body, as at the pin);
`:> @@ Assert ToString Print PrintT Permutations SortSeq TLCEval TLCGet TLCSet
RandomElement`; ten `TLCExt` operators including `CounterExample`; and the three
`Randomization` operators.

## Three things that surprise people

1. **Strings and model values order lexicographically**, not by Java intern
   order. This is an approved difference — intern order is an artifact of the
   Java toolchain's path, not of TLA+.
2. **Randomness is reproducible here.** The default seed is `0`; tlc2 draws an
   unprintable one. All four drawing operators share one generator, reseeded
   to `fingerprint ^ seed` once per **predecessor state**. Comparing against the
   pin needs `-seed N` **and** `-fp 0`.
3. **`TLCSet("exit"…)` and `TLCSet("pause"…)` are refused by name.** They are
   real tlc2 capabilities — stopping the checker and blocking on stdin — that
   this engine has no channel for, so they are named rather than misreported as
   bad arguments.
