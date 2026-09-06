---
name: tla-lus-dev-workflow
description: Build, deploy, test and gate the %tla-lus desk - copy and commit the desk to a ship, run the two tier-1 halves (validate.py --check and -test on the ship), tier 2 and the tier-3 report, the scaffold and release gates, the differential generators, fuzzing, and how to add a test case. Use for any development loop on this repo. Owns every command line for the pack.
user-invocable: true
disable-model-invocation: false
---

# Development Workflow

- Every command line, deploy through gates →
  [references/commands.md](references/commands.md)
- Adding cases, randomized-operator rules, fuzzing, close-out discipline →
  [references/adding-tests.md](references/adding-tests.md)
- Why a difference is allowed, and the oracle itself → `tla-lus-parity`

## The loop

```bash
# 1. edit desk/lib/... or desk/app/...
# 2. regenerate anything whose fixtures you touched
python3 tools/gen-<stage>-tests.py
# 3. tier 1, half one
python3 tools/validate.py --check
```
```
::  4. deploy and run tier 1, half two
|commit %tla-lus
-test /=tla-lus=/tests ~          ::  expect ok=%.y
```

Then, before calling a unit done, the close-out sequence in
[references/adding-tests.md](references/adding-tests.md) — tier 1, tier 2,
ledger, scaffold gate, release gate, acceptance, suite.

## Rules that are not negotiable here

1. **Never weaken a golden without first proving the Java behaviour from the
   pin.** `validate.py` refuses to regenerate off-pin for exactly this reason.
2. **An intentional divergence is documented before it is shipped** — a
   `compatibility.md` entry and a ledger row. The release gate checks every
   `unsupported:` message in **both** directions.
3. **A gate that never runs is not a gate.** Run the whole close-out sequence,
   and read a red gate's *other* clauses — this project lost nine units to a
   stale clause nobody executed, and later found two rotted clauses hiding
   behind one that was red on purpose.
4. **Do not edit `r1-acceptance.py` to pass.** It is the record of what R1
   proved and it correctly still prints `R1 NOT ACCEPTED`.
5. **Prove which part of an oracle is comparable; do not assert it.** Where the
   Java tool is not a function of its input, measure the variance first — the
   pattern is `gen-dfid-tests.py`, which runs the jar 8× per case.
6. **Fix a fuzz crash last.** Reduce it, commit it as a fixture in the corpus
   that owns the stage, capture its golden — *then* fix the port.

## Status commands

```bash
python3 tools/check-parity.py     # ledger well-formed; how many rows still owed
bash tools/release-gate.sh        # PASSES as of 2026-09-05 (R3.0d)
```

Current: **134 rows, 0 owed**; release gate green; `r3-acceptance.py
--suite-log` prints **R3 ACCEPTED** on 5/5 (2179 suite arms, 0 failed).

## Environment

- `TLA_REPO` — the pinned `tlaplus` checkout (`scaffold-gate.sh` defaults to
  `/mnt/mars/gitrepos/tlaplus`), which must sit exactly at
  `4ba7d8811289fb8e95dac4d5e554c05216ba3100`.
- A ship with the desk installed, for the Hoon suite and any live run.
- Python 3 and, for regenerating goldens, a JDK and Ant to build
  `tla2tools.jar`.

The jar is **only** used to build goldens. It is never shipped and never called
at runtime — the scaffold gate checks that the desk contains no Java, no GUI,
and no `tla2tex`.
