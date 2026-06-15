# Parser and XML Tooling

## Source of Truth

- Grammar: `tlatools/org.lamport.tlatools/javacc/tla+.jj`
- Parser code: `src/tla2sany/parser/`
- XML export: `src/tla2sany/xml/XMLExporter.java`
- Schema: `src/tla2sany/xml/sany.xsd`
- Tests: `test/tla2sany/parser/`, `test/tla2sany/xml/`, `test/tla2sany/corpus/`

`tla+.jj` is the authoritative grammar for TLA+ syntax. Generated parser files under `src/tla2sany/parser/` are committed, but they are outputs.

Generated files include:

- `TLAplusParser.java`
- `TLAplusParserTokenManager.java`
- `TLAplusParserConstants.java`
- `Token.java`
- `TokenMgrError.java`
- `SimpleCharStream.java`
- `ParseException.java`

## Regeneration

```bash
cd /mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools
ant -f customBuild.xml generate
git status --porcelain=v1
```

The `generate` target runs JavaCC on `javacc/tla+.jj`, emits parser Java files, generates grammar docs, and normalizes line endings. If `tla+.jj` changes, commit regenerated parser files with it.

## Grammar/Code Sync

CI regenerates the parser and checks for diffs. If sync fails, run `ant -f customBuild.xml generate` locally and inspect/commit the generated files.

## XML AST Export

```bash
java -cp dist/tla2tools.jar tla2sany.xml.XMLExporter Module.tla
java -cp dist/tla2tools.jar tla2sany.xml.XMLExporter -I path/to/modules Module.tla
```

Non-Java tools should capture stdout and parse XML. The schema is `src/tla2sany/xml/sany.xsd`.

Optional schema check when `xmllint` is available:

```bash
java -cp dist/tla2tools.jar tla2sany.xml.XMLExporter Module.tla > out.xml
xmllint --schema src/tla2sany/xml/sany.xsd out.xml
```

## Key XML Classes

| Class/file | Role |
|---|---|
| `tla2sany.xml.XMLExporter` | entry point; runs SANY and walks AST |
| `tla2sany.xml.XMLExportable` | interface for exportable AST nodes |
| `tla2sany.xml.SymbolContext` | symbol/export context |
| `tla2sany/xml/sany.xsd` | XML schema |

## Tests

Syntax corpus:

```bash
cd /mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools
ant -f customBuild.xml test-set -Dtest.testcases="tla2sany/parser/TlaPlusSyntaxCorpusTests.java"
```

Parser suite:

```bash
ant -f customBuild.xml test-set -Dtest.testcases="tla2sany/parser/*"
```

XML exporter tests:

```bash
ant -f customBuild.xml test-set -Dtest.testcases="tla2sany/xml/*"
```

Broader SANY tests:

```bash
ant -f customBuild.xml test-set -Dtest.testcases="tla2sany/*"
```

## Adding a Syntax Feature

1. Edit `javacc/tla+.jj`.
2. Run `ant -f customBuild.xml generate`.
3. If semantic handling is needed, update `src/tla2sany/semantic/`.
4. If XML output changes, update `XMLExportable` behavior and `sany.xsd` as needed.
5. Add valid and invalid syntax corpus cases.
6. Add XML tests if AST/XML shape changes.
7. Run compile and targeted tests.
8. Verify generated parser files are intentionally changed and in sync.

## Hand-Written Parser Extensions

`src/tla2sany/parser/` contains both generated and hand-written files. Do not edit generated files directly. Hand-written support for operators, error handling, or associativity can be edited, but must remain compatible with regeneration from `tla+.jj`.

## Invariants

Generated parser Java is not source authority. Cite `tla+.jj`, hand parser support, or schema.

Grammar and generated parser files must remain in sync. Parser/XML changes need corpus or XML tests unless the change is strictly mechanical.
