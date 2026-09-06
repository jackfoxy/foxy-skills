# Wire Reference

Every public mold lives in `desk/sur/tla-lus.hoon`; `desk/doc/api.md` tabulates
all of them with a value taken from green test assertions or a live run, and
`tools/check-portmap.py` fails if a mold reaches the wire without appearing
there. This file is the working subset.

## Identifiers, positions, sources

| Mold | Shape | Example |
|---|---|---|
| `req-id` | `@ta` | `~.counter` — caller-chosen |
| `module-name` | `@t` | `'Counter'` — the TLA+ module name, **not** a file name |
| `source-name` | `@t` | `'Counter'`, or `'inline'` for the config |
| `pos` | `[line=@ud col=@ud]` | `[5 12]` — 1-indexed, SANY semantics |
| `span` | `[from=pos to=pos]` | `[[5 12] [5 18]]` — inclusive |
| `loc` | `[src=source-name =span]` | `['Counter' [[5 12] [5 18]]]` |
| `source-id` | `$%([%inline name] [%clay ship desk case path])` | `[%clay ~zod %tla-lus da+now /counter/tla]` |
| `resolver` | `$-(module-name (unit source-text))` | built by `inline-resolver:modules` from a `(map module-name @t)` |

## Diagnostics

| Mold | Shape | Notes |
|---|---|---|
| `severity` | `?(%error %warning %info)` | only **warnings** are promotable |
| `code-family` | `?(%sany %pcal %tlc %lus)` | `%lus` is engine-specific; everything else is the pin's |
| `diag-code` | `[family=code-family num=@ud]` | `[%tlc 2.103]`, `[%sany 4.802]`, `[%lus 402]` |
| `diagnostic` | `[code severity stage message at related]` | `at` is `(unit loc)` |

## Request

```hoon
+$  request  [=op src=source-bundle =limits write=(unit write-target) promote=(set diag-code)]
+$  op
  $%  [%translate opts=pcal-opts]      ::  typed rejection today
      [%analyze flags=analyze-flags]
      [%check opts=check-opts]
  ==
+$  analyze-flags  [syntax=? semantic=? level=? lint=?]
+$  check-opts
  $:  translate=?  view=?  difftrace=?  continue=?
      cfg=(unit source-name)
      coverage=?
      postconditions=(list [module=@t op=@t])
      mode=check-mode
  ==
+$  check-mode
  $%  [%exhaustive deadlock=? seed=@ud]
      [%simulate seed=@ud num=@ud depth=@ud generate=?]
      [%dfid depth=@ud deadlock=?]
  ==
+$  source-bundle
  $%  [%inline root=module-name modules=(map module-name @t) cfg=(unit @t)]
      [%clay =ship =desk cas=case root=module-name cfg=(unit path) roots=(list path)]
  ==
+$  limits  [max-source=@ud max-modules=@ud max-states=@ud max-depth=@ud max-time=@dr max-artifact=@ud max-set-size=@ud]
+$  write-target  [=desk pax=path]
```

Field notes that save a round trip:

- **`analyze-flags.syntax` must be `&`.** Parsing is mandatory, a parse error
  is fatal and so unsuppressible, and a *successful* parse emits no diagnostics
  at all — so `syntax=|` has no possible behaviour and is refused rather than
  accepted and ignored.
- **`check-mode.seed` is not simulation-only.** `RandomEnumerableValues.setSeed`
  runs for the BFS too, so it is the seed `TLC!RandomElement` draws from while
  the search expands states. The generator is reseeded to `fingerprint ^ seed`
  once per **predecessor state**, not once per evaluation, so two draws in one
  action give two values. Default `0`, which makes runs reproducible;
  comparing against the pin also needs `-fp 0`.
- **`generate` is a field on `%simulate`, not a mode**, because tlc2 spells it
  that way (both flags set `RunMode.SIMULATE`). It only changes anything below
  the action-decomposition boundary: `Next == A \/ B` and `Next == \E n \in
  1..5 : …` are byte-identical either way, because `Tool.getActions` splits the
  disjunction and enumerates the quantifier first.
- **`%dfid.depth` is the deepest LEVEL a sweep may reach.** Below 2 no sweep
  runs, so 0 and 1 explore the initial states and stop. A run that ends **at**
  the bound is `[%limited %depth …]` and never `%ok` — tlc2 prints no
  completion line there.
- **`postconditions`** is tlc2's `-postCondition mod!op`, as a list of pairs.
  They run **in addition to** and **after** any the `.cfg` declares (tlc2
  appends both to one `POST_CONDITIONS` list). A `module` naming somewhere
  other than where the operator is defined is a typed rejection — the port
  resolves definitions by bare name, so honouring it would silently run a
  different operator.
