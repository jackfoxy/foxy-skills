# SANY & TLC Java Package Map

Root: `tlatools/org.lamport.tlatools/src`.

## SANY front end (`tla2sany/`)
Entry `tla2sany.SANY` / `tla2sany.drivers.SANY.frontEndMain()`. Three phases (per `SANY.java`): **(1) syntax parsing → (2) semantic analysis → (3) level checking**, returning a `ModuleNode`. `parse()` is process-safe but **not thread-safe**.

| Subpackage | Contents |
|------------|----------|
| `parser/` | generated + hand-written parser (`TLAplusParser*`, `Operators`, `OperatorStack` for precedence/associativity, `ParseError(s)`, `SyntaxTreeNode`); generated from `javacc/tla+.jj` |
| `st/` | syntax-tree abstractions (`ParseTree`, `TreeNode`, `Location`) |
| `semantic/` | semantic graph: `Generator`, `ModuleNode`, `Context`, `OpDefNode`, level checking (`LevelNode`), `BuiltInOperators`, `ASTConstants`, `ErrorCode`, `Errors` |
| `modanalyzer/` | `SpecObj` (the parsed-spec object the public API populates), module dependency resolution |
| `xml/` | AST → XML export (`XMLExporter`, `sany.xsd`) |
| `drivers/` | `SANY` driver, `SanyExitCode`, exceptions |

## TLC model checker (`tlc2/`)
Entry `tlc2.TLC.main()` (also `java -jar`). ⚠ Holds **global static state** — cannot run twice in one JVM without reloading classes.

| Subpackage | Contents |
|------------|----------|
| `tool/` | checking engine: builds the state graph, computes initial/next states, evaluates invariants/properties; BFS (`ModelChecker`), simulation; liveness via SCC; `impl/TLARegistry` |
| `value/` | runtime TLA+ values (`IntValue`, `SetEnumValue`, `FcnRcdValue`, `RecordValue`, `TupleValue`, …) and enumeration/normalization |
| `util/` | fingerprinting (`FP64`), state queue, bit-sets, vectors (`LongVec`) |
| `module/` | Java implementations of overridden StandardModule operators |
| `output/` | user-facing messaging: `EC` (236 error codes) + `MP` (message text) |
| `overrides/` | annotation-based operator overrides (`@TLAPlusOperator`) |

## Other tools
- `tla2tex/` — TLA+ → LaTeX (`tla2tex.TLA`), low priority.
- `pcal/` — PlusCal translator (see tlaplus-pluscal).
- `tlc2.REPL` — interactive evaluator over `value/`+`tool/`.
