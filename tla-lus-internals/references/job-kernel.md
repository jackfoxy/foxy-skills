# The Job Kernel and the Gall Shell

## `desk/lib/job.hoon`

The resumable stage engine: `+validate` → `+plan` → `+init` → `+step`* →
terminal. Everything the agent does with a request goes through it.

- **`+validate`** — every typed-boundary check, run **before a job exists**.
  Anything the pipeline cannot do faithfully is rejected here **by name**,
  never accepted into a stage that would fake success. Write targets are
  validated here too, because Clay's `%info` is fire-and-forget: it carries no
  ack gift, so a bad target could not be reported through the job's result.
- **`+plan`** — the ordered stage list. Every planned stage does real work. A
  `%clay` bundle prepends `%modules`; whether a `%liveness` stage is needed is
  unknown until the config is read, so `%config` **appends** it when the loaded
  config names a `PROPERTY`.
- **`+step`** — one bounded slice. Spends at most `default-budget` (256) work
  units — states registered or generated, simulation transitions, or modules
  parsed — then returns `%more` with a persisted continuation, or a result.
- **`+project`** — the public `$job`: no `id` (it is the map key), and **never**
  the internal cursors.

The continuation is **jammed** because its recursive syntax/value molds must
not enter the `on-save` vase type. It holds the search queue, the visited set,
the scan worklist, the RNG sample, or the source-load cursor.

## Limits, budgets, and quotas — three different things

| | Scope | Set by | Effect |
|---|---|---|---|
| `limits` | one job | the caller, per request | typed `%limited` naming the resource |
| `default-budget` (256), `default-load-budget` (8) | one Gall event | engine config | slice size; invisible to the caller |
| `gquota` (`max-jobs=8`, `max-retained=8MB`, `max-inflight=4MB`) | the ship | engine config | submit-time rejection naming the resource |

Plus `max-noun-bytes` (16MB) on the persisted continuation — defense in depth
above what `max-states` already implies, checked at each slice boundary.

Every quota figure is **derived from the jobs map**, never carried as a
counter, so the accounting cannot drift and deleting a job frees its quota by
construction. Over the retention bound, `+reclaim` takes the **oldest terminal
jobs' artifact bodies** — never their results — and records a `[%lus 403]`
warning on the job, so a later artifact scry that misses is explained rather
than blank.

## Asynchronous source load (`%clay` bundles)

Purity forces this shape. No library reads Clay; the kernel **names** the files
it needs and the agent brings the bytes back:

```
   %modules ──▶ %await [read-request …]        the kernel names files
       ▲                    │
       │                    ▼
       │            app/tla-lus: %warp ─▶ Clay
       │                    │
       └──── +deliver ◀── %writ                the agent brings bytes back
                  │
                  ▼
   graph closed ──▶ %src ──▶ %parse ──▶ %config ──▶ %explore
```

The `%load` cursor holds the BFS queue of referenced names, the reads in flight
(by tag), the delivered-but-unabsorbed inbox, and the byte/module accounting.
It jams and revives like any other continuation, so a run paused waiting on
Clay resumes byte-identically.

Three invariants:

- **Escape-free by construction.** A `source-ref` exists only if
  `desk/lib/source-path.hoon` built it, which requires canonical segments, a
  path under a declared search root, and a revision already pinned to a number.
- **One revision per run.** The agent resolves the requested case **at submit**,
  so a commit mid-run cannot split the source set.
- **Bounded everywhere.** Source bytes and module count accrue as reads arrive;
  the load cursor shares the search cursor's noun bound; reads per slice have
  their own budget.

Delivery is robust by design: anything that is not a live answer to a read this
job is actually holding — an unknown or deleted job, a sealed one, a response
from an earlier job that held this id, a duplicate, or one for a superseded
load — is **dropped without a step**, so a repeated or reordered delivery
changes neither state nor events.

## `desk/app/tla-lus.hoon`

Deliberately small. Five jobs:

1. **Authorize** — `on-poke`/`on-watch`/`on-arvo` all assert
   `=(src.bowl our.bowl)`.
2. **Validate and start** — `%submit` runs `validate:job` then `init:job`,
   storing the job under its `req-id`.
3. **Schedule** — a Behn timer on wire `/job/<id>/step`; each `%behn %wake`
   runs one `step:job`, fans its events out as `%tla-lus-update` facts, and
   reschedules while the step returns `%more`. Wakes for deleted or already
   terminal jobs are no-ops.
4. **Publish** — `/job/<id>` subscribers get a **replayed snapshot** then live
   ordered events; `%result` is terminal and fires once.
5. **Persist** — `state-0 = [%0 jobs=(map req-id jobstate)]`. `on-load`
   **coerces** the stored noun (`;;`) inside `mule` rather than requiring it to
   nest, so a mold change cannot discard completed results.

`on-peek` exposes only the public projection: `/x/version`, `/x/jobs`,
`/x/job/<id>`, `/x/job/<id>/artifact/<name>` (terminal jobs only).

## Persistence and versioning

`versioned-state = $%(state-0)` — one arm, because nothing has been released. A
future version adds its `state-N` **alongside** a frozen copy of this one and
converts in `on-load`'s `?-`; upgrades are explicit migrations, never in-place
reshaping.

`api-version` is 1 and the state version is `%0`. **Pre-release reshapes are
not versions** (`compatibility.md` §10.6): no ship held that state and no caller
saw that wire, so there is no migration anywhere in this project. Both move at
release.

A job's noun contains everything needed to resume byte-identically: the
request, the current stage, the remaining `pending` stages, accumulated
stats/diags/artifacts, the submit time (for `max-time`), the jammed in-stage
continuation, and — once set — the terminal result. Recovery is therefore
"reload state, keep stepping".

## Trust boundaries

- **Input** arrives only as pokes from the host ship; nouns are clammed at the
  mark boundary, so a malformed action crashes the `grab`, not the agent.
- **Clay** is read-only unless the request carries a `write-target`, which is
  validated at submit and refused if it overlaps the run's own search roots.
- **Resources** are bounded per request, per slice, and per ship.
- **Output** the agent owns: jobs and artifacts leave only by `%delete-result`,
  `%cancel`, or retention reclaim.