- **`coverage` is a boolean**, not tlc2's interval argument:
  `TLCGlobals.coverageInterval` gates only *periodic* reporting and the
  end-of-run block is byte-identical for `-coverage 0`, `1` and `2`.
- **`promote`** is tlc2's `-messagesAsErrors`. It lives on `request`, not
  `check-opts`, because it applies to `%analyze` and `%check` alike, and it is
  **not** a display concern: promotion is `Assert.fail` at the moment of
  emission, so it aborts the run there and reports the statistics reached so
  far — a caller filtering severities off a finished result cannot reproduce
  that. Only warnings are promotable (tlc2's rule, not a port choice); an
  unrecognised code is simply inert here.
- **`%clay`'s `root` is a module NAME, not a path.** The config is selected by
  `src.cfg` (a path, e.g. `/spec-cfg/txt`), because the file's Clay mark is
  part of the reference and a bare name cannot supply it.

## Updates

```hoon
+$  update
  $%  [%ack id=req-id]
      [%rejected id=req-id reason=@t]
      [%deleted id=req-id]
      [%job id=req-id =event]
  ==
+$  event  $%([%stage =stage] [%progress =progress] [%diagnostic =diagnostic] [%result =result])
+$  progress  [done=@ud total=@ud]     ::  stages, not states
```

Events arrive **in order**; `%result` fires exactly once and is terminal.

## Results and statistics

```hoon
+$  result
  $%  [%ok stats=run-stats]
      [%failed reason=@t]
      [%violated =violation stats=run-stats]
      [%cancelled ~]
      [%limited kind=limit-kind stats=run-stats]
  ==
+$  run-stats  [generated=@ud distinct=@ud queued=@ud depth=@ud outdeg=out-degree]
+$  out-degree  [min=@ud mean=@ud p95=@ud max=@ud]
+$  violation
  $%  [%invariant name=@t initial=?]  [%deadlock ~]
      [%property name=@t initial=?]   [%action name=@t]
      [%liveness name=@t]             [%assumption name=@t]
  ==
```

- **`out-degree` samples one value per *dequeued* state** (its newly-distinct
  successor count), so a sink pulls `min` to 0.
- **`run-stats` means different things per mode.** In `%simulate`, `generated`
  is transitions taken and `depth` the deepest transition index; `distinct` and
  `queued` stay 0, because simulation keeps no frontier. In `%dfid`,
  `generated` and `distinct` are tlc2's own two numbers and `queued`, `depth`
  and `outdeg` stay 0 — DFID's summary carries no queue term, no complete-graph
  depth line and no average out-degree, so the port reports nothing rather than
  a number the oracle never produced. The per-level lines are in `%report`.
- **`violation.initial`** splits what tlc2 reports as two error codes: `&` is a
  violation found while **computing the initial states** (EC 2107 invariant, EC
  2108 property), `|` one found by a behaviour (EC 2110). It is not cosmetic —
  an initial-state violation has no behaviour and tlc2 prints no state-graph
  statistics for it, so without the flag a caller cannot tell whether the
  `trace` it holds is a counterexample or a single offending state.
- **`%action`** is an IMPLIED ACTION violation (a `[][A]_v` PROPERTY whose `A`
  fails on some transition), tlc2's EC 2112 — a broken **step**, distinct from
  EC 2116's broken **behaviour**. Only the DFID engine currently produces it.
- `%deadlock`, `%action`, `%liveness` and `%assumption` take no `initial` flag:
  the first three are properties of a behaviour by construction, and an
  `ASSUME` is checked before any state exists.

## Traces and artifacts

```hoon
+$  binding      [var=@t val=@t]
+$  trace-state  [index=@ud action=(unit [name=@t at=(unit loc)]) bindings=(list binding)]
+$  trace        [kind=?(%safety %lasso %simulate) states=(list trace-state) loop-start=(unit @ud)]
+$  artifact     $%([%text text=@t] [%trace =trace])
```

`binding.val` is **already rendered text**, matching what TLC prints — the wire
does not ship a structured value. `action` is `~` on the initial state.
`loop-start` is set only for `%lasso`.

Artifact names: `%report` (the TLC-style console output), `%trace` (on a
violation), `%violations` (every counterexample in discovery order, under
`continue=&`), `%sources`.

## Scries

| Path (add the `/noun` mark for `.^`) | Returns |
|---|---|
| `/x/version` | `[api=@ud state=@ud]` — `[1 0]` today |
| `/x/jobs` | `(list [req-id stage])` |
| `/x/job/<id>` | `(unit job)` — the public projection |
| `/x/job/<id>/artifact/<name>` | `artifact`, for a **terminal** job only |

`api-version` is 1 and stays there until release: pre-release reshapes are not
versions, because no ship held that state and no caller saw that wire
(`compatibility.md` §10.6). No migration exists anywhere in this project.
