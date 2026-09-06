# Enabling PlusCal in `%tla-lus`

## Exactly what is refused today

Two typed rejections, both at **submit**, in `desk/lib/job.hoon` `+validate`:

```
op = %translate                    -> 'unsupported: PlusCal translation is not ported yet (unit 8)'
check-opts.translate = &           -> 'unsupported: translate-before-check is not ported yet (unit 8)'
```

Nothing else about PlusCal is refused, because nothing else about PlusCal is
reachable: `+plan` returns an empty stage list for `%translate`, and the
`%translate` stage tag exists in `sur/tla-lus.hoon` but is never entered.

## What already exists

| Piece | State |
|---|---|
| `fairness` / `pcal-opts` on the wire | **present** — `?(%none %wf %sf %wf-next)`, `termination=?`, `gen-cfg=?`, mirroring `-nof`/`-wf`/`-sf`/`-wfNext`, `-termination`, `-nocfg` |
| `%translate` in `op` and in `stage` | **present**, unreachable |
| `desk/lib/crc.hoon` | **ported, at parity** — the CRC-32 the `BEGIN TRANSLATION` markers need (ledger `pcal-crc`, 7 tests) |
| `desk/test-data/pcal/` | **two corpus fixtures** (`counter`, `twovars`) |
| `tools/gen-pcal-tests.py` | **2 goldens, `oracle-only`** — captured from the pin, no Hoon comparator |
| `tools/oracle/CrcVec.java` | the checksum dumper |
| The translator itself | **not ported** |

So the wire, the stage tag, the checksum primitive, the fixtures and the
goldens are all in place. What is missing is `pcal/Tokenize`,
`ParseAlgorithm`, the AST, `PcalTranslate`, `PcalTLAGen` and `trans` — ledger
row `pcal-translate`.

## The status is `excluded`, not `absent` — and that matters

`desk/doc/parity-manifest.md` marks `pcal-translate`, `op-translate` and
`check-opt-translate` **`excluded`**: PlusCal translation is outside
PORT-COMPLETION-PLAN-2's scope boundary (tla2sany + tlc2 parity), a decision
taken at R1.0 and reaffirmed at R3.1 ("PlusCal is out of the project"). It is
not a gap that R3 left open; it is a boundary that was drawn.

The refusal *message* says "not ported yet (unit 8)", which reads as
provisional. Both readings are documented; the ledger's is the operative one.
**If PlusCal comes into scope, that is a scope decision first and an
implementation task second.**

Invariant 8 governs the interim: **no stub ever returns a plausible
translation.** Whatever happens, `%translate` must never produce TLA+ it did
not actually derive.

## Checklist to make it available

1. **Re-scope.** Move `pcal-translate`, `op-translate` and
   `check-opt-translate` from `excluded` to `absent` in
   `desk/doc/parity-manifest.md`, with the decision recorded. `check-parity.py`
   will then report them as owed and the release gate will go red — which is
   the correct signal.
2. **Port the translator** into `desk/lib/pcal.hoon` (or a small stack:
   tokenizer, algorithm parser, AST, translate, TLA-gen), consuming
   `lib/source` positions and emitting text the existing `lib/syntax` parser
   accepts. `lib/crc` already supplies the checksums.
3. **Add the stage.** `+plan:job` returns `~[%translate]` (plus the check
   stages when `check-opts.translate` is set); `+step:job` runs it as a bounded
   slice like any other; the generated TLA+ feeds `%parse` in the same job.
4. **Delete the two rejections** in `+validate` — and *only* those two.
5. **Build the comparator.** `tools/gen-pcal-tests.py` already captures goldens
   from the pin; it needs a Hoon shard (`desk/tests/lib/pcal.hoon`) that
   compares against them, which is what turns its `oracle-only` status into
   `parity`. Grow the fixture corpus well past two: p-syntax and c-syntax, each
   fairness flag, `-termination`, `-nocfg`, `-label`, macros, procedures,
   multiprocess, and the label-error cases.
6. **Document both ways.** Add the capability to
   `desk/doc/compatibility.md`'s tables and **remove the two refusal rows** —
   `release-gate.sh` R4 checks every `unsupported:` message in the desk against
   that table in both directions, so a stale row fails the gate.
7. **Update the docs that name it**: `desk/doc/users-guide.md` §Concepts,
   `desk/doc/api.md` (the `pcal-opts` row says "`%translate` is a typed
   rejection today"), and `desk/doc/architecture.md`'s unit-8 note.
8. **Update this pack**: this skill's frontmatter and banner, and
   `tla-lus-overview`'s support matrix.

## What would *not* need to change

The wire. `op`, `pcal-opts`, `fairness` and the `%translate` stage tag are
already the shapes a working translator would use, so enabling it is
**capability, not a wire reshape** — and therefore not an `api-version` move
even after release.
