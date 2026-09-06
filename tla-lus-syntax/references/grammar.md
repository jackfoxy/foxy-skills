# The Grammar `%tla-lus` Accepts

`desk/doc/tla-bnf.md` is the authoritative statement: the grammar accepted by
`desk/lib/syntax.hoon`, traceable production by production to `javacc/tla+.jj`
at the pinned upstream commit. It is **drift-protected** — every `### G-…`
heading in that file must match an entry in `grammar-manifest:syntax`, and the
generated test `desk/tests/lib/bnf.hoon` (from `tools/gen-bnf-manifest.py`)
fails on a mismatch in either direction.

**Verdict parity is complete**: accept/reject matches SANY on all 261
syntax-conformance corpus cases, and accepted trees match node-for-node.
Error-message text is byte-exact too (see `tla-lus-debugging`).

## Productions

The manifest names 35 productions. Grouped:

| Group | Productions |
|---|---|
| Module frame | `G-module`, `G-begin-module`, `G-extends`, `G-body` |
| Declarations | `G-variable-declaration`, `G-param-declaration`, `G-ident-decl`, `G-op-decls`, `G-recursive` |
| Definitions | `G-operator-definition`, `G-function-definition`, `G-module-definition`, `G-instance` |
| Assertions | `G-assumption`, `G-theorem`, `G-use-or-hide` |
| Expressions | `G-expression`, `G-junctions`, `G-general-id`, `G-op-application`, `G-atoms`, `G-action-expr` |
| Control | `G-if-then-else`, `G-case`, `G-let-in` |
| Binding | `G-quantifiers`, `G-lambda`, `G-fairness` |
| Data | `G-sets`, `G-records-functions`, `G-except` |
| Misc | `G-label`, `G-proof`, `G-proof-step`, `G-assume-prove` |

Proof syntax **parses** (`G-proof`, `G-proof-step`, `G-assume-prove`) — there
is no TLAPS here, but a module carrying proof steps is accepted rather than
rejected, exactly as SANY does.

## Lexical conventions

From `desk/lib/lexer.hoon` (tla+.jj lexical states, lines 939–1402):

- Identifiers, including `@`, `W_`-style names, and the number sets `ℕ ℤ ℝ`.
- Numbers: decimal, and `\b` / `\o` / `\h` based literals.
- Strings with `\n \t \r \f \\ \"` escapes.
- Nested `(* *)` block comments and `\*` line comments, with their specials
  preserved.
- Module delimiter runs `----+` and `====+`.
- Proof-step lexemes `<digits|+|*>label[.dots]`, canonicalized exactly as
  SANY's `correctedStepNum` (`<*>`/`<+>` to their level, leading zeros
  dropped).
- Junction tokens, and every ASCII **and Unicode** operator spelling.

Two position rules that bite: **CRLF/LF never changes reported positions**, and
**tabs advance the column to the next multiple of eight**. Positions are
1-indexed with SANY semantics, and a `span` is inclusive.

Context-sensitive retagging, faithfully reproduced:

- binder positions retag `\in` to `t-in`;
- `EXCEPT` assignments retag `=` to `t-equal`;
- record-field keywords may be retagged to identifiers.

## Operator table and precedence mechanics

`tla-bnf.md` §"Operator table" carries the canonical table from
`Operators.java:130-234` — lexeme, low precedence, high precedence,
associativity, fixity — as the port implements it. The reduction rule is the
one SANY uses:

```
succ(L,R) = L.lo > R.hi        reduce
prec(L,R) = L.hi < R.lo        shift
neither, without matching associativity  =>  precedence conflict
```

That is why precedence is a **range**, not a number, and why an unparenthesized
mix of two operators with overlapping ranges is an *error* rather than an
arbitrary parse. Representative entries:

| lexeme | lo | hi | assoc | fix |
|---|---|---|---|---|
| `.` | 170 | 170 | left | infix |
| `[` | 160 | 160 | left | postfix |
| `'` | 150 | 150 | none | postfix |
| `^+` `^*` `^#` | 150 | 150 | none | postfix |
| `^` | 140 | 140 | none | infix |
| `/` `*` | 130 | 130 | none / left | infix |
| `-.` (unary minus) | 120 | 120 | none | prefix |
| `-` | 110 | 110 | left | infix |
| `+` | 100 | 100 | left | infix |
| `SUBSET` `UNION` `DOMAIN` | 100 | 130 | none | prefix |
| `=` `/=` `\in` `\subseteq` | 50 | 50 | none | infix |
| `\cdot` | 50 | 140 | left | infix |
| `[]` `<>` `ENABLED` `UNCHANGED` | 40 | 150 | none | prefix |
| `\lnot` | 40 | 40 | left | prefix |
| `\land` `\lor` | 30 | 30 | left | infix |
| `~>` `\equiv` `-+->` | 20 | 20 | none | infix |
| `=>` | 10 | 10 | none | infix |

**No operator is right-associative.** Parenthesize mixed operators freely.

## Layout hazards that change the parse

- Bulleted `/\` and `\/` lists are delimited by **column alignment**. A
  misaligned item is a different parse or an `Item at <loc> is not properly
  indented` error.
- **Never use tabs.** They advance columns to multiples of eight, which is
  almost never what the alignment looks like.
- `CHOOSE`, quantifiers, `IF`, `CASE` and `LET` extend as far right as their
  delimiters allow.
- Function application binds tightly — parenthesize a nontrivial subscript in
  `[A]_e`, `<<A>>_e`, `WF_e`, `SF_e`.
- A label placed where it changes the parse is rejected: `Removing label at
  <loc> would change expression parsing.`

## One approved divergence in the parser

**Module-body LOOKAHEAD recovery points.** SANY's module body uses JavaCC
syntactic LOOKAHEAD to decide whether a unit starts; when a would-be unit fails
to parse as a whole, SANY rejects it *before* entering the production and
unwinds to the module-body choice, reporting `Was expecting "==== or more
Module body"` at an arbitrary recovery point. The port parses the unit greedily
and reports the failure where it actually occurs. **The accept/reject verdict is
identical**; only the recovery position and message differ on already-rejected
input.
