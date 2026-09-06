# Chapter 15 — The Syntax of TLA⁺

Source: [SpecifyingSystems-21-07-04.pdf](~/eBooks/TLA+/SpecifyingSystems-21-07-04.pdf) (Leslie Lamport, *Specifying Systems*), pp. 275–290 (with the Part IV reference tables 1–8 on pp. 267–273).

The opening chapter of Part IV (The TLA⁺ Language), which describes `TLA⁺` in detail as a reference manual. This chapter specifies the **syntax** of the ASCII version of `TLA⁺` (the only version that exists); Chapters 16–17 give the semantics, Chapter 18 the standard modules. It uses "syntax" in the *computer scientist's* sense (well-formedness, ignoring whether identifiers are defined) — the mathematician's "semantic" conditions are deferred to Chs. 16–17. Two levels: a **simple BNF grammar** (§15.1) that ignores precedence/indentation/comments, plus **informal rules** (§15.2) filling in those aspects, then how characters become lexemes (§15.3).

## Part IV Reference Tables (pp. 267–273)

A tiny reference manual preceding the chapter:
- **Tables 1–4** — all built-in operators: constant operators (logic, sets, functions, records, tuples, strings/numbers), miscellaneous constructs (`IF`/`CASE`/`LET`, `∧`/`∨` lists), action operators (`e'`, `[A]_e`, `⟨A⟩_e`, `ENABLED`, `UNCHANGED`, `A·B`), temporal operators (`□`, `◇`, `WF`/`SF`, `⤳`, `⇉`, `∃`/`∀`).
- **Table 5** — user-definable operator symbols (infix/postfix/prefix), flagging which are already used by standard modules.
- **Table 6** — operator **precedence ranges** (§15.2.1); relative precedence is unspecified where ranges overlap; `(a)` marks left-associative operators.
- **Table 7** — operators defined by each standard module.
- **Table 8** — **ASCII representations** of typeset symbols (e.g. `⪯` = `\preceq`, `□` = `[]`, `∈` = `\in`).

## 15.1 The Simple Grammar

- The simple grammar is written in BNF as `TLA⁺` module **`TLAPlusGrammar`** (`EXTENDS Naturals, Sequences, BNFGrammars` — using the BNF operators of §11.1.4). It's the *smallest* grammar satisfying its productions (`LeastGrammar(P)`).
- Defines lexeme sets: **`ReservedWord`** (keywords that can't be identifiers — `ASSUME`, `THEOREM`, `LET`, etc.; note `BOOLEAN`/`TRUE`/`FALSE`/`STRING` are predefined identifiers, not reserved), **`Letter`**, **`Numeral`**, **`NameChar`**; tokens **`Name`** (letters/digits/`_`, ≥1 letter, not beginning `WF_`/`SF_`), **`Identifier`** (a `Name` that isn't reserved), **`IdentifierOrTuple`**, **`Number`** (decimal `63`, `63.00`, binary `\b`, octal `\o`, hex `\h`), **`String`**, and the operator-token sets **`PrefixOp`**, **`InfixOp`**, **`PostfixOp`**.
- The productions (`G.Module`, `G.Unit`, `G.VariableDeclaration`, `G.ConstantDeclaration`, `G.OpDecl`, `G.OperatorDefinition`, `G.FunctionDefinition`, `G.Instance`, `G.Substitution`, `G.Expression`, etc.) define modules, declarations, definitions, `INSTANCE`/`WITH` substitution, `ASSUME`/`AXIOM`/`THEOREM`, and the full grammar of expressions (function application, records, tuples, `\X`, `EXCEPT`, `WF`/`SF`, `IF`/`CASE`/`LET`, `∧`/`∨` lists, `@` usable only in an `EXCEPT`).

## 15.2 The Complete Grammar

Fills in what the BNF ignores.

