# TLA+ Tools Internals

## Source Layout

```text
tlatools/org.lamport.tlatools/src/
|-- tla2sany/
|   |-- SANY.java
|   |-- drivers/
|   |-- parser/
|   |-- semantic/
|   |-- st/
|   |-- xml/
|   `-- StandardModules/
|-- tlc2/
|   |-- TLC.java
|   |-- tool/
|   |-- value/
|   |-- util/
|   |-- output/
|   |-- module/
|   `-- overrides/
|-- pcal/
|-- tla2tex/
`-- util/
```

## SANY Pipeline

- `SANY.java`
- `drivers/`
- `parser/`
- `semantic/`
- `st/`
- `xml/`
- `javacc/tla+.jj`

Flow:

```text
tla2sany.SANY.main()
  -> tla2sany.drivers.SANY.SANYmain()
  -> JavaCC parser / hand parser support
  -> symbol table
  -> semantic analysis and level checking
  -> semantic AST / SpecObj
  -> optional XML export
```

SANY is process-safe but not thread-safe when used as a Java library.

Programmatic use centers on `tla2sany.drivers.SANY.parse()` and `SpecObj`.

## TLC Architecture

- `TLC.java`
- `tool/`: `ModelChecker`, `Simulator`, `DFIDModelChecker`, `TLCState`, spec evaluation.
- `tool/impl/`: `FastTool`, `DebugTool`, parameterized spec support.
- `value/` and `value/impl/`: value representation such as booleans, ints, tuples, functions, sets.
- `util/`: state writers and utilities.
- `model/`: model/config support.
- `output/`: `EC.java` error codes and `MP.java` message printer.
- `module/`, `overrides/`: Java overrides for TLA+ modules.

Flow:

```text
tlc2.TLC.main()
  -> parse CLI args
  -> choose ModelChecker / DFIDModelChecker / Simulator
  -> initialize Tool from SpecObj
  -> explore states or simulate traces
  -> print trace/messages through MP on violation
```

TLC holds global static state, including output and interned/fingerprint-related state. Do not run TLC twice in one JVM process unless classes are reloaded.

## Module Override Mechanism

Use `$tla-plus-stdlib` for the full workflow. Internals anchors:

- `tlc2.tool.impl.TLARegistry` maps TLA+ symbols to Java method names.
- `tlc2.module.<Module>` overrides `StandardModules/<Module>.tla`.
- infix/symbolic operators use `TLARegistry.put(...)`.
- mismatch diagnostics are in `EC.java` / `MP.java` around override-related codes.

## PlusCal Internals

- `trans.java`
- `ParseAlgorithm.java`
- `PcalTranslate.java`
- `PCalTLAGenerator.java`
- `AST.tla`, `PlusCal.tla`

Flow:

```text
pcal.trans.main()
  -> read .tla file
  -> locate --algorithm block in comment
  -> ParseAlgorithm: parse PlusCal to AST
  -> rename/fix conflicting identifiers
  -> generate TLA+ actions, Init, Next, Spec support
  -> write between BEGIN/END TRANSLATION markers
  -> update checksums
```

## Messages and Error Codes

When adding a user-facing error:

1. Add a constant to `tlc2/output/EC.java`.
2. Add a message case in `tlc2/output/MP.java`.
3. Use `Assert.fail(...)`, `MP.printError(...)`, or the existing local pattern.
4. Add tests that assert the code/message behavior where stable.

Keep message text stable if tests or external tooling parse it.

## Capturing Tool Output in Tests

Use `ToolIO` and `TestPrintStream` patterns from existing tests:

```java
ToolIO.setMode(ToolIO.TOOL);
ToolIO.reset();
String[] messages = ToolIO.getAllMessages();
```

## TLATeX

`src/tla2tex/` converts TLA+ to LaTeX. Entry point: `tla2tex.TLA.main()`. This is usually lower priority than SANY, TLC, PlusCal, and Toolbox work.

## Testing

- Parser/semantic/XML: `test/tla2sany/`
- TLC: `test/tlc2/`
- PlusCal: `test/pcal/`
- Spec fixtures: `test-model/`

Use `$tla-plus-build-workflow` for exact `test-set` commands.

## Invariants

- Reproduce through the public CLI first, then trace inward to implementation stage.
- SANY level checking gates TLC.
- Generated parser files are regenerated from `javacc/tla+.jj`; do not hand-edit them as source.
- TLC global static state makes same-JVM reruns unsafe.
- Override names are case-sensitive and must match the TLA+ surface.
- `test-model/` and fixtures are examples/test surfaces, not general design authority.
