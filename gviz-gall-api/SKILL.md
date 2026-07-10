---
name: gviz-gall-api
description: API reference for the %graph-viz Gall agent — the stateless subscribe-then-poke protocol, %gviz-command/%gviz-result marks, $command/$render-opts/$result/$err/$diag types, the run:lib gate, and the positioned-graph noun.
user-invocable: true
disable-model-invocation: false
validated: safe
---

# gviz-gall-api

`%graph-viz` renders DOT (see [[gviz-dot-syntax]]) to SVG in pure Hoon.
This skill is the integration reference: how to talk to the agent, what
the types mean, and how to read the response. For recipes and worked
diagrams see [[gviz-patterns]].

Source of truth: `desk/sur/gviz.hoon`, `desk/sur/graph.hoon`,
`desk/lib/gviz.hoon`, `desk/app/graph-viz.hoon`.

## The pipeline

Every render walks the same seven stages, each a `lib/`:

```
parse → resolve → rank → order → coord → route → svg
 parse   attr     rank   order   coord   route   svg
```

`run:lib` (in `lib/gviz.hoon`) composes them and maps every failure to
a structured `$err`. Layout (`rank`→`route`) runs under `+mule`, so an
internal crash becomes an `[%error %layout ...]` **result**, never an
agent crash.

## Subscription protocol

The agent is **stateless** — no state survives the event. Gall pokes
only ack/nack, so the result rides a one-shot subscription:

1. **Subscribe** to `/result/[uid]`, where `uid` is a `@uv` **the
   caller chooses** (e.g. from `eny`).
2. **Poke** `%graph-viz` with mark `%gviz-command` carrying the **same
   `uid`**.
3. The agent computes, emits **one `%fact`** with mark `%gviz-result`
   on `/result/[uid]`, then **`%kick`s** the path. Do not resubscribe
   on the kick.

The whole thing is **atomic**: one poke → one fact → one kick, in a
single event. Nothing is retained between requests, so requests are
independent and order-free.

> **The only nack**: poking `%gviz-command` with **no subscriber** on
> `/result/[uid]` is nacked with a `tang` explaining the protocol
> (`app/graph-viz.hoon` checks `sup.bowl` for the path first). Always
> subscribe before you poke.

### From an agent (both cards in one turn)

```hoon
=/  uid  `@uv`eny.bowl
:~  :*  %pass  /gviz/results  %agent  [our.bowl %graph-viz]
        %watch  /result/(scot %uv uid)
    ==
    :*  %pass  /gviz/poke  %agent  [our.bowl %graph-viz]
        %poke  %gviz-command
        !>  ^-  command:gviz
        [%render uid [%dot %svg ~ ~ %.n %.n %.n %.n] 'digraph {a -> b}']
    ==
==
```

The result lands in `+on-agent` as a `%fact` (mark `%gviz-result`),
followed by a `%kick`:

```hoon
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+    -.sign  `this
      %fact
    ?.  =(%gviz-result p.cage.sign)  `this
    =/  res  !<(result:gviz q.cage.sign)
    ::  ... handle res ...
    `this
      %kick  `this          :: expected; do NOT resubscribe
  ==
```

### From the dojo

Bundled generator (subscribes for you):
```
+dot-svg 'digraph {a -> b}'
```

Library gate directly (no agent, no protocol):
```
=gviz -build-file /=graph-viz=/lib/gviz/hoon
(run:gviz [%version 0v0])
```

Poking the live agent from dojo has no subscription, so it demonstrates
the nack:
```
:graph-viz &gviz-command [%version 0v0]
```

## Marks

| mark | direction | payload | `grad` |
|---|---|---|---|
| `%gviz-command` | poke → agent | `command:gviz` | `%noun` |
| `%gviz-result` | fact ← agent | `result:gviz` | `%noun` |

Both are plain noun marks (`mar/gviz/command.hoon`,
`mar/gviz/result.hoon`); build the vase with `!>` and read with `!<`.

## Commands (`$command`)

```hoon
+$  command
  $%  [%render uid=@uv opts=render-opts src=@t]
      [%version uid=@uv]      :: -V analogue
      [%plugins uid=@uv]      :: -P analogue
  ==
```

- **`%render`** — parse, lay out, and render DOT `src` under `opts`.
- **`%version`** — implementation version → `[%version [maj min pat]]`
  (currently `[0 1 0]`).
- **`%plugins`** — supported/stubbed engines and formats → `[%plugins
  engines formats]`, each a `(list [_ ?])` (the `-P` analogue).

## Render options (`$render-opts`)

Fields **in tuple order** — the bunt `[%dot %svg ~ ~ %.n %.n %.n %.n]`
is the plain "just render it" configuration:

| field | type | CLI | meaning |
|---|---|---|---|
| `engine` | `$engine` | cmd / `-K` | only `%dot` lays out; else `%unsupported-engine` |
| `format` | `$format` | `-T` | full enum recognized; only `%svg` accepted |
| `defaults` | `(list gattr)` | `-G`/`-N`/`-E` | root-scope attr defaults, in order; file overrides them |
| `scale` | `(unit @rd)` | `-s` | input points-per-inch; `` `.~36 `` halves the drawing; `~` = default 72 |
| `flip-y` | `?` | `-y` | invert the y axis (double-flips SVG's built-in flip) |
| `quiet` | `?` | `-q` | drop `warnings` from the result |
| `verbose` | `?` | `-v` | fill `diag` with per-phase counts |
| `want-graph` | `?` | — | also return the positioned-graph noun |

`$gattr` is one CLI default: `[targ=?(%graph %node %edge) name=@t
value=@t]`. The `-A` flag has no direct field — expand it to all three
targets before poking.

### Engine / format enums

`$engine`: `%dot %neato %fdp %sfdp %twopi %circo %patchwork %osage`
(only `%dot` implemented).

`$format`: the full graphviz `-T` set (`%svg %png %pdf %ps %json
%dot-out %plain %xdot %canon` … ~30 values) is **recognized**; only
`%svg` is **accepted**. Everything else → `%unsupported-format`. Query
the live matrix with `%plugins`.

## Results (`$result`)

```hoon
+$  result
  $%  [%svg warnings=(list @t) diag=(unit diag) svg=@t graph=(unit graph:gg)]
      [%graph warnings=(list @t) graph=graph:gg]
      [%error =err]
      [%version ver=[maj=@ud min=@ud pat=@ud]]
      [%plugins engines=(list [engine ?]) formats=(list [format ?])]
  ==
