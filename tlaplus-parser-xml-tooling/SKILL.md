---
name: tlaplus-parser-xml-tooling
description: The TLA+ parser front-end - the JavaCC grammar (tla+.jj), the generated + hand-written parser, XML AST export (XMLExporter + sany.xsd), and the syntax-conformance corpus tests. Use when regenerating/modifying the parser, extending syntax, consuming the AST via XML, fixing parser bugs, or maintaining sany.xsd and corpus tests. For the broader SANY/TLC internals see tlaplus-tools-internals.
user-invocable: true
disable-model-invocation: false
---

# Parser, Grammar & XML AST Tooling

Specialized front-end skill. Broader pipeline: [[tlaplus-tools-internals]]; build commands: [[tlaplus-build-workflow]].

## Grammar is the source of truth
`javacc/tla+.jj` (~4400 lines) is the authoritative TLA+ syntax. Regenerate the parser from it:
```bash
ant -f customBuild.xml generate     # JavaCC over tla+.jj -> src/tla2sany/parser/ ; jjdoc -> tla+.html ; LF-normalize
```
`compile` depends on `clean, generate`. **CI enforces sync**: `pr.yml` runs `generate` then fails if `git status` is dirty — never hand-edit generated parser files; change `tla+.jj` and regenerate, committing both in LF. The parser also has hand-written precedence/associativity (`Operators.java`, `OperatorStack.java`) and error reporting.

## XML AST export (validated)
```bash
java -cp dist/tla2tools.jar tla2sany.xml.XMLExporter MySpec.tla         # AST as XML on stdout
java -cp dist/tla2tools.jar tla2sany.xml.XMLExporter -I dir MySpec.tla  # add module search path
```
Emits `<modules><RootModule>…</RootModule><context>…</context>` with `<UserDefinedOpKind>`, `<location>`, `<level>`, `<uniquename>` — the semantic graph. Format defined by `src/tla2sany/xml/sany.xsd`; the supported path for non-Java tooling. Validate with `xmllint --schema sany.xsd`.

## Conformance corpus
`test/tla2sany/corpus/*.txt` — tree-sitter-style cases pairing a module snippet with its expected s-expression AST, driven by `TlaPlusSyntaxCorpusTests.java`. Add a case to assert a construct parses (or fails) into a specific shape. The corpus format, file list, and XMLExporter output detail are in `references/grammar-corpus-xml.md`.

## Run tests
```bash
ant -f customBuild.xml test-set -Dtest.testcases="tla2sany/parser/*"
ant -f customBuild.xml test-set -Dtest.testcases="tla2sany/xml/*"
```

## Workflows
- **Modify syntax:** edit `tla+.jj` → `ant generate compile` → run `tla2sany/parser/*` + corpus tests → commit grammar **and** regenerated parser together.
- **Add a corpus case:** add to `corpus/*.txt`; run `TlaPlusSyntaxCorpusTests`.
- **Update XML format:** change exporter + `sany.xsd` together; re-validate sample exports; run `tla2sany/xml/*`.

## Validation
After a grammar edit: regenerate, confirm corpus + a hand-written syntax test pass/fail as expected, export a module to XML and validate it against `sany.xsd`, and confirm `git status` is clean (no generated-code drift).

## References (local)
- `references/grammar-corpus-xml.md` — grammar/generate detail, XML format, corpus format, test globs
- `javacc/tla+.jj`, `javacc/README`
- `src/tla2sany/parser/` (`Operators.java`, `OperatorStack.java`, `SyntaxTreeNode.java`), `src/tla2sany/st/`
- `src/tla2sany/xml/` (`XMLExporter.java`, `sany.xsd`, `XMLExportable.java`)
- `test/tla2sany/corpus/*.txt`, `test/tla2sany/parser/TlaPlusSyntaxCorpusTests.java`, `test/tla2sany/xml/`
- `customBuild.xml` (`generate`), `.github/workflows/pr.yml` (grammar sync check)
