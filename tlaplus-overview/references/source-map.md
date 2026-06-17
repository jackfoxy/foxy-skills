# TLA+ Tools Source Map

Repository: `/mnt/mars/gitrepos/tlaplus` — source of truth for the **Java toolchain** (SANY, TLC, PlusCal, XML export, TLA2TeX, formatter Java impl, StandardModules + overrides). This map covers this repo **only**.

VS Code/Cursor extension behavior (commands, settings, webviews/panels, diagnostics, output parsing, MCP, syntax highlighting, bundled-jar usage + packaging) is **not authoritative here** — it lives in the separate `/mnt/mars/gitrepos/vscode-tlaplus` repo, which has no skill in this pack. The bundled `tools/tla2tools.jar` there may not match this checkout. See the boundary table in `SKILL.md`.

| Local path | Knowledge | Skills | Authority |
|---|---|---|---|
| `README.md`, `USE.md` | product overview, CLI entrypoints, Java 11+, releases, library/non-Java use | overview, syntax, model-checking | authoritative |
| `DEVELOPING.md` | layout, Ant/Maven commands, devcontainer, Eclipse, git, style | overview, build, contribution, toolbox | authoritative |
| `CONTRIBUTING.md`, `general/docs/contributions.md` | engagement, tests-first, surgical PRs, commit tags, DCO | contribution | authoritative |
| `pom.xml`, `tlatools/org.lamport.tlatools/customBuild.xml`, `tlatools/org.lamport.tlatools/pom.xml` | build targets and Maven wrapping | build | authoritative |
| `.github/workflows/pr.yml`, `main.yml`, `perf.yml` | CI matrix, JDK, xvfb, release/perf jobs | build, toolbox, performance | authoritative |
| `tlatools/org.lamport.tlatools/src/tla2sany/StandardModules/` | bundled standard modules and TLA+ idioms | syntax, model-checking, stdlib | authoritative |
| `tlatools/org.lamport.tlatools/src/tlc2/module/` | Java implementations for TLC overrides | stdlib, internals | authoritative |
| `tlatools/org.lamport.tlatools/src/tla2sany/`, `javacc/tla+.jj` | SANY pipeline and grammar | parser-xml, internals | authoritative |
| `tlatools/org.lamport.tlatools/src/tla2sany/xml/sany.xsd` | XML AST schema | parser-xml | authoritative |
| `tlatools/org.lamport.tlatools/src/tlc2/` | TLC engine, values, model, output, tracing | model-checking, debugging, internals | authoritative |
| `tlatools/org.lamport.tlatools/src/tlc2/output/EC.java`, `MP.java` | error codes and user-facing messages | debugging | authoritative |
| `tlatools/org.lamport.tlatools/src/pcal/` | PlusCal translator and specs | pluscal, internals | authoritative |
| `tlatools/org.lamport.tlatools/src/tla2tex/` | LaTeX exporter | internals | authoritative, low priority |
| `tlatools/org.lamport.tlatools/test/` | Java regression tests | build, debugging, internals, parser-xml | authoritative for expected behavior |
| `tlatools/org.lamport.tlatools/test-model/`, `general/tests/` | spec/config fixtures and examples | syntax, model-checking, debugging | example/test |
| `general/performance/` | real-world snapshots and measurement scripts | performance | example/test |
| `toolbox/`, `general/ide/README.md` | Eclipse RCP Toolbox plugins/features/product/Oomph | toolbox | authoritative |
| `general/docs/` changelogs/roadmaps/history | historical context | overview, contribution | supporting/historical |
| `dist/`, `target/`, `.tlacache`, `states/`, generated parser output, run `.out` files | generated artifacts | none | generated-never-cite |

Rules:

- Prefer authoritative docs, source, StandardModules, and schema for factual claims.
- Use `test-model/` as examples unless validating expected behavior.
- Do not cite generated artifacts as source.
- Keep repo layout here; individual skills should link here instead of repeating it.