### 15.2.1 Precedence and Associativity
- Each operator's precedence is a **range** (Table 6). Higher-precedence operators bind tighter (`a+b*c` = `a+(b*c)`; `a+b'` = `a+(b')`). `−` is left-associative (`a−b−c` = `(a−b)−c`); no `TLA⁺` operator is right-associative.
- An expression is **illegal** if two operators' precedence ranges *overlap* and they aren't two instances of the same associative operator (e.g. `a+b*c' % d` is illegal because `+` (10–10) and `%` (10–11) overlap). Philosophy: **better to require parentheses than to risk misreading** — even `a*b/c` is illegal. Use parentheses freely for clarity.
- **Additional precedence rules:** function application has range 16–16 (higher than everything except `.`); Cartesian product `×` acts like an associative infix op (range 10–13) but is really part of a special construct — `A×B×C` (triples) ≠ `(A×B)×C` ≠ `A×(B×C)` (pairs).
- **Undelimited constructs** (`CHOOSE`, `IF/THEN/ELSE`, `CASE`, `LET/IN`, quantifiers) act as lowest-precedence prefix operators and extend as far as possible — ended only by the next module unit, an unmatched right delimiter, one of `THEN`/`ELSE`/`IN`/`,`/`:`/`→`, the `CASE`-separator `□`, or a `∧`/`∨` at/left of a prefixing bullet. Absence of a terminating `END` reduces clutter but sometimes forces parentheses.
- **Subscripts** (`[A]_e`, `⟨A⟩_e`, `WF_e`, `SF_e`) are written with `_`; parenthesize the subscript except when it's a `GeneralIdentifier` or a bracketed/braced expression. `[A]_(f[x])` reads better than `[A]_f[x]`.

### 15.2.2 Alignment
- The most novel syntactic feature: **aligned conjunction/disjunction lists**. A conjunction list begins with `/\` in column `c`; a conjunct is ended by another `/\` in column `c` (next conjunct), any nonspace char in/left of column `c`, a matching right delimiter, or the next module unit.
- Indentation properly delimits (e.g. an `IF/THEN/ELSE` inside a conjunct). **You can't use parentheses to circumvent the indentation rules.** The notation is robust to being off by a space, but misalignment can silently turn `/\` into an infix operator.
- **Never use tab characters** — a tab equals one-or-more spaces (occupying ≥1 column), with no guarantee beyond identical leading whitespace sequences occupying the same columns.

### 15.2.3 Comments
- Two kinds: **delimited** `(* ... *)` (may nest, properly matched) and **end-of-line** `\* ... ⟨LF⟩`. A comment may appear between any two lexemes. Multiple adjacent comments (e.g. a box of `(***...***)` lines) are grammatically distinct but read as one; TLATeX supports this convention (§13.4).

### 15.2.4 Temporal Formulas
- The BNF treats `□`/`◇` as plain prefix operators, but §8.1 restrictions make some formulas illegal (`□(x'=x+1)` is not legal). Determining if a temporal formula is well-formed requires first expanding all defined operators (§17.4). The precise rules are **of academic interest only** (temporal operators are rarely used in specs, and new ones are seldom defined).

### 15.2.5 Two Anomalies
- Two unlikely ambiguities with *ad hoc* resolutions:
  1. `−` is both infix (`2−2`) and prefix (`2+−2`). When an operator appears **alone** (as a higher-order-operator argument `HOp(+, −)`, or in an `INSTANCE ... WITH Minus <- −` substitution, or defining prefix `−`), you must type `-.` for the prefix operator. In ordinary expressions just type `-` for both.
  2. `{x ∈ S : y ∈ T}` could mean a subset of `S` or a subset of `BOOLEAN` — it is interpreted as **a subset of `S`** (the first form).

## 15.3 The Lexemes of TLA⁺

- Completes the syntax definition: how a character sequence becomes a positioned lexeme sequence (syntactic correctness depends on both the lexemes *and* their row/column positions, due to alignment).
- All characters **before** the module are ignored (without affecting positions). A module begins with ≥4 dashes, optional spaces, then `MODULE`. The rest is lexed by repeatedly: **the next lexeme begins at the next non-comment text char and is the longest legal `TLA⁺` lexeme** (error if none), until the `==...==` end token.
- Space, tab, and end-of-line are **not** text characters (form-feed etc. undefined — avoid). The `Name` restriction excluding strings that *begin with* (but aren't entirely) `WF_`/`SF_` is what makes `WF_x(A)` lex into `WF_`, `x`, `(`, `A`, `)` = `WF_x(A)`, rather than being ambiguous with a record field like `r.a+b`.

---
*Next: Chapter 16 — The Operators of TLA⁺.*
