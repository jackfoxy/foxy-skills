# Ant Targets, Test Selection & CI Pipeline

## `customBuild.xml` targets

| Target | Does |
|--------|------|
| `info` | print build/git revision info |
| `compile` | compile application classes (depends on `clean, generate`) |
| `compile-test` | compile test classes |
| `dist` | package `dist/tla2tools.jar` |
| `generate` | run JavaCC over `javacc/tla+.jj` to regenerate the parser (normalizes to LF) |
| `test` | run the full unit-test suite |
| `test-set` | run a subset (`-Dtest.testcases=...`) |
| `test-report` | generate JUnit HTML/XML report |
| `clean` | remove build outputs |
| `test-verify` | JPF verification tests (needs JDK 11) |
| `test-formatter-semantic`, `test-formatter-tlaps` | formatter tests against examples |
| `benchmark` | build the self-contained JMH benchmark jar |

## Running tests
```bash
ant -f customBuild.xml test                       # full suite (all should pass)
ant -f customBuild.xml test -Dtest.halt=true      # stop on first failure (CI uses this)
# Single test or glob; path relative to test/ ; QUOTE the glob:
ant -f customBuild.xml test-set -Dtest.testcases="tla2sany/parser/TlaPlusSyntaxCorpusTests.java"
ant -f customBuild.xml test-set -Dtest.testcases="tlc2/util/*Vec*"   # validated
```
Reports: `tlatools/org.lamport.tlatools/target/surefire-reports/`.

## CI pipeline (`.github/workflows/`)

**`pr.yml`** — validates PRs:
- *TLA+ Tools Build & Test*: matrix ubuntu/macos/windows, JDK 17, `fetch-depth: 0` (jgit needs history). First a **grammar/code sync check**: `ant ... generate` then fail if `git status` is dirty (regenerated parser must match committed code; Windows forces `core.autocrlf input`). Then `info compile compile-test dist`, `test -Dtest.halt=true`, `test-report`, upload `tla2tools.jar`, build CommunityModules as integration test.
- *JPF Verification*: JDK 11, `test-verify`.
- *Eclipse Toolbox Build & Test*: ubuntu `xvfb-run mvn ... verify`; macOS `mvn -Dmaven.test.skip=true`. Tycho `-Dtycho.disableP2Mirrors=true`.
- *Examples Integration*: clones `tlaplus/examples`, parses every `.tla` with `tla2sany.SANY -error-codes`, runs `XMLExporter`, model-checks small models, smoke-tests large ones (unicode + ascii matrix).

**`main.yml`** — same build/test on master, publishes to the `v1.8.0` pre-release.
**`perf.yml`** — performance job (see tlaplus-performance).

## Dev container
`.devcontainer/` layers Java 11, Maven, Git, Ant, Xvfb onto `mcr.microsoft.com/devcontainers/base:ubuntu`. VS Code → "Reopen in Container"; `postCreateCommand` runs `ant -version && mvn -version`.
