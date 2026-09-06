# Standard Modules

`desk/lib/stdmods.hoon` vendors the **MIT-licensed upstream `StandardModules`
text verbatim**, with a provenance header. It is the only vendored upstream
text in the desk, and `tools/gen-stdmods.py` (20 cases) proves it reproduces
from the pin. Standard modules always resolve from here, never from a request's
bundle.

Present: `Naturals`, `Integers`, `Reals`, `Sequences`, `FiniteSets`, `Bags`,
`TLC`, `TLCExt`, `Randomization`, `RealTime`, `Json`, `Toolbox`.

## Choosing an operator

- **`Naturals`** — `+ - * ^ \div % .. < > \leq \geq`, `Nat`. `\div` is
  **floored**; `%` takes a positive divisor and gives a non-negative
  remainder; `Expt` and the 32-bit `IntValue` range follow the pin.
- **`Integers`** — adds `Int` and unary minus. The pin declares unary minus as
  `-.`; the port canonicalizes a prefix `-` to `-.` so the reachable key
  matches (`[Integers '-.' 1]`).
- **`Reals`** — present, but real arithmetic is not enumerable; use it for
  specification, not for checking.
- **`Sequences`** — `Seq Len Head Tail Append \o SubSeq SelectSeq`. Sequences
  are functions with domain `1..n`; `Seq(S)` is infinite, so never enumerate it
  without a bound.
- **`FiniteSets`** — `IsFiniteSet Cardinality`.
- **`Bags`** — `IsABag BagToSet SetToBag BagIn EmptyBag CopiesIn \oplus
  \ominus \sqsubseteq BagUnion BagCardinality BagOfAll`. A bag is a function to
  positive integers. `SubBag` is *not* overridden — it evaluates from its
  vendored TLA+ body.
- **`TLC`** — the model-checker's own operators: `:>` and `@@` (function
  construction and merge), `Print` / `PrintT` (which return their second/only
  argument), `Assert`, `ToString`, `Permutations` (for `SYMMETRY`), `SortSeq`,
  `TLCEval`, `TLCGet` / `TLCSet`, `RandomElement`.
- **`TLCExt`** — `CounterExample`, `TLCGetOrDefault`, `TLCGetAndSet`,
  `TLCCache`, `TLCDefer`, `TLCEvalDefinition`, `TLCFP`, `TLCModelValue`,
  `TLCNoOp`, `AssertError`.
- **`Randomization`** — `RandomSubset`, `RandomSetOfSubsets`,
  `TestRandomSetOfSubsets`.
- **`RealTime`**, **`Json`**, **`Toolbox`** — vendored; use only what the pin
  overrides.

## The register store

`TLCGet` / `TLCSet` and `TLCExt!TLCGetOrDefault` / `TLCGetAndSet` are live
(R2.7.4.3), measured at the pin and pinned by corpus cases whose **state count
depends on them**, so a dropped write cannot pass silently.

Two string keys stay refused **by name**: `TLCSet("exit", …)` stops the checker
mid-run and `TLCSet("pause", …)` blocks the search on stdin. Neither is a
channel this engine has, so they are named as unsupported rather than
misreported as bad arguments.

`TLCGet("duration")` and `TLC!JavaTime` are wall-clock and therefore
irreproducible — the same argument that refuses `_PERIODIC`.

## Randomness

All four drawing operators — `TLC!RandomElement` and the three `Randomization`
operators — share one `RandomEnumerableValues` generator, reproduced
byte-exactly against the pin **for a given seed**: `RandomSubset(3, 1..10)` is
`{1, 6, 9}` at seed 12345 and `{2, 9, 10}` at 987654321.

The generator is reseeded to `fingerPrint ^ seed` once per **predecessor
state**, so two draws in one action give two values. A comparison against the
Java tool is therefore pinned to `-fp 0` as well as `-seed N`.

**The one difference**: an unseeded tlc2 run draws its seed from `new
Random().nextLong()` and never prints it — nobody, including the spec's author,
can reproduce that run. Here the default seed is `0`, so every run is
reproducible by construction. Pass a seed to compare against the pin.

## Error text

Argument-error text for some `TLC` operators is **normalized** where the pin
fails inside a `MethodValue` cast naming a Java signature. The error code and
the failure are reproduced; the Java type names are not, because a Hoon port
has no analogue for them. This is an approved difference (`tlc-module-tlc`).
