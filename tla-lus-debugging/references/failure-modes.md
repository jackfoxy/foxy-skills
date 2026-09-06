# Failure Modes

## First question: which of the five results is it?

| Symptom | It is |
|---|---|
| `%rejected` on the poke | submit-time validation; **no job exists** |
| `[%failed reason]` | the engine could not answer — read `reason`, it names why |
| `[%violated …]` | a **successful** run that found a counterexample |
| `[%limited kind …]` | a bound was hit; the numbers are a lower bound |
| `[%cancelled ~]` | someone poked `%cancel` |

A `%rejected` never becomes a job, so there is nothing to scry. The reason
string is the whole diagnosis.

## Submit-time rejections

Everything in `tla-lus-overview`'s support matrix under "Refused at submit".
The four that are not obviously about capability:

- **`duplicate active id`** — the `req-id` has a running job. Cancel it or pick
  a new id. A **terminal** id may be resubmitted freely.
- **`a %check request requires a config`** — an `%inline` bundle needs
  `cfg=`` `text ``; a `%clay` bundle needs `src.cfg`.
- **`unknown cfg source: <name>`** — `check-opts.cfg` names a source the bundle
  does not carry. Refused here so nothing downstream can silently fall back to
  the bundle's own cfg and check a *different* config than you asked for.
- **`global limit: …`** — a ship-wide quota, not your request's `limits`.
  `too many active jobs` (8), `retained artifact bytes; delete a result first`
  (8MB), `in-flight source bytes` (4MB). `%delete-result` on finished jobs is
  the fix.

## Parse failures

A parse error is **fatal and unsuppressible** — every later stage consumes the
tree. A *successful* parse emits no diagnostics at all, so "no output" from
`%analyze` with `syntax` only is success.

The parser reports where **no valid continuation exists**, which can be well
past the actual mistake. Work backwards:

1. Read the `Was expecting "…"` line — it names what the grammar wanted.
2. Read the residual stack trace — the top frames name the productions it was
   inside, with their entry positions. The real error is usually at the entry
   position of the innermost frame.
3. Check the usual suspects in order: an unclosed `(* *)`; a `----`/`====` run
   shorter than four; **tabs** (they advance columns to multiples of eight);
   junction-list misalignment; a mixed-precedence expression that needs
   parentheses; `==` where `=` was meant (there is a dedicated hint for that).

`Item at <loc> is not properly indented` is always alignment. `Couldn't
properly parse expression` followed by ` Couldn't reduce expression stack.` is
`finalReduce` — usually an operator with no operand or a precedence conflict.

**One approved divergence**: on *already-rejected* module-body input, SANY
unwinds to the module-body choice and reports `Was expecting "==== or more
Module body"` at an arbitrary recovery point; this port reports where the
failure actually occurred. Same verdict, better position.

## Semantic and level failures

- **`ASSUME` asserting a variable's type** — `ASSUME` is constant-level. This
  is the single most common level error.
- **An `INVARIANT` that is level 2** — it has a prime or an `ENABLED` in it.
  Move it to `PROPERTY` as `[][A]_v`, or drop the prime.
- **`f[e]'` not meaning what you think** — priming distributes over the whole
  expression: it is `f'[e']`.
- **Arity** — applying a 2-ary operator to one argument is an error, not
  partial application.
- **An operator where a value is expected** — use `LAMBDA` or declare a
  higher-order parameter `Op(_, _)`.

## Config failures

At most **one** `CFG_*` diagnostic per file (the Java parser throws on the
first malformed construct). After parsing, `TLC_CONFIG_*` (2222–2281) reports
config-vs-graph mismatches: a name that does not exist, a wrong arity, an
illegal level, a `CONSTANT` assignment to something undeclared.

`%failed 'no INIT in config'` and friends mean the config parsed but does not
describe a runnable spec: you need either `INIT`+`NEXT` or `SPECIFICATION`.

## Evaluation failures at `%explore`

The engine must **enumerate**. TLA+ legality is broader than evaluability:

- unbounded quantification (`\A n \in Nat : …`) parses, level-checks, and then
  fails;
- `CHOOSE` over an infinite set fails;
- a function applied outside its domain fails;
- a decimal literal is rejected at **spec load**, even if unused (EC 2244) —
  this matches the pin, which fails in `processConstantDefns`.

Each arrives as a `%tlc` diagnostic with the pin's own text and a source span.

## Reading a counterexample

```hoon
+$  trace  [kind=?(%safety %lasso %simulate) states=(list trace-state) loop-start=(unit @ud)]
```

- `kind=%safety` — a finite path to the offending state. `states` is in order;
  `action` is `~` on the initial state and otherwise names the action taken
  **to reach** that state, with its source span.
- `kind=%lasso` — a liveness counterexample. `loop-start` is the 1-based index
  the cycle returns to. Two shapes: a **stuttering** lasso (the behaviour stops
  making progress) and a **back-to-state** lasso (a genuine cycle). The report
  labels which.
- `binding.val` is **already rendered text**, as TLC prints it. The wire ships
  no structured value.

Method: read the *last* state first — that is where the invariant broke. Then
walk backwards to the first state where a variable holds a value you did not
expect. That transition's `action` name is where to look in the module. If
every value looks legal, the invariant is wrong, not the spec.

A stuttering lasso on a property that should hold almost always means **no
fairness constraint**: without one, the behaviour that does nothing forever is
allowed, and it violates every liveness property. Add `WF_vars(A)` and use
`SPECIFICATION`.

## `%limited`

`kind` names the resource: `%source %modules %states %depth %time %artifact
%noun`.

1. Shrink the model. Smaller `CONSTANT` sets are nearly always the answer.
2. Add a `CONSTRAINT` — and say so when reporting, because a constrained `%ok`
   proves less.
3. Raise the one bound named. `max-time` is per **slice**, not per run.
4. `%noun` (a >16MB persisted continuation) is a shape problem, not a size
   dial: the search state itself got too big.

## When it looks like a port bug

- `[%lus 400] parser crashed in <module>` is always a defect. Report it with
  the module text.
- A divergence from the Java tool may be **approved** — check
  `desk/doc/compatibility.md`'s support matrix and `tla-lus-parity` before
  filing anything. String/model-value ordering, the default seed, `-terse`
  rendering, DFID traces, and coverage's two absent line kinds are all
  deliberate.
- Reproduce the Java side **at the pin** (`tlaplus@4ba7d8811`) with `-fp 0` and
  an explicit `-seed` before claiming a difference. See `tla-lus-dev-workflow`.

## Reading a `-test` verdict from the ship

A trap this port hit four times: `tmux capture-pane -S -N | grep FAILED` spans
**several runs**, and every stale hit looks exactly like a live one. Anchor the
read to the current run — slice the scrollback between the *previous* `ok=%`
line and the last one. The dojo prints its command echo at the **end** of a
run, so anchoring on the echo alone selects the wrong block.
