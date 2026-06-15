---
name: tlaplus-pluscal
description: Write and debug PlusCal algorithms and run the pcal.trans translator that compiles them into TLA+ inside the same .tla file. Use when authoring/translating PlusCal, choosing fairness options, understanding the parse/label/translate pipeline, or maintaining the translator. For checking the generated TLA+ see tlaplus-model-checking.
user-invocable: true
disable-model-invocation: false
---

# PlusCal & the Translator

PlusCal is an algorithm language embedded in a TLA+ comment; `pcal.trans` parses it and writes the equivalent TLA+ back into the **same file** between `BEGIN/END TRANSLATION` markers, plus a `.cfg`. Then model-check the generated TLA+ with [[tlaplus-model-checking]]. Translator internals overlap [[tlaplus-tools-internals]].

## Authoring

Algorithm goes in a TLA+ comment `(* ... *)`:
```tla
-------------------------------- MODULE Counter --------------------------------
EXTENDS Naturals
(*
--algorithm Counter {
  variable x = 0;
  { while (x < 3) { x := x + 1 } }
}
*)
================================================================================
```
Building blocks (`variable`, `process`, labels, `:=`, `while`, `if`, `either/or`, `with`, `await`, `assert`) and the fairness options are in `references/pipeline-and-options.md`.

## Translate (validated)

```bash
java -cp dist/tla2tools.jar pcal.trans Counter.tla   # rewrites Counter.tla in place, writes Counter.cfg
```
Reports `Labels added. / Parsing completed. / Translation completed.` and inserts (between `\* BEGIN TRANSLATION` / `\* END TRANSLATION`):
- `VARIABLES pc, x` — a `pc` (program-counter) variable is added per process.
- `vars`, `Init`, one action operator per label (`Lbl_1 == /\ pc = "Lbl_1" /\ ...`), `Terminating`, `Next`, `Spec`, and `Termination == <>(pc = "Done")`.

An embedded `chksum(pcal)/chksum(tla)` lets tools detect a stale translation.

## Fairness (essentials)
`-nof` (default), `-wf`/`-sf` (per-process weak/strong), `-wfNext` (whole next-state), `-termination` (adds `Termination` to the `.cfg`). Full table + the 3-phase pipeline (parse → label/fix-ids → translate) and failure modes: `references/pipeline-and-options.md`.

## Workflow
PlusCal source → `pcal.trans` → generated TLA+ (+`.cfg`) → SANY parse → TLC ([[tlaplus-model-checking]]). For termination, translate with `-termination` and check `Termination`.

## Validation
Translate a PlusCal algorithm, confirm the generated TLA+ parses (`tla2sany.SANY`) and model-checks; verify the added `pc`/labels match the algorithm's atomic steps and the checksum is fresh.

## References (local)
- `references/pipeline-and-options.md` — language constructs, fairness options, translation phases, failure modes
- `tlatools/org.lamport.tlatools/src/pcal/` — `trans.java`, `ParseAlgorithm.java`, `PcalTranslate.java`, `PcalTLAGen.java`, `AST.{java,tla}`, `help.txt`, `Pcal.tla`, `PlusCal.{tla,cfg}`, `XPlusCal.{tla,cfg}`
