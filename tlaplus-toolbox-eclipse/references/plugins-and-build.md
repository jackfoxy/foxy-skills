# Toolbox: Plugin Architecture, Tycho Build & CI

## Architecture (Eclipse RCP / OSGi, ~30 `toolbox/org.lamport.tla.toolbox.*` dirs)
- **Plugins (bundles):** `org.lamport.tla.toolbox` (core), `.editor.basic`, `.tool.tlc`, `.tool.tlc.ui`, `.tool.tla2tex`, `.tool.prover`, `.doc`, `.jclouds`, `.jnlp`, `.rss` — each has `plugin.xml` + `MANIFEST.MF` declaring OSGi dependencies and extension points.
- **Features:** `.feature.base`, `.feature.editor`, `.feature.tlc`, `.feature.tla2tex`, `.feature.prover`, `.feature.standalone`, `.feature.jnlp`, `.feature.jclouds`, `.feature.help`, `.feature.uitest` — `feature.xml` groups plugins for installation.
- **Product / packaging:** `.product.product` (the `.product` launcher definition), `.product.standalone`, `.p2repository` (update site), `.jnlp`.
- **Tests:** `.test`, `.tool.tlc.test`, `.tool.tlc.ui.test`, and `*.uitest` (headless UI tests needing a display).

Product definition file: `toolbox/org.lamport.tla.toolbox.product.product/org.lamport.tla.toolbox.product.product.product`. It embeds `tla2tools.jar` for command-line use in the product root.

## Build (Maven/Tycho)
From repo root (the root `pom.xml` aggregates toolbox bundles via Tycho):
```bash
mvn install -Dmaven.test.skip=true   # build the Toolbox product
mvn verify                           # build + run tests
```
Distributables (per-OS zips): `toolbox/org.lamport.tla.toolbox.product.product/target/products/`. Requires **JDK 11 exactly** (newer JDKs likely break the build — tlaplus/tlaplus#1162), Ant 1.9.8+, Maven 3.9.7+, Git.

## CI (`.github/workflows/pr.yml`, `main.yml`)
*Eclipse Toolbox Build & Test* job:
- ubuntu: `xvfb-run mvn -Dtest.skip=true -Dmaven.test.failure.ignore=true ... verify` (UI tests need a virtual framebuffer → **xvfb-run**).
- macOS: `mvn -Dmaven.test.skip=true` (also produces Windows + Linux zips, uploaded as `TLAToolboxes`).
- Common flags: `-Dtycho.disableP2Mirrors=true -fae -B verify --file pom.xml`. CI uses JDK 17 for the build step; local interactive dev wants JDK 11.

## Develop in Eclipse (Oomph)
`general/ide/README.md` + `general/ide/TLA.setup`:
1. Install the Oomph Eclipse Installer; Advanced Mode.
2. Pick "Eclipse Platform" (README pins **2020-12** if newer fails).
3. Select the "TLA+" GitHub project (master stream), anonymous (read-only) or SSH.
4. Let Oomph clone & provision; open `.product.product` and hit the green launch arrow to run the Toolbox from source.

For developing just the tools in Eclipse: "Eclipse IDE for RCP and RAP Developers" edition, open `tlatools/org.lamport.tlatools`. ⚠ Running Ant from the CLI while Eclipse is open can cause phantom compile errors — run Ant from within Eclipse (Window > Show View > Ant), or right-click project > Refresh.

## Known limitations
- Unmaintained; prefer the VS Code extension for new work.
- JDK pinned to 11 for the build; Oomph README references older JDK/Eclipse versions.
- Platform-specific packaging quirks (per-OS zips, name clashes worked around in CI).
