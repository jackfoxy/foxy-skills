---
name: tla-lus-debugging
description: Diagnose and recover from %tla-lus failures - submit rejections, SANY parse and semantic errors, level errors, CFG_*/TLC_CONFIG_* config errors, evaluation failures, invariant and liveness violations, deadlock, and %limited results; and read counterexample traces and lassos. Use for any rejection, opaque diagnostic, unexpected verdict, or trace analysis. Owns the diagnostic-code taxonomy for the pack.
user-invocable: true
disable-model-invocation: false
---

# Debugging `%tla-lus`

- Code families, ranges, and the four `%lus` codes →
  [references/error-codes.md](references/error-codes.md)
- Symptom-by-symptom recovery, and how to read a trace →
  [references/failure-modes.md](references/failure-modes.md)

## Triage in four questions

1. **Did the poke get `%rejected`?** Then no job exists and the reason string
   is the whole diagnosis — it is submit-time validation. Look it up in
   `tla-lus-overview`'s support matrix.
2. **Is the result `%failed`?** The engine could not answer. `reason` names
   why; an `unsupported: …` prefix means a documented refusal, not a bug.
3. **Is it `%violated`?** That is a **successful** run. Read the trace.
4. **Is it `%limited`?** A bound was hit; the statistics are a lower bound on
   the real state space. Nothing is wrong.

Anything else — a crash, a `[%lus 400]`, a divergence from the Java tool that
is not in `compatibility.md` — is a defect worth reporting.

## The five highest-yield checks

- **Run `%analyze` with all four flags** before debugging a `%check`. Most
  confusing check failures are semantic or level errors that `%analyze` names
  precisely.
- **Put `TypeOK` first in the `.cfg`.** Invariants are checked in declaration
  order; the first failure is the one reported, and a type error usually
  explains everything after it.
- **Check `violation.initial`.** `&` means the *initial-state computation*
  found it (EC 2107/2108) — there is no behaviour, no statistics, and the
  `trace` is a single offending state, not a counterexample.
- **A stuttering lasso means no fairness.** Without `WF_`/`SF_` under a
  `SPECIFICATION`, the do-nothing behaviour is legal and violates every
  liveness property.
- **`deadlock=&` on a spec that legitimately terminates** reports "done" as
  "broken". Turn it off.

## Before blaming the port

Check `desk/doc/compatibility.md`. **Ten** ledger rows are approved
differences, each pinned by a differential test: lexicographic string and
model-value order, the default RNG seed of 0, `-terse` rendering, DFID
counterexample traces, coverage's two absent line kinds and its silence on a
violating run, the in-memory product graph, `_PERIODIC`'s refusal, and the
narrower `lib/eval`. Rows that `compatibility.md` marks ✅ CLOSED are the
**record of a difference that no longer exists**. See `tla-lus-parity`.

To reproduce the Java side, use the pin (`tlaplus@4ba7d8811`) with `-fp 0` and
an explicit `-seed`; `tla-lus-dev-workflow` has the invocation.
