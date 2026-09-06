---
name: tla-lus-specification
description: Expert TLA+ systems specification - choose the abstraction, variables and grain of atomicity, write safety and liveness properties, justify fairness, and argue refinement, composition, hiding and real time. Grounded in Lamport's Specifying Systems and adapted to what the %tla-lus engine actually checks. Use when designing, reviewing, or repairing a specification as a mathematical description of behaviors, before reaching for syntax or tool options.
user-invocable: true
disable-model-invocation: false
---

# Specifying Systems

A specification is a **mathematical description of allowed behaviors**, not
executable code. Preserve the user's intended abstraction, and keep separate
what is proved *in TLA+* from what is *evidence from a finite model check*.

## Route the task

- Abstraction, variables, atomicity, actions, data representation, authoring
  workflow → [references/modeling.md](references/modeling.md)
- Liveness, fairness, machine closure, hiding, refinement, composition, open
  systems, real time → [references/temporal-refinement.md](references/temporal-refinement.md)
- Provenance or deeper treatment → [references/source-map.md](references/source-map.md),
  then the one chapter it names.
- Exact constructs, operators, levels → `tla-lus-syntax`
- `.cfg`, modes, statistics → `tla-lus-model-checking`

## Work at expert level

1. **Identify the question before writing formulas.** What system view? What
   failures? What environment behavior? What is observable? Where is the
   correctness boundary?
2. **Write a few representative behaviors first**, including failures and
   races. Choose the state variables and the grain of atomicity *from those
   behaviors*, not from the implementation's structure.
3. **Structure the module** as: constants and constant assumptions; `TypeOK`;
   `Init`; named action subrelations; `Next` as their disjunction; `vars` as
   the tuple of **all** flexible variables; `Spec == Init /\ [][Next]_vars`
   plus justified fairness or timing only when needed; then the safety,
   liveness and refinement claims.
4. **Make every action explicit about every variable** it changes or leaves
   unchanged. Prefer `x' = e` or `x' \in S` to clever relational encodings.
5. **Keep the spec stuttering-invariant.** `[Next]_vars`, `<<A>>_vars`,
   `WF_vars(A)`, `SF_vars(A)` — always with the complete variable tuple.
6. **Treat types as invariants.** Ensure `Init => TypeOK` and that
   `[Next]_vars` preserves an adequate inductive invariant. Check `TypeOK`
   before anything else.
7. **Validate incrementally.** `%analyze` first (parse, semantic, level, lint);
   then a *tiny* `%check`; inspect action coverage; deliberately check at least
   one property you know is **false**, to prove the model can fail; then
   enlarge or simulate.
8. **For a refinement claim**, supply the mapping or hiding relation and check
   initial-state correspondence, step simulation including mapped stuttering,
   and liveness — separately.

## Non-negotiable semantic checks

- `ASSUME` is **constant-level**. Never use it to assert a variable's type.
- TLA+ is **untyped** and every value is a set. Do not infer that visually
  different values are unequal; use tagged records or model values when
  inequality matters.
- `CHOOSE` is **deterministic but unspecified**, not nondeterministic. Express
  a nondeterministic next value with membership (`x' \in S`).
- Priming an expression primes **every** flexible variable in it: `f[e]'` means
  `f'[e']`.
- A bare action under a temporal operator is generally not a legal TLA formula.
  Use the bracket/angle forms.
- **Weak fairness** covers continuous enablement; **strong fairness** covers
  infinitely recurring enablement. Prefer weak unless interruption can starve
  the action.
- Fairness on **subactions of `Next`** preserves machine closure. Fairness on a
  non-subaction can silently constrain safety.
- Temporal hiding (`\EE x : F`) is not ordinary rigid quantification and is not
  supported by classic TLC or by this engine.
- A model check establishes results **for the configured finite model only**.
  Never call a successful run a proof for all constants or all behaviors.
- `CONSTRAINT`, `ACTION_CONSTRAINT`, `VIEW` and `SYMMETRY` change or compromise
  what is explored. State the soundness implication when you use one —
  especially for liveness.

## What this engine adds to the picture

- **A run is bounded by `limits` and returns `%limited` rather than dying.**
  Design constant sets that fit; report `%limited` honestly.
- **Verdicts are typed, not printed.** `%ok`, `%violated` (with the
  counterexample), `%limited`, `%failed`, `%cancelled`. A counterexample is a
  *successful* run.
- **Runs are reproducible by construction** — the default RNG seed is 0, where
  the Java tool draws an unprintable one.
- **Anything unsupported is refused by name at submit or at `%config`**, never
  silently degraded. Check `tla-lus-overview`'s support matrix before
  promising a capability.

## Deliverables

Return complete, parseable `.tla` and `.cfg` text whenever the user needs to
run something. Explain only the modeling decisions or proof obligations that
materially affect correctness. If you can run the agent, run the **narrowest
relevant** check and report the exact property checked, the model bounds, and
which of `%ok`/`%violated`/`%limited` you got.
