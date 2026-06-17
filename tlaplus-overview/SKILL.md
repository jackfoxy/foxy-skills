---
name: tlaplus-overview
description: High-level orientation to the tlaplus/tlaplus repository (TLA+ CLI tools + Eclipse Toolbox IDE), its tool entrypoints, and which sibling skill to use for a given task. Use when first interacting with the TLA+ toolchain repo, deciding between CLI/editor/build paths, or routing to the right tlaplus-* skill. Points to the shared external-link inventory and source-map for the whole pack.
user-invocable: true
disable-model-invocation: false
---

# TLA+ Toolchain: Overview & Navigation

Use this first for broad orientation in `/mnt/mars/gitrepos/tlaplus`. Prefer local repo facts over web knowledge. This skill **routes**; commands and detail live in the target skills.

This repo (`tlaplus/tlaplus`) is the **Java source repo for the TLA⁺ toolchain**, not a collection of user specs. Two products:

- **`tlatools/org.lamport.tlatools/`** — the CLI tools, packaged as one `tla2tools.jar`. Built with **Ant** (`customBuild.xml`), wrapped by Maven.
- **`toolbox/`** — the Eclipse-RCP IDE (~30 OSGi plugins), built with **Maven/Tycho**. Currently **unmaintained** / lower-priority vs. CLI + VS Code.

## Source-of-truth boundary (two repos)

This pack covers the **Java toolchain only**. The VS Code/Cursor extension is a **separate repo** with its own source of truth — do **not** inspect or edit it here, and do not treat it as authoritative for Java internals.

