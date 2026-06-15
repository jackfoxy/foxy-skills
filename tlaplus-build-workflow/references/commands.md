# Build and Test Commands

This file owns repeated Ant, Maven, Tycho, CI, devcontainer, and generated-artifact command guidance for the TLA+ skill pack.

## Dependencies

TLA+ tools:

- Java Development Kit 11+
- Apache Ant 1.9.8+

Toolbox:

- JDK 11 when following `DEVELOPING.md`; newer versions are version-sensitive.
- Apache Ant 1.9.8+
- Apache Maven 3.9.7+
- Git 2.0+

CI workflows may use JDK 17 for some jobs; report the local JDK when comparing to CI.

## Build TLA+ Tools

All commands below run from repo root unless they `cd`.

```bash
cd tlatools/org.lamport.tlatools
ant -f customBuild.xml info compile compile-test dist
java -cp dist/tla2tools.jar tlc2.TLC test-model/pcal/Bakery.tla
ant -f customBuild.xml test
ant -f customBuild.xml test-set -Dtest.testcases="tla2sany/parser/TlaPlusSyntaxCorpusTests.java"
ant -f customBuild.xml test-set -Dtest.testcases="tlc2/util/*Vec*"
```

Output jar: `tlatools/org.lamport.tlatools/dist/tla2tools.jar`.

## Ant Target Reference

| Target | Action |
|---|---|
| `info` | print environment and revision info |
| `compile` | compile application classes |
| `compile-test` | compile test classes |
| `dist` | package `tla2tools.jar` |
| `test` | run unit tests |
| `test-set` | run a single test or glob pattern |
| `test-report` | generate test report |
| `test-dist` | run post-distribution tests |
| `generate` | regenerate parser from JavaCC grammar |
| `shorttests` | short test suite |
| `longtests` | long-running tests |
| `default` | default full build/test/dist sequence |

## Targeted Tests

`test-set` paths are relative to `tlatools/org.lamport.tlatools/test`. Quote globs so the shell does not expand them.

```bash
cd tlatools/org.lamport.tlatools
ant -f customBuild.xml test-set -Dtest.testcases="tlc2/tool/MonolithSpecTest*"
ant -f customBuild.xml test-set -Dtest.testcases="tlc2/util/*Vec*"
ant -f customBuild.xml test-set -Dtest.testcases="tla2sany/parser/TlaPlusSyntaxCorpusTests.java"
```

## Parser Generation and Sync

```bash
ant -f tlatools/org.lamport.tlatools/customBuild.xml generate
git status --porcelain=v1
```

Generated parser files must match `javacc/tla+.jj`. If the grammar changed, commit regenerated parser output with the grammar change. If no grammar changed, generated diffs indicate drift.

## Capturing Tool Output in Tests

Use `TestPrintStream` with `ToolIO` to capture tool stdout/stderr in Java tests. Search the test tree for existing usage.

```java
ToolIO.setMode(ToolIO.TOOL);
ToolIO.reset();
String[] output = ToolIO.getAllMessages();
```

## Toolbox

```bash
mvn install -Dmaven.test.skip=true
mvn verify
xvfb-run mvn -Dtest.skip=true -Dmaven.test.failure.ignore=true \
  -Dtycho.disableP2Mirrors=true \
  -fae -B verify --file pom.xml
```

Toolbox distributables are produced under `toolbox/org.lamport.tla.toolbox.product.product/target/products/`.

## Devcontainer

The `.devcontainer/` setup provides Java 11, Maven, Ant, Git, and Xvfb. Open the repo in VS Code and choose "Reopen in Container". The container runs `ant -version && mvn -version` after creation.

## CI Anchors

- PR tools build: `ant -f tlatools/org.lamport.tlatools/customBuild.xml info compile compile-test dist`
- PR tools test: `ant -f tlatools/org.lamport.tlatools/customBuild.xml info test -Dtest.halt=true`
- PR parser generated sync: `ant -f tlatools/org.lamport.tlatools/customBuild.xml generate`
- JPF verification: `ant -f tlatools/org.lamport.tlatools/customBuild.xml info compile compile-test test-verify`
- Toolbox build/test: Maven/Tycho with `xvfb-run` on headless Linux.
- CommunityModules integration: build jar, copy into CommunityModules, run that build.
- Perf job: compile, compile-test, dist under JDK 11.

## Eclipse Caveat

Running Ant from the CLI while Eclipse is open can cause phantom compile errors in Eclipse. Prefer running Ant through Eclipse's Ant view when working inside Eclipse. If phantom errors appear, refresh the project.

## Generated and Ignored Artifacts

Do not cite these as source authority:

- `dist/`
- `target/`
- `states/`
- `.tlacache/`
- JavaCC-generated parser files such as `src/tla2sany/parser/TLAplusParser.java`
- run output such as generated `.out`, trace, or coverage files
