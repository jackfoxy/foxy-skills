# The `.cfg` File

`desk/lib/config.hoon` is the port of `ModelConfig` + `SpecProcessor`. It is at
parity: 34 differential cases for the parse (`tools/gen-cfg-tests.py`, oracle
`ConfigDump.java`) and 39 for config-vs-graph validation
(`tools/gen-cfg-val-tests.py`).

**`ModelConfig.parse` throws on the FIRST malformed construct**, so a bad
config yields at most **one** `CFG_*` diagnostic (family 5001–5006). Fix them
one at a time.

An `%inline` bundle passes the config as `cfg=(unit @t)` — raw text, newlines
as `\0a`. A `%clay` bundle selects it by path (`src.cfg`), because the file's
Clay mark is part of the reference.

## Keywords

| Keyword | Takes | Notes |
|---|---|---|
| `SPECIFICATION` | one operator name | the behaviour spec, level 3. Mutually exclusive with `INIT`/`NEXT` |
| `INIT` / `NEXT` | one operator name each | the explicit pair. `%check` needs either this pair or `SPECIFICATION` |
| `INVARIANT` / `INVARIANTS` | names | level ≤ 1. Checked at every state, **in declaration order** |
| `PROPERTY` / `PROPERTIES` | names | may be level 3; triggers the `%liveness` stage |
| `CONSTANT` / `CONSTANTS` | assignments | see below |
| `CONSTRAINT` / `CONSTRAINTS` | names | level 1 state constraint — prunes the search |
| `ACTION_CONSTRAINT` / `ACTION_CONSTRAINTS` | names | level 2 — prunes transitions |
| `SYMMETRY` | one name | a symmetry-group operator over model values |
| `VIEW` | one name | the projection used for state identity |
| `ALIAS` | one name | the record rendered instead of raw bindings in a trace |
| `POSTCONDITION` | names | evaluated after exploration |
| `CHECK_DEADLOCK` | `TRUE`/`FALSE` | the config-side spelling of `deadlock` |
| `_PERIODIC`, `_RL_REWARD` | — | **parsed and refused by name** at `%config` |

An unrecognised keyword is `CFG_GENERAL` (5.006), *"Expected a keyword"*.

## `CONSTANT` assignments

Three forms, all supported:

```
CONSTANT N = 3                    \* a value
CONSTANT Data = {d1, d2}          \* a set of MODEL VALUES (bare identifiers)
CONSTANT Op(a, b) <- ImplOp       \* an operator OVERRIDE (definition replacement)
CONSTANT Foo <- [Other]Bar        \* an override naming the module it comes from
```

Values may be numbers, strings (quotes stripped), `TRUE`/`FALSE`, bare
identifiers (which become **model values**), and sets of those.

Two rules worth memorizing:

- **`CONSTANT Inv = 42` REPLACES the operator `Inv`** in the definition table.
  It is not restricted to declared constants — this is how overrides work.
- A declared `CONSTANT` that only an override will fill **resolves to null**
  until the override loop runs. That is the pin's behaviour, reproduced.

Model values are unequal to everything but themselves. **They order
lexicographically here**, where tlc2 orders by intern position — a documented
approved difference (`tla-lus-parity`).

## `INIT`/`NEXT` versus `SPECIFICATION`

Use `INIT`/`NEXT` when you can. `SPECIFICATION` is required when the spec
carries fairness conjuncts, but it costs you:

- `-coverage` is **refused** under a `SPECIFICATION` — the INIT action has no
  declaration to label.
- The port's own `%report` labels come from the declarations, so `INIT`/`NEXT`
  gives more legible action names.

## Worked configs

Safety only:

```
INIT Init
NEXT Next
INVARIANT TypeOK
INVARIANT Safe
```

Invariants are checked in declaration order, so put `TypeOK` first — the first
one to fail is the one reported.

Liveness with fairness:

```
SPECIFICATION Spec
INVARIANT TypeOK
PROPERTY Liveness
```

with `Spec == Init /\ [][Next]_vars /\ WF_vars(Next)` in the module. **Without
a fairness conjunct you will get a stuttering lasso**, i.e. `%violated
[%property …]`, which is a correct answer to the question you asked and
probably not the question you meant.

Bounding an infinite model:

```
INIT Init
NEXT Next
CONSTRAINT SmallEnough
INVARIANT Safe
```

`SmallEnough == x < 10`. Say so when reporting: a constrained run explores a
sub-graph, so `%ok` means "no violation within the constraint".

Symmetry:

```
CONSTANT Procs = {p1, p2, p3}
SYMMETRY Perms
```

with `Perms == Permutations(Procs)` from `TLC`. Symmetry is **unsound with
liveness** in general; the port refuses the combinations it cannot do
faithfully and documents the rest.

## Config-vs-graph validation

After parsing, the config is validated against the semantic graph
(`SpecProcessor`): every named operator must exist, have the right arity, and
sit at a legal level. Failures are `TLC_CONFIG_*` diagnostics (2222–2281) with
the pin's exact text — e.g. an `INVARIANT` naming a level-2 expression, a
`CONSTANT` assigned to something that is not declared, or an operator named in
`PROPERTY` that does not exist.

`ASSUME`s are checked **before any state exists**; a failed one is
`[%violated [%assumption <name>]]`, which takes no `initial` flag.
