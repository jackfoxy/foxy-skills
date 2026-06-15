---
name: tlaplus-build-workflow
description: Build, package, test, and develop the TLA+ tools and Toolbox locally or in CI - Ant targets for tla2tools.jar, Maven/Tycho for the Toolbox, the test-set/test targets, the devcontainer, and the GitHub CI matrix. Use to compile the jar, run the test suite or a single test, set up a dev environment, or understand the CI pipeline. Owns every ant/mvn command line for the pack.
user-invocable: true
disable-model-invocation: false
---

# Build & Test Workflow

Owns every `ant`/`mvn` command for the pack. Toolbox specifics: [[tlaplus-toolbox-eclipse]]; contribution process: [[tlaplus-contribution]]. Java **11+** required (CI uses 17 for tools; Toolbox needs JDK 11 — newer JDKs break it).

## Build the CLI tools (Ant — primary)

```bash
cd tlatools/org.lamport.tlatools
ant -f customBuild.xml info compile compile-test dist    # -> dist/tla2tools.jar (validated, ~4.3 MB)
java -cp dist/tla2tools.jar tlc2.TLC test-model/pcal/Bakery.tla   # smoke test -> "No error has been found."
```
The output jar is identical in use to a release jar. Full target list, test-selection, the CI pipeline, and the devcontainer are in `references/targets-and-ci.md`.

## Run tests

```bash
ant -f customBuild.xml test                       # full suite (all should pass)
ant -f customBuild.xml test -Dtest.halt=true      # stop on first failure (CI default)
ant -f customBuild.xml test-set -Dtest.testcases="tlc2/util/*Vec*"   # subset (validated); QUOTE the glob
```
Path in `-Dtest.testcases` is relative to the `test/` dir. Reports land in `target/surefire-reports/`.

## Build the Toolbox (Maven/Tycho)

```bash
mvn install -Dmaven.test.skip=true   # build Toolbox (from repo root)
mvn verify                           # build + run tests
```
Distributables: `toolbox/org.lamport.tla.toolbox.product.product/target/products/`. Needs JDK 11, Ant 1.9.8+, Maven 3.9.7+, Git. Detail: [[tlaplus-toolbox-eclipse]].

## CI at a glance
`pr.yml` (PR validation, 3-OS matrix, JDK 17) and `main.yml` (master → `v1.8.0` pre-release) run the same build/test; `pr.yml` also enforces a **grammar/code sync check** (`generate` then `git status` must be clean) and an examples-integration job. `perf.yml` → [[tlaplus-performance]]. Full breakdown: `references/targets-and-ci.md`.

## Validation checklist (clean clone → working jar)
1. `cd tlatools/org.lamport.tlatools && ant -f customBuild.xml info compile compile-test dist`
2. `java -cp dist/tla2tools.jar tlc2.TLC test-model/pcal/Bakery.tla` → "No error has been found."
3. `ant -f customBuild.xml test-set -Dtest.testcases="tlc2/util/*Vec*"` → BUILD SUCCESSFUL.

## References (local)
- `references/targets-and-ci.md` — full target list, test-set usage, CI pipeline, devcontainer
- `DEVELOPING.md`, `tlatools/org.lamport.tlatools/README.md`
- `tlatools/org.lamport.tlatools/customBuild.xml`, root `pom.xml`, `tlatools/org.lamport.tlatools/pom.xml`
- `.github/workflows/{pr,main,perf}.yml`, `.devcontainer/`
