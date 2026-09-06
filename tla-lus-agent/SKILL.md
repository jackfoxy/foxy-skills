---
name: tla-lus-agent
description: Drive the %tla-lus Gall agent - submit/cancel/delete-result pokes, the request/source-bundle/limits/write-target molds, the job lifecycle and its bounded resumable slices, ordered update events, /job subscriptions, scry paths, artifacts, and the ship-wide quotas. Use for any task that operates the agent from the dojo or from Hoon, reads a job's state, or builds a request noun. Owns the wire contract for the pack.
user-invocable: true
disable-model-invocation: false
---

# Driving `%tla-lus`

The agent is **headless and host-only**: `on-poke`, `on-watch` and `on-arvo`
all assert `=(src.bowl our.bowl)`. There is no HTTP surface. Everything below
runs from the dojo of the ship that hosts the desk, or from Hoon on that ship.

```
|install our %tla-lus     ::  or |merge from wherever the desk lives
|start %tla-lus
```

Jobs live in agent state (`state-0 = [%0 jobs=(map req-id jobstate)]`), so they
survive `|nuke` and reboot, and an in-flight search resumes from its persisted
cursor to a **byte-identical** result.

## The three actions

```hoon
+$  action
  $%  [%submit id=req-id =request]
      [%cancel id=req-id]
      [%delete-result id=req-id]
  ==
```

- **`%submit`** — validates the request, then starts a job under `id`.
  Re-submitting an id whose job is still **active** is `%rejected 'duplicate
  active id'`; re-submitting a **terminal** id is allowed and replaces it. On
  success the agent emits `%ack` and schedules the first slice.
- **`%cancel`** — idempotent. Unknown or terminal id: no-op. Active job: sealed
  with `[%cancelled ~]` and a `%result` update.
- **`%delete-result`** — removes a **terminal** job's stored result and
  artifacts, freeing its quota. Deleting an active job is rejected (`'job still
  active'`).

Both agent marks (`%tla-lus-action`, `%tla-lus-update`) are `%noun` marks, so a
malformed action crashes the mark's `grab`, not the agent.

## Building a request

```hoon
+$  request  [=op src=source-bundle =limits write=(unit write-target) promote=(set diag-code)]
```

Read [references/wire-reference.md](references/wire-reference.md) for every
field with a real value. The four decisions that matter:

1. **`op`** — `%analyze` to parse/level/lint, `%check` to model-check.
   `%translate` is a typed rejection (see `tla-lus-pluscal`).
2. **`src`** — `%inline` passes module text as nouns (fastest to iterate,
   nothing touches Clay); `%clay` names a root **module name** plus
   module-search **roots** in a desk, loaded asynchronously at one pinned
   revision. Store `.tla` files under the `%tla` mark with **lowercased**
   file names — Clay path segments carry no case, and the declared
   module-name check still validates the original case.
3. **`limits`** — `default-limits:job-lib` is `[max-source=1.000.000
   max-modules=64 max-states=100.000 max-depth=1.000 max-time=~m10
   max-artifact=1.000.000 max-set-size=1.000.000]`. Raise `max-states` for a
   real model; hitting any bound is a typed `%limited`, never a crash.
4. **`write`** — `~` (read-only, the default) or `` `[desk pax] ``. It is a
   **target, not a flag**, validated at submit because Clay's `%info` carries
   no ack. A target overlapping the run's own module-search roots is refused in
   either direction. `%report` lands at `<pax>/report/txt`, a `%trace` at
   `<pax>/trace/noun`.

## The job lifecycle

```
%submit ──▶ %ack ──▶ [%stage …] [%progress …] [%diagnostic …]* ──▶ %result (once, terminal)
                └─ or ─▶ %rejected reason
```

Stages are planned up front from the request (`+plan:job`) and drained one per
bounded slice: `%starting`, `%parse`, `%modules`, `%semantic`, `%level`,
`%lint`, `%config`, `%init`, `%explore`, `%checkpoint`, `%liveness`,
`%simulate`, `%dfid`, `%terminal` (and `%translate`, unreachable today).

Each Behn wake on wire `/job/<id>/step` spends at most `default-budget:job-lib`
(256) work units — states registered or generated, simulation transitions, or
modules parsed — publishes that slice's events, and reschedules while work
remains. **The per-slice budget is engine configuration and is deliberately
separate from the request's `limits`**, which are enforced where each resource
grows.

Five terminal results:

| Result | Meaning |
|---|---|
| `[%ok stats=run-stats]` | the run completed and found nothing |
| `[%violated =violation stats=run-stats]` | a counterexample — a *successful* run. Never collapsed into `%failed` |
| `[%limited kind=limit-kind stats=run-stats]` | a bound was hit: `%source %modules %states %depth %time %artifact %noun` |
| `[%failed reason=@t]` | the engine could not answer; `reason` names why |
| `[%cancelled ~]` | `%cancel` sealed it |

## Reading a job

**Scries take a mark on the end of the path** (`%gx` supplies the `%x` head):

```
.^([api=@ud state=@ud] %gx /=tla-lus=/version/noun)
.^((list [req-id stage]) %gx /=tla-lus=/jobs/noun)
.^((unit job) %gx /=tla-lus=/job/counter/noun)
.^(artifact %gx /=tla-lus=/job/counter/artifact/report/noun)
```

An artifact scry returns `[~ ~]` unless the job exists, is **terminal**, and
holds that artifact. `$job` is the public projection: no `id` field (the id is
the map key) and **never** the internal cursors.

**Subscriptions** on `/job/<id>` (mark `%tla-lus-update`) replay a snapshot of
the job so far, then stream live ordered events; terminal replay is idempotent
and subscribing to an unknown id fails the watch. `/jobs` is a marker
subscription with no snapshot.

Three shipped generators cover the common path — `:tla-lus|submit <id>
%check`, `+tla-lus/status '<id>'`, `:tla-lus|cancel '<id>'`. `submit.hoon` is a
**demo** request (an empty `Demo` module); copy it as a template rather than
using it for real work.

## Ship-wide quotas

A request's `limits` bound one job; `default-quota:job-lib` bounds the ship:
`max-jobs=8` concurrent active jobs, `max-retained=8.000.000` stored artifact
bytes, `max-inflight=4.000.000` source bytes held by active jobs. Every figure
is **derived from the jobs map**, not carried as a counter, so deleting a job
frees its quota by construction. Over the retention bound the oldest terminal
jobs give up their artifact **bodies** — never their results — and record a
warning saying so, which is why a later artifact scry can miss with the job
still present.

A persisted continuation over `max-noun-bytes` (16.000.000) ends the run
`[%limited %noun …]`.

## Recipes

[references/recipes.md](references/recipes.md) has copy-paste dojo sequences
for: an inline safety check, an invariant violation and its trace, a liveness
property, simulation, a Clay-sourced run, write-back, streaming events,
recovering from `%limited`, and cleaning up.

For what to put in the `.cfg` see `tla-lus-model-checking`; for interpreting a
rejection or a diagnostic see `tla-lus-debugging`.
