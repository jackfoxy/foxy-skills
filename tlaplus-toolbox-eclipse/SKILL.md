---
name: tlaplus-toolbox-eclipse
description: The Eclipse-RCP-based TLA+ Toolbox IDE - its ~30 OSGi plugins/features, the product definition, the Tycho/Maven build, update sites, Oomph dev setup, and its unmaintained status and JDK limitations. Use when working on or understanding the IDE surface, packaging Toolbox distributables, plugin development, or reproducing Toolbox-specific build/CI issues. For the tools jar build see tlaplus-build-workflow.
user-invocable: true
disable-model-invocation: false
---

# TLA+ Toolbox (Eclipse RCP IDE)

The legacy graphical IDE under `toolbox/`. **Currently unmaintained** — the maintained GUI is the VS Code extension ([[tlaplus-overview]]). Tool-jar build commands: [[tlaplus-build-workflow]]; this skill owns the Eclipse/Tycho specifics.

## Architecture (at a glance)
Eclipse RCP / OSGi: ~30 `toolbox/org.lamport.tla.toolbox.*` dirs — plugins (core + `.tool.tlc`, `.tool.tlc.ui`, `.editor.basic`, `.tool.tla2tex`, `.tool.prover`, `.doc`, …), features (`feature.xml` grouping plugins), packaging (`.product.product`, `.p2repository`), and tests (`*.test`/`*.uitest`). The product definition is `toolbox/org.lamport.tla.toolbox.product.product/org.lamport.tla.toolbox.product.product.product` (embeds `tla2tools.jar`). Full plugin/feature inventory + CI detail: `references/plugins-and-build.md`.

## Build (Maven/Tycho)
```bash
mvn install -Dmaven.test.skip=true   # build the Toolbox product (from repo root)
mvn verify                           # build + run tests
```
Distributables (per-OS zips): `toolbox/org.lamport.tla.toolbox.product.product/target/products/`. Requires **JDK 11 exactly** (newer JDKs break the build — tlaplus/tlaplus#1162), Ant 1.9.8+, Maven 3.9.7+, Git. UI tests need a display → CI runs `xvfb-run mvn ... verify` on ubuntu.

## Develop in Eclipse (Oomph)
`general/ide/README.md` + `TLA.setup` drive an Oomph setup: install the Oomph Installer, pick "Eclipse Platform" (pinned to 2020-12 if newer fails), select the "TLA+" GitHub project, let it provision, then open `.product.product` and launch. ⚠ Running Ant from the CLI while Eclipse is open can cause phantom compile errors — run Ant inside Eclipse or Refresh the project. Steps in the reference.

## Known limitations
Unmaintained (prefer VS Code); JDK pinned to 11 for the build; platform-specific packaging quirks.

## Validation checklist
1. `mvn install -Dmaven.test.skip=true` (JDK 11) from a clean state.
2. Confirm zips in `.../product.product/target/products/`.
3. For UI tests, reproduce CI with `xvfb-run mvn ... verify`.

## References (local)
- `references/plugins-and-build.md` — plugin/feature inventory, Tycho build, CI, Oomph steps
- `toolbox/org.lamport.tla.toolbox.product.product/org.lamport.tla.toolbox.product.product.product`
- `toolbox/*/{pom.xml,feature.xml,plugin.xml,MANIFEST.MF}`
- `general/ide/README.md`, `general/ide/TLA.setup`
- `DEVELOPING.md` (Toolbox + Eclipse sections), `.github/workflows/{pr,main}.yml`, root `pom.xml`
