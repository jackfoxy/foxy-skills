# Grammar, Parser Files, XML Schema & Corpus

## Grammar → generated parser
`javacc/tla+.jj` (~4400 lines) is the JavaCC grammar — the authoritative TLA+ syntax. The `generate` Ant target runs JavaCC over it to produce parser Java in `src/tla2sany/parser/`, runs `jjdoc` to `javacc/tla+.html`, then normalizes line endings to LF (`fixcrlf`):
```bash
ant -f customBuild.xml generate     # regenerate parser (uses lib/javacc-4.0.jar)
```
`compile` depends on `clean, generate`, so a plain build regenerates too. **CI enforces sync** (`pr.yml`): runs `generate` then fails if `git status` is dirty — committed generated code must match the grammar (Windows runners force `core.autocrlf input` due to the LF normalization).

The parser is **not** purely generated: hand-written support handles operator precedence/associativity (`parser/Operators.java`, `OperatorStack.java`, `OSelement.java`) and richer error reporting (`ParseError(s)`, `ParseExceptionExtended`). Syntax tree: `parser/SyntaxTreeNode.java`, `st/`.

## XML AST export
```bash
java -cp dist/tla2tools.jar tla2sany.xml.XMLExporter MySpec.tla         # AST as XML on stdout
java -cp dist/tla2tools.jar tla2sany.xml.XMLExporter -I dir MySpec.tla  # add module search path
```
Emits `<modules><RootModule>…</RootModule><context>…</context>` with `<UserDefinedOpKind>`, `<location>` (line/column/filename), `<level>`, `<uniquename>`, etc. — the semantic graph, not just syntax. Format defined by `src/tla2sany/xml/sany.xsd`; classes implement `XMLExportable`. Supported path for non-Java tooling (per `USE.md`). Validate exports against the schema with `xmllint --schema sany.xsd`.

## Syntax conformance corpus
`test/tla2sany/corpus/*.txt` is a tree-sitter-style corpus: each case is a header (`====|||`), a `---- MODULE Test ----` snippet, a separator (`----|||`), and the expected s-expression parse tree. Example (`case.txt`):
```
=============|||
Basic CASE
=============|||
---- MODULE Test ----
op == CASE 1 -> 2 [] 3 -> 4 [] OTHER -> 5
====
--------------|||
(source_file (module (header_line) (identifier) (header_line)
  (operator_definition (identifier) (def_eq)
    (case (case_arm (nat_number) (case_arrow) (nat_number)) ...))
(double_line)))
```
Driven by `test/tla2sany/parser/TlaPlusSyntaxCorpusTests.java`. Files: `assume`, `case`, `conjlist`, `disjlist`, `except`, `expressions`, `fairness`, `functions`, `if_then_else`, … Add a case to assert a construct parses (or fails) into a specific AST shape.

## Run parser / XML tests
```bash
ant -f customBuild.xml test-set -Dtest.testcases="tla2sany/parser/TlaPlusSyntaxCorpusTests.java"
ant -f customBuild.xml test-set -Dtest.testcases="tla2sany/parser/*"
ant -f customBuild.xml test-set -Dtest.testcases="tla2sany/xml/*"
```
