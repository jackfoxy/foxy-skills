# `.cfg` Keys and TLC CLI Flags

## `.cfg` model-file keys

| Key | Meaning |
|-----|---------|
| `SPECIFICATION Spec` | the temporal spec formula (`Init /\ [][Next]_vars /\ Fairness`) |
| `INIT` / `NEXT` | alternative to `SPECIFICATION`: name init predicate + next action directly |
| `CONSTANT x = v` | assign a constant; `x = {a,b,c}` makes model values |
| `INVARIANT Inv` | state predicate (level ≤ 1) checked in every state |
| `PROPERTY Liveness` | temporal property (level 3): `[]`, `<>`, `~>`, fairness |
| `CONSTRAINT C` | state constraint — prune states where `C` is false (bounds search) |
| `ACTION_CONSTRAINT` | constraint on steps |
| `SYMMETRY Sym` | symmetry set (`Permutations(M)`) collapsing equivalent states |
| `VIEW`, `ALIAS` | custom state projection / trace display |
| `POSTCONDITION` | closing check run after model checking |
| `CHECK_DEADLOCK FALSE` | disable deadlock detection (same as `-deadlock`) |

Examples:
```
SPECIFICATION Spec          SPECIFICATION Spec
INVARIANT Inv               CONSTANTS NumProcs = 2
                                      MaxNum = 3
                            INVARIANT Invariant
                            CONSTRAINT Constraint
```

## TLC CLI flags (`tlc2.TLC -help`)

| Flag | Use |
|------|-----|
| `-config file` | the `.cfg` to use (defaults to `SPEC.cfg`) |
| `-workers N` / `auto` | parallel worker threads |
| `-simulate [num=Y]` | random simulation instead of exhaustive BFS |
| `-depth num` | bound depth (simulation / `-dfid`) |
| `-dfid num` | depth-first iterative deepening |
| `-deadlock` | do **not** check for deadlock |
| `-coverage minutes` | collect coverage stats |
| `-dump dot file.gv` | dump full state graph as DOT |
| `-dumpTrace json out.json` | dump error trace as JSON (also `-loadTrace`) |
| `-inv expr` / `-invlevel n` | extra invariant / level |
| `-seed num`, `-fp N`, `-fpbits num`, `-fpmem num` | reproducibility / fingerprinting |
| `-metadir path`, `-cleanup`, `-recover id` | run state directory management |
