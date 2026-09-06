---
name: tla-lus-pluscal
description: PlusCal algorithms - p-syntax and c-syntax, labels and the grain of atomicity, macros, procedures, processes, the fairness flags, and the CRC-32 translation checksums - plus exactly what %tla-lus refuses today and the checklist to enable translation when it is ported. Use when authoring or reviewing PlusCal, reasoning about a translated module, or planning PlusCal support. For checking the generated TLA+ see tla-lus-model-checking.
user-invocable: true
disable-model-invocation: false
---

# PlusCal

> **Not available in `%tla-lus` today.** Both PlusCal entry points are typed
> rejections at submit:
>
> - `op = %translate` → `unsupported: PlusCal translation is not ported yet (unit 8)`
> - `check-opts.translate = &` → `unsupported: translate-before-check is not ported yet (unit 8)`
>
> The **generated TLA+ checks normally** — translate with the pinned Java
> `pcal.trans`, then submit the resulting module as an ordinary `%analyze` or
> `%check`.

- Language reference, labels, fairness, checksums, reviewing a translation →
  [references/pluscal.md](references/pluscal.md)
- What exists already and the checklist to turn it on →
  [references/enablement.md](references/enablement.md)

## Why it is off

The ledger marks it **`excluded`**, not `absent`: PlusCal translation is
outside PORT-COMPLETION-PLAN-2's scope boundary (tla2sany + tlc2 parity), a
decision taken at R1.0 and reaffirmed at R3.1. The refusal message reads "not
ported yet", which sounds provisional; the ledger's status is the operative
one. Bringing it in is a **scope decision first**, an implementation task
second.

Invariant 8 governs the interim: **no stub ever returns a plausible
translation.**

## What is already in place

The wire (`op`'s `%translate` arm, `pcal-opts`, `fairness`), the `%translate`
stage tag, the CRC-32 primitive the translation markers need
(`desk/lib/crc.hoon` — **ported and at parity**), two corpus fixtures, and two
oracle-only goldens from `tools/gen-pcal-tests.py`. Missing: the translator
itself.

Because the wire already has the right shape, enabling PlusCal is **capability,
not a wire reshape** — it would not move `api-version` even after release.

## Today's workflow

```bash
java -cp tla2tools.jar pcal.trans -wf -termination Counter.tla   # rewrites in place
```

Then submit `Counter.tla` (and the generated `Counter.cfg`) as an `%inline` or
`%clay` bundle. Two things to expect:

- the generated `.cfg` uses `SPECIFICATION Spec`, so `coverage` is **refused**
  on it (the INIT action has no declaration to label — use `INIT`/`NEXT` if you
  need coverage);
- `vars` includes `pc` and any procedure stack, so counterexample traces are
  longer and noisier than for a hand-written spec. `ALIAS` helps on safety
  paths, but is refused with a temporal `PROPERTY`.

## The one rule that catches everyone

**A label defines the grain of atomicity**, and a variable may be assigned at
most once per label. Everything between one label and the next becomes a single
TLA+ action — so an unlabeled sequence touching a shared variable is atomic,
which is almost never what a concurrent algorithm means. Use `-label` to have
the translator insert the mandatory ones, then read where it put them.

**Never hand-edit between the `BEGIN`/`END TRANSLATION` markers.** The two
CRC-32 checksums on the `BEGIN` line exist to detect exactly that.
