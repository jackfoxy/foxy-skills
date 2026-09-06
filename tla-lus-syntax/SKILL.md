---
name: tla-lus-syntax
description: Read, write and validate TLA+ modules for the %tla-lus native parser - modules, EXTENDS/INSTANCE, operators vs functions, actions with primed variables, the operator precedence table, junction alignment, and the four expression levels. Use when inspecting or editing any .tla text, predicting whether the parser will accept it, or resolving a parse/semantic/level error. Owns the accepted-grammar reference for the pack.
user-invocable: true
disable-model-invocation: false
---

# TLA+ Syntax for `%tla-lus`

The port's parser is **verdict-identical to SANY** on the full upstream
syntax-conformance corpus (261 accept/reject cases), with node-for-node tree
agreement and byte-exact error text. So: if SANY accepts it, this accepts it.
There is no port-specific dialect.

TLA+ source is ASCII (Unicode operator spellings are also lexed); mathematical
glyphs in prose are presentation only.

## Route the task

- Constructs, legality, operators vs functions, modules, semantic distinctions
  → [references/language.md](references/language.md)
- The accepted productions, lexical rules, the precedence table, layout hazards
  → [references/grammar.md](references/grammar.md)
- Levels, name resolution, arities, `INSTANCE` substitution, module resolution
  → [references/levels.md](references/levels.md)
- The full grammar, production by production → `desk/doc/tla-bnf.md`
- Deeper semantics → `tla-lus-specification`'s book chapters 15–17.

## Module skeleton

```tla
---------------------------- MODULE Counter ----------------------------
EXTENDS Naturals

CONSTANT N
ASSUME N \in Nat                     \* constant level only

VARIABLE x
vars == <<x>>

TypeOK == x \in 0..N                 \* a type is an INVARIANT, not a declaration

Init == x = 0
Inc  == /\ x < N
        /\ x' = x + 1
Next == Inc
Spec == Init /\ [][Next]_vars /\ WF_vars(Inc)

Safe == x <= N
=============================================================================
```

`----` and `====` runs may be any length ≥ 4. Everything before the header and
after the footer is ignored.

## The distinctions that cause most errors

1. **Operators are not values; functions are.** `f[x]` applies a function,
   `Op(x)` applies an operator. `DOMAIN`, `[S -> T]` and `[x \in S |-> e]` are
   function constructs. You cannot pass an operator where a value is expected —
   use `LAMBDA` or a higher-order parameter (`Op(_, _)`).
2. **Records are functions with string keys**; `r.f` is `r["f"]`. Tuples are
   functions with domain `1..n`. `f[a,b]` abbreviates `f[<<a,b>>]`.
3. **`EXCEPT`**: `[f EXCEPT ![k] = e, ![j].g = v]`. `@` is legal *only* in an
   `EXCEPT` replacement and denotes the old targeted value.
4. **Priming distributes.** `f[e]'` means `f'[e']`.
5. **Precedence is a range, not a number.** Overlapping ranges make an
   unparenthesized mix *illegal* rather than arbitrary. No operator is
   right-associative. Parenthesize freely.
6. **Junction lists are delimited by column alignment.** Misalignment changes
   the parse or errors. **Never use tabs** — they advance columns to multiples
   of eight.
7. **`CHOOSE` is deterministic but unspecified.** For nondeterminism use
   `x' \in S`.
8. **Level matters**: constant (0), state (1), action (2), temporal (3).
   `ASSUME` is level 0. An `INVARIANT` is level ≤ 1; a `PROPERTY` may be
   level 3.

## Reviewing a module, in order

1. Lexing and module delimiters — is the header/footer run long enough, are
   there tabs, is a `(* *)` comment closed?
2. Alignment, delimiters, precedence.
3. Name resolution, scope, arity, duplicate declarations.
4. Expression level and legal priming.
5. Domain guards and Boolean expectations — a legal expression may still have
   an unspecified value.
6. Mathematical meaning on **all** states, not just intended typed ones.
7. Evaluability, which is narrower than legality: TLC (and this engine) must be
   able to *enumerate*. Unbounded quantification over `Nat` parses and level-checks
   and then fails at evaluation.

## Getting the parser to tell you

Submit an `%analyze` request with `flags=[& & & &]` — syntax, semantic, level
and lint. `syntax` must be `&` (parsing is mandatory; see `tla-lus-agent`).
Diagnostics arrive as `%sany`-family codes with exact SANY text and a source
span. A *successful* parse emits no diagnostics at all.

The parser reports where **no valid continuation exists**, which can be later
than the actual mistake. Read the `Was expecting "…"` line and the residual
stack trace, and reduce the surrounding expression. See `tla-lus-debugging`.
