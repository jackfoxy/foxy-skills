# Dojo Recipes

Environment-neutral: every line runs on the ship hosting the desk. The
`%tla-lus-action` mark's `grab` is `noun`, so a **plain noun literal
typechecks** — you do not need the `sur` faces in scope. Where a recipe wants
`default-limits:job-lib`, either build the library into the dojo subject or
paste the literal:

```
=jl -build-file /=tla-lus=/lib/job/hoon        ::  then use default-limits:jl
::  or, equivalently, the literal:
::  [1.000.000 64 100.000 1.000 ~m10 1.000.000 1.000.000]
```

A `request` has **five** fields — `[op src limits write promote]`. Omitting
`promote` is the most common hand-written mistake.

## 1. Inline safety check

```
=spec '''
---- MODULE Counter ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = (x + 1) % 4
Inv  == x < 4
====
'''
=cfg 'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a'
=req :*  op=[%check [| | | | ~ | ~ [%exhaustive & 0]]]
         src=[%inline 'Counter' (malt ~[['Counter' spec]]) `cfg]
         limits=[1.000.000 64 100.000 1.000 ~m10 1.000.000 1.000.000]
         write=~
         promote=~
     ==
:tla-lus &tla-lus-action [%submit ~.counter req]
.^((unit job) %gx /=tla-lus=/job/counter/noun)
.^(artifact %gx /=tla-lus=/job/counter/artifact/report/noun)
```

`check-opts` positionally is `[translate view difftrace continue cfg coverage
postconditions mode]`. Expect `[%ok [5 4 0 4 [0 1 1 1]]]`.

## 2. Watch a violation and read its trace

Change the invariant to something false (`Inv == x < 3`) and resubmit under a
fresh id. The result becomes

```
[%violated [%invariant 'Inv' |] [4 4 0 3 …]]
```

`initial=|` says a **behaviour** violated it, so the `%trace` artifact is a
counterexample. `initial=&` would mean the *initial-state* computation found
it, with no behaviour and no state-graph statistics.

```
.^(artifact %gx /=tla-lus=/job/counter-bad/artifact/trace/noun)
```

The `%report` artifact renders the same thing as TLC's console output —
`State N: <label>` blocks with `var = value` bindings.

## 3. Liveness

Add a `PROPERTY` to the config. `%config` appends a `%liveness` stage when the
loaded config names one.

```
=cfg 'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
```

Without a fairness constraint, TLC — and this port — report a **stuttering
lasso**, so expect `%violated [%property 'Live' |]` unless the spec constrains
stuttering. Add `SPECIFICATION Spec` with `Spec == Init /\ [][Next]_vars /\
WF_vars(Next)` to check what you meant. A lasso trace has
`kind=%lasso` and a `loop-start`; the report ends with a `Stuttering` or
back-to-state marker.

## 4. Simulation

```
=req :*  op=[%check [| | | | ~ | ~ [%simulate 987.654.321 100 20 |]]]
         src=[%inline 'Counter' (malt ~[['Counter' spec]]) `cfg]
         limits=[1.000.000 64 100.000 1.000 ~m10 1.000.000 1.000.000]
         write=~  promote=~
     ==
```

`[%simulate seed num depth generate]`. The same seed and limits always produce
the same result. Use **wide** seeds — measured, seeds 1, 2, 3, 7, 8 and 42 all
produce the same first draw. `generate=&` switches to probabilistic successor
picking (tlc2's `-generate`), which only changes anything below the
action-decomposition boundary.

In simulation, `generated` counts **transitions taken** and `depth` is the
deepest transition index; `distinct` and `queued` stay 0.

## 5. Clay-sourced run

Store modules under the `%tla` mark with lowercased file names
(`/counter/tla`), and the config under a text mark (`/spec-cfg/txt`).

```
=req :*  op=[%check [| | | | ~ | ~ [%exhaustive & 0]]]
         src=[%clay our %myspecs da+now 'Counter' `/spec-cfg/txt ~[/]]
         limits=[1.000.000 64 100.000 1.000 ~m10 1.000.000 1.000.000]
         write=~  promote=~
     ==
```

- `root` is the module **name**; `roots` are module-search **paths**, and at
  least one is required.
- The revision is resolved **once, at submit**, so a commit mid-run cannot
  split the source set.
- `check-opts.cfg` (the source-name override) is refused on a `%clay` bundle —
  select the config with `src.cfg` instead.
- A Clay run reaches the same verdict, report and counterexample as an inline
  bundle of the same files.

## 6. Persist artifacts to Clay

```
=req :*  op=[%check [| | | | ~ | ~ [%exhaustive & 0]]]
         src=[%inline 'Counter' (malt ~[['Counter' spec]]) `cfg]
         limits=[1.000.000 64 100.000 1.000 ~m10 1.000.000 1.000.000]
         write=`[%base /tlaout]
         promote=~
     ==
```

`%report` lands at `/tlaout/report/txt`, a `%trace` at `/tlaout/trace/noun`.
The target is validated **at submit** (Clay's `%info` carries no ack), and a
target overlapping the run's own search roots is refused in either direction.

## 7. Stream events instead of polling

Subscribe to `/job/<id>` with mark `%tla-lus-update` from your own agent or a
thread. You get a **replayed snapshot** of the job so far — so a late
subscriber catches up — then live ordered events, ending in exactly one
`%result`. Terminal replay is idempotent; subscribing to an unknown id fails
the watch.

## 8. Recovering from `%limited`

```
[%limited %states [100.000 100.000 12.431 17 [0 3 5 9]]]
```

`kind` names the resource: `%source %modules %states %depth %time %artifact
%noun`. Options, in order of preference:

1. Shrink the model — smaller `CONSTANT` sets are almost always the answer.
2. Add a `CONSTRAINT` to bound the state space (and say so when reporting the
   result: a constrained run proves less).
3. Raise the one bound that was hit. `max-time` is per **slice**, not per run.
4. `%noun` means the persisted continuation exceeded 16MB — that is a shape
   problem, not a size dial.

## 9. Cancel and clean up

```
:tla-lus &tla-lus-action [%cancel ~.counter]
:tla-lus &tla-lus-action [%delete-result ~.counter]
.^((list [req-id stage]) %gx /=tla-lus=/jobs/noun)
```

`%cancel` is idempotent; `%delete-result` refuses an active job (`'job still
active'`) and frees the job's quota when it succeeds. If a scry for an artifact
misses on a job that still exists, retention reclaimed its **body** — the
job's own diagnostics record it.

## 10. Shipped generators

```
:tla-lus|submit ~.job-1 %check       ::  a DEMO request (empty module) — copy as a template
+tla-lus/status ~.job-1
:tla-lus|cancel ~.job-1
```

The id argument is a `@ta`, not a cord — `~.job-1`, not `'job-1'`.

`gen/tla-lus/status.hoon` is also the reference for the scry path shape,
including the trailing `/noun` mark.
