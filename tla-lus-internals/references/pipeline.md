# The Pure Pipeline (`desk/lib/`)

Each library is a port of a Java stage, validated against it. `desk/doc/port-map.md`
carries the Java-to-Hoon traceability class by class; `desk/doc/architecture.md`
is the narrative. This is the working map.

```
source.hoon       UTF-8 codec + SimpleCharStream position model
  |
lexer.hoon        TLA+ token manager                      (vs TokenDump)
  |
ast.hoon          concrete syntax-tree mold + AstDump renderer
syntax.hoon       SANY parser: operator stack, junctions
  |
modules.hoon      EXTENDS/INSTANCE resolution, std modules,
stdmods.hoon      dependency-first sem-order, parse cache
source-path.hoon  the ONLY constructor of a source-ref
  |
semantic.hoon     name resolution, arities, builtin table, per-def levels
                  (0/1/2/3); INSTANCE substitution (parametrized/nested/HO
                  params, RECURSIVE-through-WITH), LAMBDA + HO op-args,
                  tuple + operator-symbol binders
  |
config.hoon       TLC .cfg parse + config-vs-graph validation + typed run-spec
  |
value.hoon        canonical TLC values (equality, order, render, FP64 input
                  bytes, lazy sets)
stdops.hoon       override registry keyed [module operator arity]
node-eval.hoon    semantic-node evaluator + action solver (init/next-states)
fingerprint.hoon  FP64 fingerprints, FPSet, symmetry orbit canonicalization
  |
eval.hoon         constant evaluation (vs the TLC REPL); retired from the
                  safety path but owns the canonical `value` mold
  |
check.hoon        safety BFS: ordered invariants, constraints, deadlock,
crc.hoon          symmetry, FP64 identity, shortest traces, out-degree;
                  liveness scan, seeded simulation
  |
temporal.hoon     temporal-PROPERTY normalization: the LN* live-expression
                  tree, astToLive/simplify/toDNF/pushNeg/makeBinary/
                  extractPromises, and the OrderOfSolution/PossibleErrorModel
tableau.hoon      Manna-Pnueli particle tableau (particleClosure as an
                  alpha/beta expansion to a FIXPOINT)
liveness.hoon     product build, PEM accepting sets, Tarjan SCC, verdict, lasso
  |
job.hoon          resumable stage engine, jammed continuation, typed %limited,
                  asynchronous %modules source load, quotas
```

Supporting: `diagnostics.hoon` (MP message rendering, diagnostic ordering),
`rng.hoon` (`java.util.Random` reproduced — `nextInt`/`nextLong`/`nextDouble`/
`nextPrime`/`setSeed`), `skeleton.hoon`, `test.hoon`, `dbug.hoon`,
`default-agent.hoon`.

## Where state generation actually happens

Safety state generation runs on the semantic graph through
`node-eval` — **not** through `eval.hoon`, whose CST solver survives only for
simulation and the liveness state-predicate scan. State identity is the
`fingerprint` FP64 **orbit representative**, never rendered text, which is what
makes `SYMMETRY` real rather than cosmetic.

## The liveness stack

1. **`temporal.hoon`** consumes semantic nodes and a `SPECIFICATION`'s fairness
   conjuncts and produces the `oos` — the `OrderOfSolution` /
   `PossibleErrorModel` decomposition (tableau formula, promises, shared
   check-state/check-action bins with per-PEM index arrays). Constant-level
   leaves are folded to `LNBool` through `node-eval`, so a non-boolean liveness
   leaf is a typed rejection rather than a silent pass. The `live-expr` tree is
   a recursive-mold hazard, handled as a named `$+` union of constant-head
   records with every recursion hand-rolled.
2. **`tableau.hoon`** builds the particle tableau. `particleClosure` is an
   alpha/beta expansion under local consistency run to a **fixpoint** — the
   forward alpha sweep walks the *growing* term list, so a `[]` introduced by
   expanding a `/\` is itself expanded and its level ≤ 1 body enters the
   particle's state predicates.
3. **`liveness.hoon`** `+build-product` pairs each reachable state with the
   tableau nodes consistent with it (`isConsistent`, via `node-eval` — a
   non-temporal `LET` leaf keeps its bindings so `x = y` resolves);
   `+pem-accepting`, `+labeled-product`, `+tarjan`, `+live-verdict` give the
   verdict over the SCCs.
4. **The lasso layer** turns a violated `oos` into a trace: `+find-lasso`
   selects the first violated `oos`; `+stutter-lasso` takes the shortest prefix
   to an accepting stutter node, `+bts-lasso` the shortest real-edge cycle back
   to a prefix state. The trace contract is `check.hoon` `+live-lasso-lines`,
   which renders the whole `LivenessDump` `out.txt`.

Stutter-node selection matches TLC's DFS: the trace is over distinct **states**,
so a same-fingerprint stutter step collapses, and among accepting stutter SCCs
the port reports either the deepest or the shallowest **keyed on
`+box-free-tf`** — a surviving obligation makes the witness a genuine lasso
whose cycle does the work (TLC reports the deepest, the one its DFS finishes
first), while an obligation a finite prefix discharges makes the witness pure
reachability (TLC ends at the first discharging state, the shortest prefix).

In production the `%liveness` stage runs this engine with the product build
sliced through a bounded resumable `+pcursor` and the SCC search an
explicit-stack `+scursor` — no recursion-depth bail. Pause/resume at every
product-step boundary is byte-identical.

## Purity is load-bearing

`+step:job` is a **pure function of the job noun**. Two consequences the tests
assert directly:

- pausing and resuming a job cannot change its output
  (`test-pause-resume-identical`);
- a job persisted across a ship restart resumes to the identical result.

This is also why **no library reads Clay** — the scaffold gate checks that
`desk/lib` and `desk/sur` contain no scry. A stage that read Clay would be a
function of the event it ran in, not of the job noun.
