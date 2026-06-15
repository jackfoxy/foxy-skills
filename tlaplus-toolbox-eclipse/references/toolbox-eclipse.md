# Toolbox Eclipse/RCP

Status: currently unmaintained. Use the VS Code extension for new user-facing TLA+ GUI work. Use this reference for Toolbox internals, packaging, tests, or CI failures.

Primary paths:

- `toolbox/org.lamport.tla.toolbox.*`
- `toolbox/org.lamport.tla.toolbox.product.product/`
- `toolbox/org.lamport.tla.toolbox.p2repository/`
- `general/ide/README.md`
- root `pom.xml`
- `.github/workflows/pr.yml`, `main.yml`

## Structure

```text
toolbox/
|-- org.lamport.tla.toolbox/
|-- org.lamport.tla.toolbox.editor.basic/
|-- org.lamport.tla.toolbox.feature.*/
|-- org.lamport.tla.toolbox.product.product/
|-- org.lamport.tla.toolbox.jclouds/
|-- org.lamport.tla.toolbox.feature.uitest/
|-- org.lamport.tla.toolbox.doc/
|-- org.lamport.tla.toolbox.rss/
`-- org.lamport.tla.toolbox.p2repository/
```

Each bundle generally has its own `pom.xml`; plugins use `plugin.xml`, features use `feature.xml`, and product packaging centers on the `.product` file.

## JDK and Build Constraints

`DEVELOPING.md` says Toolbox needs JDK 11 and newer JDKs may fail because of Eclipse/Tycho constraints. CI workflow jobs may use JDK 17; when reporting failures, always include local JDK, Maven, OS, and exact command.

## Build Commands

From repo root:

```bash
mvn install -Dmaven.test.skip=true
mvn verify
```

Linux/headless UI tests:

```bash
xvfb-run mvn \
  -Dtest.skip=true \
  -Dmaven.test.failure.ignore=true \
  -Dtycho.disableP2Mirrors=true \
  -fae -B verify --file pom.xml
```

macOS CI-style build often skips tests:

```bash
mvn -Dmaven.test.skip=true \
  -Dtycho.disableP2Mirrors=true \
  -fae -B verify --file pom.xml
```

Distributables appear under:

```text
toolbox/org.lamport.tla.toolbox.product.product/target/products/
```

## CI Mapping

`pr.yml` has a `toolbox-build-and-test` job. Linux uses `xvfb-run mvn ...`; macOS uses Maven with tests skipped. Main/release workflows package products and p2 artifacts.

## Eclipse/Oomph Source Launch

See `general/ide/README.md` and `general/ide/TLA.setup`.

Quick path:

1. Install Eclipse IDE for RCP and RAP Developers.
2. Use Oomph/TLA.setup or import the Toolbox projects manually.
3. Open `toolbox/org.lamport.tla.toolbox.product.product/org.lamport.tla.toolbox.product.product.product`.
4. Launch from the Product editor.

## Key File Types

- `plugin.xml`: OSGi plugin declarations.
- `feature.xml`: Eclipse feature composition.
- `.product`: product definition and launch.
- `pom.xml`: Tycho/Maven bundle descriptor.
- `MANIFEST.MF`: OSGi bundle metadata.
- `target/products`: built distributables.
- p2 repository files: update-site packaging.

## Plugin Modification Workflow

1. Identify the owning `org.lamport.tla.toolbox.*` bundle.
2. Modify Java/resources in that bundle.
3. Update `plugin.xml` for extension points, commands, views, editors, handlers, or dependencies.
4. Update `feature.xml` only when feature composition changes.
5. Build with Maven/Tycho; use `xvfb-run` on Linux for UI tests.
6. Launch from Eclipse product for manual UI validation when behavior changes.

## Nightly and Update Site Caution

`nightly.tlapl.us` and `nightly.tlapl.us/toolboxUpdate/` appear in docs and release workflows. Treat the entire namespace as verify-before-use. Do not embed stale nightly URLs without checking them.

The old `apt-key add` install pattern in docs is deprecated on modern Debian/Ubuntu.

## Known Limitations

- Toolbox is currently unmaintained.
- Prefer VS Code for new user-facing GUI workflows.
- JDK/Tycho/Eclipse versions are fragile.
- UI tests require display support or `xvfb-run` on Linux.
- Cloud TLC / jclouds references can point at old infrastructure.
- Windows Toolbox build is not covered the same way as Linux/macOS in CI.
- Keep Toolbox changes separate from CLI tools unless build/product integration requires both.

## Validation

Report exact Maven command, OS, JDK, Maven version, target product path, p2/product artifacts if relevant, and UI test or manual launch status.