```

- **`%svg`** — the success case for `%render`. `svg` is the `<?xml …>`
  document text. `warnings` is empty when `quiet`. `diag` is `~`
  unless `verbose`. `graph` is `~` unless `want-graph`.
- **`%graph`** — positioned graph without SVG (reserved; `%render`
  returns `%svg` with an optional embedded `graph`).
- **`%error`** — a structured failure (below).
- **`%version` / `%plugins`** — the two query responses.

## Errors (`$err`)

Errors are **results, not nacks** — the poke acks and the fact carries
the failure:

```hoon
+$  err
  $%  [%parse line=@ud col=@ud msg=@t]
      [%unsupported-engine =engine]
      [%unsupported-format =format]
      [%unsupported-feature msg=@t]
      [%layout msg=@t]
  ==
```

| error | when |
|---|---|
| `%parse` | DOT syntax error; **1-indexed** `line`/`col` |
| `%unsupported-engine` | any engine but `%dot` |
| `%unsupported-format` | any format but `%svg` |
| `%unsupported-feature` | HTML labels (carries source position), `record`/`Mrecord`/HTML shapes |
| `%layout` | internal layout crash, trapped by `+mule` — never crashes the agent |

Example: `+dot-svg 'digraph { a -- b }'` →
`[%error [%parse line=1 col=14 msg='syntax error']]` (undirected edge
in a digraph). HTML label →
`[%error %unsupported-feature 'HTML labels not supported: line L, column C']`.

## Diagnostics (`$diag`, from `verbose`)

```hoon
+$  diag
  $:  nodes=@ud       :: distinct resolved nodes
      edges=@ud       :: expanded edges (cross products counted)
      clusters=@ud    :: cluster subgraphs
      nrank=@ud       :: number of ranks
      virtuals=@ud    :: virtual routing nodes (nall − nreal)
      crossings=@ud   :: edge crossings after mincross
  ==
```

Set `verbose=%.y` to populate it; otherwise `diag=~`. `virtuals` and
`crossings` reveal layout complexity — high values explain slow or
tangled output. See [[gviz-patterns]] for reading them while tuning.

## Decoding the SVG

`svg.result` is a `@t` holding a complete standalone SVG document,
structured like graphviz's `-Tsvg`: `<g class="node">` / `<g
class="edge">` groups each with a `<title>` child naming the node/edge.
Downstream CSS/JS tooling that keys on those classes keeps working.
Serve it, embed it, or store it in clay (`mar/svg`) as-is.

## The positioned-graph noun (`$graph:graph`)

With `want-graph=%.y`, `graph.result` is a `(unit graph:gg)` — the
pipeline's public geometry, enough to drive any renderer:

```hoon
+$  graph
  $:  name=@t
      canvas=[size=fpair scale=@rs]
      directed=?
      nodes=(list gnode)     :: creation order = the node index space
      edges=(list gedge)     :: tail/head index into nodes
      clusters=(list gcluster)
  ==
```

Conventions (`sur/graph.hoon`, `doc/graph-noun.md`):

- Coordinates are `@rs` **points** (1/72 in), **y-up**, origin at the
  drawing's lower-left. SVG flips y at codegen; if you render the noun
  yourself, flip (or pass `flip-y`).
- `canvas.scale` is a factor ≤ 1 from `size=`/`-s`; coordinates are
  unscaled — apply the factor as a final transform.
- `gedge.spline` length is `3k+1`: point 0 is the start, then each
  triple is `[ctrl1 ctrl2 endpoint]` — exactly SVG `M … C …`.
- `gnode.half` are half-extents: the box is `center ± half`.
- `attrs` maps are complete resolutions (inherited + explicit,
  latest-wins, unknowns preserved).

## Request/response lifecycle

```
caller                         %graph-viz
  |  %watch /result/[uid]  ---->  on-watch: ok
  |  %poke %gviz-command   ---->  on-poke: run:lib → one %fact + %kick
  |  <---- %fact %gviz-result (on /result/[uid])
  |  <---- %kick
```

Timing: synchronous within one Arvo event — the fact is emitted in the
same event as the poke. Atomicity: exactly one fact per command; no
partial results, no retained state.

## Error-recovery patterns

- **Always subscribe before poking** — a missing subscriber is the
  only nack. If a poke nacks, you skipped step 1.
- Treat `%error` as normal control flow: branch on `-.err` and
  surface `line`/`col`/`msg` to the user; the DOT source is at fault,
  not the agent.
- Probe capabilities with `%plugins` / `%version` before sending a
  `%render` that might use an unsupported engine or format.
- Turn on `verbose` when output looks wrong: `crossings`/`virtuals`
  distinguish "layout is hard" from "input is malformed".

For worked integration recipes (rendering from Hoon, storing in clay,
caching), see [[gviz-patterns]].
