# TLA+ Language Reference

Use this reference for exact constructs, legality, modules, and semantic distinctions. TLA+ source is ASCII; mathematical glyphs in prose are presentation only.

## Logic, sets, and quantification

Core ASCII forms:

| Meaning | ASCII |
|---|---|
| conjunction, disjunction, negation | `/\`, `\/`, `~` |
| implication, equivalence | `=>`, `<=>` |
| membership, nonmembership | `\in`, `\notin` |
| subset, union, intersection, difference | `\subseteq`, `\cup`, `\cap`, `\` |
| bounded universal/existential | `\A x \in S : P`, `\E x \in S : P` |
| tuple | `<<a, b>>` |
| function constructor | `[x \in S |-> e]` |
| function set | `[S -> T]` |
| record value/type | `[a |-> e]`, `[a : S]` |

Prefer bounded quantification because readers and TLC can reason about explicit finite bounds. Universal quantification over an empty set is true; existential quantification over it is false. A quantifier binds its identifier only in the body, not in its bounding set.

Set forms:

- `{e1, e2}`: enumeration.
- `{x \in S : P}`: subset filter.
- `{E : x \in S}`: image set.
- `UNION S`: union of the sets in `S`.
- `SUBSET S`: power set.

TLA+ is untyped and based on set theory. Syntactically legal expressions can have unspecified values. Guard partial or domain-sensitive expressions so truth does not depend on unspecified cases.

## Functions, records, tuples, and recursion

A function is a value with a set-valued domain. An operator is not a value.

- `DOMAIN f`, `f[x]`, `[S -> T]`, and `[x \in S |-> e]` are function constructs.
- Records are functions with string field names; `r.field` abbreviates `r["field"]`.
- Tuples are functions with domain `1..n`; Cartesian products are not associative.
- Multiple-argument functions use tuple domains: `f[a,b]` abbreviates `f[<<a,b>>]`.
- `EXCEPT` constructs a modified function or record: `[f EXCEPT ![k] = e, ![j].field = v]`.
- `@` is legal only in an `EXCEPT` replacement and denotes the old targeted value.

Recursive function syntax:

```tla
Fact[n \in Nat] == IF n = 0 THEN 1 ELSE n * Fact[n - 1]
```

Its semantics uses `CHOOSE` to select a function satisfying the equation. A syntactically legal recursive definition may fail to determine a function. Establish well-foundedness and uniqueness when reasoning formally. TLA+ has no direct mutually recursive definitions; combine them into fields of one record-valued recursive function when necessary.

Operators may take operators as parameters:

```tla
IsRelationOn(R(_,_), S) == \A x, y \in S : R(x, y) \in BOOLEAN
```

Functions cannot accept operators as values. Use an operator when the domain would be too large to form a set or higher-order application is required.

## Choice and nondeterminism

`CHOOSE x : P` denotes one fixed, arbitrary value satisfying `P`; if none exists its value is unspecified. Equal predicates choose equal values. It is useful for naming a uniquely characterized value or a sentinel outside a set:

```tla
NoValue == CHOOSE v : v \notin Value
```

It is not nondeterministic. Use `x' \in S` or an existentially selected action parameter for per-step nondeterminism.

`IF p THEN a ELSE b` and `CASE p1 -> a [] p2 -> b [] OTHER -> c` are expressions. If multiple `CASE` guards hold, the selected matching arm is unspecified; use mutually exclusive guards when the choice matters.

## Actions and temporal operators

- `e'`: value of state expression `e` in the next state; every variable within `e` is primed.
- `UNCHANGED e == e' = e`.
- `[A]_e == A \/ e' = e`.
- `<<A>>_e == A /\ e' # e`.
- `ENABLED A`: state predicate asserting that an `A` successor exists.
- `A \cdot B`: action composition through an intermediate state; rarely the clearest modeling form.
- `[]F`: always.
- `<>F`: eventually.
- `F ~> G`: leads-to.
- `WF_e(A)`, `SF_e(A)`: weak and strong fairness.

