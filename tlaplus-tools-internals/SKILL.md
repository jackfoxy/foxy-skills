---
name: tlaplus-tools-internals
description: Understand and modify the core Java implementation of the TLA+ toolchain - the SANY parser/semantic/level-checking/AST pipeline, the TLC engine architecture (tool/value/util/module/output), the Java<->TLA+ override mechanism, and the PlusCal translator. Use when changing tool behavior at the implementation level, adding/debugging language features in the tools, or tracing how a spec is processed internally. For grammar/XML front-end detail see tlaplus-parser-xml-tooling.
user-invocable: true
disable-model-invocation: false
---

# TLA+ Tools Internals (Java)

Implementation-level map of `tlatools/org.lamport.tlatools/src`. Build/test: [[tlaplus-build-workflow]]; grammar + XML front-end: [[tlaplus-parser-xml-tooling]]; override TLA+ side: [[tlaplus-stdlib]]; translator: [[tlaplus-pluscal]].

## Two halves
- **SANY (`tla2sany/`)** — the front end: `tla2sany.SANY.frontEndMain()` runs **(1) syntax parsing → (2) semantic analysis → (3) level checking**, returning a `ModuleNode`. `parse()` is process-safe but **not thread-safe**.
- **TLC (`tlc2/`)** — the model checker: `tlc2.TLC.main()` builds and explores the state graph (BFS/`ModelChecker`, simulation; liveness via SCC). ⚠ Holds **global static state** — cannot run twice in one JVM without reloading classes.

The full subpackage map (SANY `parser`/`st`/`semantic`/`modanalyzer`/`xml`/`drivers`; TLC `tool`/`value`/`util`/`module`/`output`/`overrides`) is in `references/package-map.md`.

```bash
java -cp dist/tla2tools.jar tla2sany.SANY -error-codes MySpec.tla   # parse + coded errors
```

## The override contract (Java replaces TLA+ defs)
Operators in `StandardModules/*.tla` are overridden at runtime by methods of the same name in `tlc2/module/<Module>.java`; infix operators map to method names via a `static` `TLARegistry` block. Full detail + how to add one: [[tlaplus-stdlib]].

## Workflows
- **Add a TLC override:** find op in `StandardModules/` → add method in `tlc2/module/` → `ant compile compile-test` → targeted `test-set`.
- **Patch parser/semantic:** edit `tla+.jj` or `semantic/` → `ant generate compile` (CI fails if generated code drifts) → run `tla2sany/parser/*` + `semantic/*` tests. Grammar detail: [[tlaplus-parser-xml-tooling]].
- **Trace a spec internally:** `SANY.parse()` → inspect `SpecObj`/`ModuleNode`; or export XML.
- **Patch TLC core:** edit `tool/`/`value/`/`output/` → targeted `test-set` + model-check a known model.

## Invariants / rules
- Generated parser must stay in sync with `tla+.jj` (CI `generate` + `git status` check).
- Overrides must exactly match the `TLC.tla` (etc.) signatures.
- TLC is single-shot per JVM (global static state); SANY parse is not thread-safe.

## Validation
For an internals change: name the subpackage owning the behavior, the entry method, the minimal edit, the test-set glob that exercises it, and (for parser/override edits) the sync/contract rule it must satisfy.

## References (local)
- `references/package-map.md` — full SANY + TLC subpackage breakdown
- `src/tla2sany/SANY.java`, `drivers/`, `semantic/`, `parser/`, `st/`, `modanalyzer/SpecObj.java`, `xml/`
- `src/tlc2/TLC.java`, `tool/`, `value/`, `util/`, `module/`, `output/{EC,MP}.java`, `overrides/`
- `src/pcal/trans.java`; `javacc/tla+.jj`; `customBuild.xml` (`generate`/`compile`/`test-set`)
