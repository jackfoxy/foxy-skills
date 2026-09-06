# Source Map — *Specifying Systems*

The TLA+ semantics in this pack are grounded in Leslie Lamport's *Specifying
Systems*. Eleven chapter summaries are copied into
[book/](book/) so the pack is self-contained; the complete set of 18 lives at
`FoxyLabs/tla-lus/specifying-systems/`. Open a chapter only when a question
needs more depth or provenance than the skills carry — do not load them by
default.

| Topic | Chapter |
|---|---|
| States, behaviors, actions, stuttering, canonical spec form | [ch02](book/ch02-specifying-a-simple-clock.md) |
| Advanced sets, untyped semantics, operators vs functions, `CHOOSE` | [ch06](book/ch06-some-more-math.md) |
| Abstraction, atomicity, data modeling, specification workflow | [ch07](book/ch07-writing-a-specification-some-advice.md) |
| Temporal logic, fairness, machine closure, temporal quantification | [ch08](book/ch08-liveness-and-fairness.md) |
| Real time, action bounds, non-Zeno and hybrid specifications | [ch09](book/ch09-real-time.md) |
| Composition, shared state, joint actions, open systems, interface refinement | [ch10](book/ch10-composing-specifications.md) |
| TLC semantics, configuration, checking, simulation, debugging | [ch14](book/ch14-the-tlc-model-checker.md) |
| Complete ASCII syntax, precedence, alignment, lexing | [ch15](book/ch15-the-syntax-of-tla-plus.md) |
| Constant, action, and temporal operator semantics | [ch16](book/ch16-the-operators-of-tla-plus.md) |
| Levels, contexts, module meaning, instantiation semantics | [ch17](book/ch17-the-meaning-of-a-module.md) |
| Standard modules: sequences, finite sets, bags, numbers | [ch18](book/ch18-the-standard-modules.md) |

Not copied (available at the original location): ch01 (elementary math), ch03–05
and ch11 (worked examples: asynchronous interface, FIFO, caching memory,
advanced examples), ch12 (the SANY CLI), ch13 (TLATeX — no analogue here).

## Coverage boundary

The book covers the TLA+ language, systems modeling, SANY, TLC and TLATeX. It
does **not** cover PlusCal, TLAPS proof scripts, editor integration, distributed
TLC, or post-book tool features — and it predates everything specific to this
port. For what `%tla-lus` actually implements, the desk's own documentation is
authoritative and the book is the semantics behind it. Never invent syntax or
claim book coverage that is absent.
