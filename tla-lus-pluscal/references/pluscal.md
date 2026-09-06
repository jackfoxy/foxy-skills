# PlusCal Reference

Keep this reference for authoring and for reasoning about a translated module.
None of it can be *run* through `%tla-lus` today — see
[enablement.md](enablement.md).

> Note: PlusCal is **not** covered by *Specifying Systems*. The authority is
> Lamport's separate PlusCal manual and the pinned `pcal` sources at
> `tlaplus@4ba7d8811`.

## What PlusCal is

An algorithm language that lives **inside a TLA+ comment** and compiles to TLA+
**in the same file**. The translator rewrites the file in place, inserting the
generated TLA+ between `\* BEGIN TRANSLATION` and `\* END TRANSLATION` markers,
and (unless suppressed) writes a `<File>.cfg`.

```tla
---- MODULE Counter ----
EXTENDS Naturals

(* --algorithm counter
   variables x = 0;
   begin
     Loop:
       while x < 4 do
         x := x + 1;
       end while;
   end algorithm; *)

\* BEGIN TRANSLATION (chksum(pcal) = "…" /\ chksum(tla) = "…")
\* … generated TLA+ …
\* END TRANSLATION
====
```

Two dialects: **p-syntax** (`begin`/`end`, as above) and **c-syntax** (braces).
They are interchangeable; the translator accepts either.

## The pieces

| Construct | Notes |
|---|---|
| `variables` | algorithm variables; become TLA+ `VARIABLE`s |
| `define … end define` | plain TLA+ definitions visible to the algorithm |
| `macro` | textual expansion at the call site — no recursion, no labels |
| `procedure` / `call` / `return` | uses a generated call stack |
| `process` | a concurrent process, `process P \in Set` for a set of them |
| `begin` / `end algorithm` | the body of a uniprocess algorithm |
| `:=` | assignment; **at most one per variable per label** |
| `await` / `when` | a guard — the step is only enabled when it holds |
| `with x \in S do … end with` | nondeterministic choice |
| `either … or … end either` | nondeterministic branch |
| `skip`, `print`, `assert` | as expected |
| labels | **define the grain of atomicity** |

## Labels are the whole game

A label marks the start of an atomic step. Everything between one label and the
next becomes **one** TLA+ action. So:

- Splitting a sequence with a label makes it interleavable with other
  processes — usually what you want when modeling concurrency.
- Not splitting it makes it atomic — usually wrong for anything crossing a
  shared variable.
- The translator **requires** labels where a step boundary is mandatory (after
  a `call`, at the top of a `while`, at the start of a process body) and
  **forbids** them where a step cannot begin. `-label` asks it to insert the
  missing ones and name them.
- A variable may be assigned **at most once per label**. Assigning twice is the
  most common translation error; add a label or restructure.

## Fairness

`pcal.trans` takes exactly one of:

| Flag | `pcal-opts.fairness` | Meaning |
|---|---|---|
| `-nof` | `%none` | no fairness conjuncts |
| `-wf` | `%wf` | weak fairness on every process |
| `-sf` | `%sf` | strong fairness on every process |
| `-wfNext` | `%wf-next` | a single `WF_vars(Next)` |

Plus `-termination`, which adds a `Termination` property asserting every
process reaches its end, and `-nocfg`, which suppresses the generated `.cfg`.

`%wf` is the usual choice. `%wf-next` is weaker than it looks: one fairness
conjunct on the whole next-state relation does not prevent one process from
starving another.

## The checksum markers

The `BEGIN TRANSLATION` line carries two CRC-32 checksums —
`chksum(pcal)` over the parsed algorithm AST's `toString()`, and `chksum(tla)`
over the generated TLA+ text. Both are
`Long.toHexString(new CRC32().update(bytes).getValue())`: a reflected CRC-32
with polynomial `0xEDB8.8320`, rendered as lowercase hex with **no leading
zeros and no `0x` prefix**, so the empty string yields `"0"`.

They exist so the translator can tell whether the TLA+ below the marker is
still the translation of the algorithm above it — i.e. whether someone
hand-edited generated code.

**This primitive is ported and at parity**: `desk/lib/crc.hoon` reproduces
`java.util.zip.CRC32` + `Long.toHexString` exactly (ledger row `pcal-crc`,
7 tests in `desk/tests/lib/crc.hoon`). It is the one piece of the PlusCal
toolchain that exists in the desk today.

## Reviewing a translated module

The generated TLA+ is ordinary TLA+ and everything in `tla-lus-syntax`,
`tla-lus-specification` and `tla-lus-model-checking` applies to it. Points to
check:

- `vars` must be the tuple of **all** variables, including `pc` and any
  procedure stack.
- Each label becomes an action guarded on `pc`; a `Next` disjunction over
  process actions plus a termination disjunct.
- The generated `.cfg` names `Spec` as `SPECIFICATION` — so `-coverage` is
  refused on it here (the INIT action has no declaration to label).
- **Never hand-edit between the markers.** Change the algorithm and retranslate;
  the checksums exist to catch exactly that.

Since `%tla-lus` cannot translate, the workflow today is: translate with the
pinned Java `pcal.trans`, then submit the **resulting TLA+** as an ordinary
`%check` or `%analyze` request.

```bash
java -cp tla2tools.jar pcal.trans [-nocfg] [-wf|-sf|-wfNext|-nof] \
     [-termination] [-label] [-lineWidth n] FILE       # rewrites FILE in place
```