Use subscripts covering all variables whose change makes the action observable. Parenthesize complex subscripts.

## Levels

Every expression has a maximum semantic level:

| Level | Kind | May depend on |
|---|---|---|
| 0 | constant | constants and constant operators |
| 1 | state | unprimed variables and `ENABLED` |
| 2 | action/transition | primed and unprimed state expressions |
| 3 | temporal | behaviors and temporal operators |

Important legality constraints:

- Priming applies only to level 0 or 1 expressions; no double priming.
- `ENABLED` consumes an action-level expression and produces a state predicate.
- `ASSUME` must be level 0.
- Module instantiation may replace a constant only with a constant-level expression and a variable only with a level-0-or-1 expression when the instantiated module is nonconstant.
- Some expressions that parse still fail semantic or level checking.

Do not confuse ordinary existential quantification over a rigid value with temporal existential quantification that hides a flexible variable. The surface glyph is related, but legality and semantics depend on level.

## Modules and scope

```tla
------------------------------ MODULE M ------------------------------
EXTENDS Naturals, Sequences
CONSTANTS S, N
VARIABLES x, y

Op(a) == ...
LOCAL Helper(a) == ...

THEOREM Name == Formula
=============================================================================
```

- Every non-submodule module `M` normally lives in `M.tla`.
- `EXTENDS` must precede other units and imports exported declarations, definitions, assumptions, and theorems.
- Definitions and declarations are visible only after their occurrence.
- A name cannot be redeclared within its scope, including by a nested binder.
- `LOCAL` prevents a definition or instantiation from being exported. It cannot modify a declaration or `EXTENDS`.
- Comments are `(* ... *)`, which may nest, or `\*` to end of line.

`LET ... IN ...` introduces ordered local definitions. Later definitions may use earlier ones. Use it for tightly scoped helpers; use module-level definitions when they carry conceptual meaning or require reuse and testing.

## Instantiation

Instantiation is semantic substitution:

```tla
I == INSTANCE Other
       WITH C <- Expr,
            v <- StateExpr
```

Refer to exported definitions as `I!Op`. All declared parameters of the instantiated module receive explicit or implicit substitutions. Omitted substitutions are name-preserving and require the same name to be in scope.

A parameterized instance supports variable hiding:

```tla
Inner(h) == INSTANCE Internal WITH hidden <- h
Spec == \EE h : Inner(h)!Spec
```

An unnamed `INSTANCE Other WITH ...` imports its definitions directly. Use named instances for multiple instantiations or to avoid collisions.

Substitution is not naive textual replacement. It avoids variable capture and handles implicit binding inside `ENABLED`, action composition, fairness, and guarantee operators. Do not assume substitution distributes through `ENABLED`, `WF`, `SF`, `\cdot`, or the open-system guarantee operator.

## Syntax and layout hazards

- Operator precedence is defined by ranges. Overlapping ranges can make an unparenthesized expression illegal; parenthesize mixed operators freely.
- No operator is right-associative. Some are left-associative; do not infer associativity across different operators.
- Bulleted `/\` and `\/` lists are delimited by column alignment. Misalignment can change the parse.
- Never use tabs in TLA+ source.
- `CHOOSE`, quantifiers, `IF`, `CASE`, and `LET` extend as far right as their delimiters allow.
- Function application binds tightly. Parenthesize a nontrivial subscript in `[A]_e`, `<<A>>_e`, `WF_e`, or `SF_e`.
- The parser reports where no valid continuation exists, which may be later than the actual missing token. Use its residual parse stack and reduce the surrounding expression.

## Semantic review

When explaining or repairing an expression, check in this order:

1. Lexing and module delimiters.
2. Alignment, delimiters, and precedence.
3. Name resolution, scope, arity, and duplicate declarations.
4. Expression level and legal priming.
5. Domain guards and Boolean expectations.
6. Mathematical meaning on all states or steps, not just intended typed states.
7. TLC evaluability, which is narrower than TLA+ legality.
