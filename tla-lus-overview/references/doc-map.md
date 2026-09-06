# Documentation Map

`desk/doc/` is authoritative. When a skill and a doc disagree, read the code —
`desk/lib/job.hoon` `+validate` is the last word on what a submit accepts.

| Document | Lines | Owns |
|---|---|---|
| `desk/doc/users-guide.md` | 132 | Task-oriented install, workflows, limits, traces, troubleshooting |
| `desk/doc/api.md` | 279 | Marks, **every** `+$` in `sur/tla-lus` with a real value, actions, updates, subscriptions, scries, dojo examples |
| `desk/doc/architecture.md` | 264 | The pure `lib/` stack, the Gall shell, async Clay load, quotas, persistence, trust boundaries |
| `desk/doc/tla-bnf.md` | 423 | The accepted grammar, production by production, traceable to `javacc/tla+.jj`; the canonical operator table |
| `desk/doc/compatibility.md` | 1887 | The release matrix, **every approved difference with its evidence**, per-unit parity notes, the `tlc2.TLC` flag-by-flag disposition, and the typed-rejection summary table |
| `desk/doc/parity-manifest.md` | 210 | The machine-checked ledger: one row per Java behavioural cluster and per public request option, each with a status |
| `desk/doc/evidence-counts.md` | 38 | **Generated** by `tools/validate.py`; the case count each generator actually ran. Docs cite it, never hand-write counts |
| `desk/doc/testing.md` | 582 | The three validation tiers, fuzzing, how to add a case, how to read a `-test` verdict |
| `desk/doc/port-map.md` | 498 | Pinned upstream sources, oracle build/invocation, normalization rules, the Java class inventory and its Hoon owner |

## Where to look first, by question

- *"Can it do X?"* — `compatibility.md` §"Typed-rejected / unsupported public
  options — summary", then `lib/job.hoon` `+validate`.
- *"What shape is X on the wire?"* — `api.md` mold reference; confirm in
  `sur/tla-lus.hoon`.
- *"Why does it differ from Java?"* — `compatibility.md` §"Support matrix —
  every approved difference". Every row names its evidence generator.
- *"Is this tested, and by what?"* — `parity-manifest.md` row → `oracle-test`
  column → `evidence-counts.md` for the count → the named
  `desk/tests/lib/*.hoon`.
- *"Is this grammar accepted?"* — `tla-bnf.md`; the `### G-…` headings are
  drift-checked against `grammar-manifest:syntax` by `tests/lib/bnf.hoon`.

## Provenance for TLA+ itself

The language and tool semantics in this pack are grounded in Lamport's
*Specifying Systems*. Chapter summaries live in
`tla-lus-specification/references/book/`; the full set (18 chapters, including
the ones this pack does not copy) is at `FoxyLabs/tla-lus/specifying-systems/`.
See `tla-lus-specification/references/source-map.md`.
