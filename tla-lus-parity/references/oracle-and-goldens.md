# The Java Oracle

The **only** external dependency is the oracle used to *build the tests*: the
Java `tla2tools.jar` at a pinned commit. It is never shipped and never called
at runtime. The desk contains no GUI, no Toolbox, no `tla2tex`, and no Java.

## Pins

| Pin | Commit |
|---|---|
| `tlaplus` (SANY / PlusCal / TLC) | `4ba7d8811289fb8e95dac4d5e554c05216ba3100` |
| `tlaplus-Examples` (fixtures) | `47b0e2cc` |
| `vscode-tlaplus` (fixtures) | `acc095d6` |

Both `tools/validate.py` and `desk/test-data/oracle/regen.sh` **refuse to
(re)generate goldens if the checkout is off-pin**, so a golden can never
silently drift to a newer tool version. `scaffold-gate.sh` gate 1 checks the
same thing.

## Building the jar

```bash
cd $TLA_REPO/tlatools/org.lamport.tlatools
ant -f customBuild.xml info compile compile-test dist
# -> dist/tla2tools.jar (~4.3 MB)   [validated with Ant + OpenJDK 11]
```

Smoke check — must reproduce exactly under the pin:

```bash
java -cp dist/tla2tools.jar tlc2.TLC -deadlock test-model/pcal/Bakery.tla
# 1183 states generated, 668 distinct states found, depth 41, no error
```

## Invocation forms

One jar, several mains (`java -jar` aliases `tlc2.TLC`):

| Stage | Form |
|---|---|
| SANY | `java -cp tla2tools.jar tla2sany.SANY [-s] [-l] [-lint] [-error-codes] [-messagesAsErrors codes] [-suppressMessages codes] FILE...` |
| PlusCal | `java -cp tla2tools.jar pcal.trans [-nocfg] [-wf\|-sf\|-wfNext\|-nof] [-termination] [-label] [-lineWidth n] FILE` (rewrites FILE **in place**; writes `FILE.cfg` unless `-nocfg`) |
| TLC check | `java -cp tla2tools.jar tlc2.TLC [-config FILE.cfg] [-deadlock] [-workers 1] [-fp 0] [-seed N] [-metadir DIR] [-cleanup] [-lncheck final] [-tool] FILE` |
| TLC simulate | `java -cp tla2tools.jar tlc2.TLC -simulate num=N -depth D -seed S [-aril A] … FILE` |
| XML AST (oracle format only) | `java -cp tla2tools.jar tla2sany.xml.XMLExporter [-o] FILE` |

**Determinism flags for every oracle run: `-workers 1 -fp 0`**, plus an
explicit `-seed` (and `-aril`) for simulation. `-fp 0` matters beyond
reproducibility: the RNG's per-predecessor reseed is `state.fingerPrint() ^
seed`, so a different fingerprint function is a different draw sequence.

`-tool` mode emits `@!@!@STARTMSG <EC-code>` tagged messages; the tagged form
is the long-term compatibility surface for diagnostics, while the unit-0
goldens use the plain human-readable form. `lib/diagnostics` byte-matches
`MP.getMessage` in **both** modes (192 cases).

Exit codes: SANY with `-error-codes` documents `2` (parse) and `4`
(semantic/level), but the pinned build observably exits **255** on fatal
lexical/parse errors and `4` on semantic/level errors. TLC exits `0` on
success and non-zero per `tlc2.output.EC` category (e.g. `151` config error).
**The port matches the coded-diagnostic categories, not CLI exit integers.**

Two inherited constraints: **TLC holds global static state and cannot run twice
in one JVM** (one process per oracle run), and SANY's `parse()` is
process-safe but not thread-safe.

## Oracle dumpers

Hand-written Java under `tools/oracle/`, compiled by `validate.py`:

| Dumper | Captures |
|---|---|
| `TokenDump` | lexer tokens, kinds, images, spans |
| `AstDump` | the parser CST |
| `SemDump` | the semantic graph and levels |
| `ConfigDump` | the normalized `.cfg` projection |
| `ParseErrDump` | verbatim `PErrors` entries |
| `InternDump` | SANY's string intern order (the evidence behind `tlc-value-order`) |
| `CrcVec` | PlusCal checksums |

Plus the REPL/TLC/SANY invocations the generators drive directly.

## Normalization rules

Implemented in `desk/test-data/oracle/regen.sh` (`normalize()`); every rule
here must stay in sync with that script. Comparison is on normalized text.

1. Line endings CRLF→LF; strip trailing whitespace; ensure a final newline.
2. Absolute paths → `<WORK>/` and `<REPO>/`.
3. Timestamps `YYYY-MM-DD hh:mm:ss` → `<DATETIME>`; durations → `<D>`.
   TLC's temp StandardModules dir → `<TLCTMP>`; the version banner's jar build
   timestamp → `TLC2 Version <BUILD> (rev: …)`, **keeping the rev hash** as the
   oracle pin.
4. Rates and machine sizing (`N s/min`, core counts, heap/offheap MB) →
   `<N>`; the `Working set` / OS+JVM lines are dropped.
5. Randomness: runs pin `-fp 0 -workers 1`; the `with fp N and seed N` line is
   kept **verbatim** (deterministic under pinned flags).
6. `Progress(N) at (…)` keeps N and normalizes the timestamp/rate; checkpoint
   directory names → `<METADIR>`.
7. **No reordering is applied.** Single worker + fixed fp make counts and traces
   deterministic. If a future case emits set-ordered diagnostics, sort just that
   block and record it here.
8. The TLC/SANY version banners are kept verbatim — they pin the oracle
   version.
9. Trace-exploration artifacts (`*_TTrace_*.tla/.bin`) are excluded.

Two further normalizations live in the tier-2 harness
(`tools/gen-tier2-tests.py`), not the engine, and are named where applied: the
**generated-state count is dropped** (still diverging on `DieHard` 253 vs 252
and `Continue` 4 vs 3), and each state's **bindings are sorted**, because tlc2
prints them in `java.util.Hashtable` bucket order. Both are measured, not
assumed.

## Why the trace-explorer flags stay excluded

`TraceExplorationSpec.teModuleId` is `timestamp.getTime() / 1000` — seconds
since the epoch — and it goes into the generated **module name**, hence the file
name, the module header, the `.bin` path registered as a `_TLCTrace`
postcondition, and the console line. The artifact's identity is the wall clock,
so no two runs agree and no differential can pin one. Same argument as
`TLCGet("duration")`, `_PERIODIC`, and `TLC!JavaTime`.

(`gen-mc-tests.py` and `gen-dfid-tests.py` both drop the `Trace exploration`
line from every golden, and `gen-mc-tests.py` deletes the `spec_TTrace_*`
artifacts because they carry Clay marks that abort `|commit`.)
