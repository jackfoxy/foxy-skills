# PlusCal: Language, Options & Translation Pipeline

## Language building blocks
Put the algorithm in a TLA+ comment `(* ... *)`. C-syntax (braces) or P-syntax (begin/end). Constructs:
- `variable(s)`, `process (P = id) { ... }` / `process (P \in Set)`
- labels `Lbl:` (mark atomic steps / `pc`)
- `:=` assignment (multiple in one label are simultaneous)
- `while`, `if`/`else`, `either`/`or` (nondeterminism), `with` (nondeterministic binding)
- `await`, `skip`, `assert`, `print`

## Translator options (`pcal.trans`, affect the emitted `Spec`)

| Option | Effect |
|--------|--------|
| `-nof` | no fairness (default, unless `-termination`) |
| `-wf` | weak fairness of each process's next-state action |
| `-sf` | strong fairness of each process's next-state action |
| `-wfNext` | weak fairness of the entire next-state action |
| `-termination` | add the `Termination` check to the `.cfg` |
| `-help` | print help instead of translating |

## Translation pipeline (three phases)
1. **Parse** the algorithm (`ParseAlgorithm.java`, `Tokenize.java`) into an AST (`AST.java` / `AST.tla`).
2. **Label / fix identifiers** — add missing labels (atomic steps) and rename to avoid clashes (`PcalFixIDs.java`, `PcalSymTab.java`).
3. **Translate** the AST to TLA+ text (`PcalTranslate.java`, `PcalTLAGen.java`, `PCalTLAGenerator.java`); `TLAtoPCalMapping` records source mapping.

`Pcal.tla`, `PlusCal.tla`/`PlusCal2.tla`/`XPlusCal.tla` (+ `.cfg`) are the translator's own reference/test specs.

## Common failure modes
- **Identifier clashes**: PlusCal vars colliding with TLA+ defs → renamed in phase 2; invariants referencing the original name may not match.
- **Missing labels**: illegal control flow across atomic steps; translator adds labels but placement affects atomicity/state count.
- **Stale translation**: editing the algorithm without re-running `pcal.trans` leaves the embedded `chksum(pcal)/chksum(tla)` mismatched.