| Behavior | Source of truth | Where to inspect |
|---|---|---|
| SANY parse/semantic/level checking, TLC checking/simulation/liveness/debugger **engine**, PlusCal translator, XML exporter, TLA2TeX, formatter Java impl, StandardModules + Java overrides (`tlc2`, `tla2sany`, `pcal`, `tla2tex`, `formatter`, `util`, `model`) | `tlaplus` | `/mnt/mars/gitrepos/tlaplus` (this pack) |
| Extension activation/commands/settings/menus/views, TS integration around the jar, webviews/panels/diagnostics/**output parsing**, MCP tools, bundled-jar usage + packaging, UI/UX, extension+Playwright tests, syntax highlighting/snippets/language config | `vscode-tlaplus` | `/mnt/mars/gitrepos/vscode-tlaplus` (no skill in this pack) |

`vscode-tlaplus` bundles `tools/tla2tools.jar` but contains **no Java source**; the bundled jar may not match the local `tlaplus` checkout. For behavior that crosses the boundary (e.g. extension parsing TLC output), inspect both and name the boundary contract explicitly.

Primary conceptual reference: Lamport's *Specifying Systems* — https://lamport.azurewebsites.net/tla/book.html

## Start here
1. For authority + routing detail, read `references/source-map.md`.
2. For command-line usage, read `README.md` and `USE.md`.
3. Before embedding any external URL, read `references/external-links.md`.
4. Route the task using the decision guide below.

## The tools (one jar, many entrypoints)

Requires **Java 11+**. Add `tla2tools.jar` to `CLASSPATH`, then:

```bash
export CLASSPATH=tla2tools.jar
java tla2sany.SANY -help            # parser / semantic analyzer
java tlc2.TLC -help                 # model checker
java tlc2.REPL                      # TLA+ REPL
java pcal.trans -help               # PlusCal -> TLA+ translator
java tla2tex.TLA -help              # TLA+ -> LaTeX
java tla2sany.xml.XMLExporter -help # parse tree as XML
```

`java -jar tla2tools.jar` is aliased to `tlc2.TLC`.

⚠ **TLC holds global static state** — it cannot be run twice in one JVM process; use a fresh process (or reload its classes) for repeated runs. SANY's `parse()` is process-safe but not thread-safe.

Interfaces, in order of recommendation for new users:
1. **VS Code extension** (https://github.com/tlaplus/vscode-tlaplus/) — the modern graphical UI. Its behavior lives in the separate `vscode-tlaplus` repo (see boundary above), not here.
2. **`tla2tools.jar` CLI** — for scripting, CI, non-Java consumers (XML/DOT/JSON export).
3. **Eclipse Toolbox** — legacy, unmaintained; see [[tlaplus-toolbox-eclipse]].

Get the jar from [Releases](https://github.com/tlaplus/tlaplus/releases) (master commits go to the `v1.8.0` Clarke pre-release), or build it yourself ([[tlaplus-build-workflow]]). As a Java library: Maven snapshots at `org.lamport.tla2tools`.

## Repo layout

```text
/
|-- README.md, USE.md, DEVELOPING.md, CONTRIBUTING.md
|-- pom.xml                                # Maven aggregator
|-- tlatools/org.lamport.tlatools/
|   |-- customBuild.xml                    # Ant build (primary for the jar)
|   |-- src/
|   |   |-- tla2sany/                       # parser + semantic analyzer (SANY)
|   |   |   |-- StandardModules/            # bundled .tla stdlib
|   |   |   `-- xml/sany.xsd                # XML AST schema
|   |   |-- tlc2/                           # model checker (TLC)
|   |   |   |-- module/                     # Java overrides of stdlib ops
|   |   |   `-- output/{EC,MP}.java         # error codes + messages
|   |   |-- pcal/                           # PlusCal translator
|   |   `-- tla2tex/                        # LaTeX exporter
|   |-- test/                               # Java unit tests
|   |-- test-model/                         # .tla/.cfg fixtures (examples)
|   `-- javacc/tla+.jj                      # grammar (parser source of truth)
`-- toolbox/                                # Eclipse RCP IDE
```

## Decision guide — which skill

| Task | Skill |
|------|-------|
| Read/write/validate a `.tla` module; level checking; operators | [[tlaplus-syntax]] |
| Configure `.cfg`, run TLC (check/simulate), interpret stats | [[tlaplus-model-checking]] |
| Diagnose a parse/config/runtime/safety/liveness failure or trace | [[tlaplus-debugging]] |
| Build the jar, run tests, CI, devcontainer | [[tlaplus-build-workflow]] |
| Contribution process, commits, DCO, PR style | [[tlaplus-contribution]] |
| PlusCal algorithms & the `pcal.trans` translator | [[tlaplus-pluscal]] |
| StandardModules and the Java override mechanism | [[tlaplus-stdlib]] |
| Large/real-world models, perf measurement | [[tlaplus-performance]] |
| Modify SANY/TLC/translator Java internals | [[tlaplus-tools-internals]] |
| JavaCC grammar, generated parser, XML AST, sany.xsd, corpus | [[tlaplus-parser-xml-tooling]] |
| Eclipse Toolbox IDE, OSGi plugins, Tycho build | [[tlaplus-toolbox-eclipse]] |
| VS Code/Cursor extension behavior, settings, webviews, MCP, output parsing, packaging | out of pack → `/mnt/mars/gitrepos/vscode-tlaplus` |

Dedup contract: syntax owns module examples, debugging owns the error taxonomy, build owns every `ant`/`mvn` line, parser/XML and toolbox facts stay isolated, and this skill owns the shared inventories in `references/`.

## CLI quickstart (validated)

```bash
# build first (see tlaplus-build-workflow), then:
java -cp dist/tla2tools.jar tlc2.TLC test-model/pcal/Bakery.tla
# => "Model checking completed. No error has been found."
#    668 distinct states, depth 41
```

## Validation
Given an unknown TLA+ tools task, name: the owning subtree, the owning skill, the first local file to read, the likely command, and the validation surface — before doing the work.

## References (local)
- `README.md`, `USE.md`, `DEVELOPING.md`, `CONTRIBUTING.md`, `tlatools/org.lamport.tlatools/README.md`
- `references/source-map.md` — authority + routing for the whole pack
- `references/external-links.md` — embeddable anchors + do-not-embed policy
