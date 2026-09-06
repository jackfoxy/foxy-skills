# Chapter 16 — The Operators of TLA⁺

Source: [SpecifyingSystems-21-07-04.pdf](~/eBooks/TLA+/SpecifyingSystems-21-07-04.pdf) (Leslie Lamport, *Specifying Systems*), pp. 291–316.

A reference-manual chapter describing every built-in `TLA⁺` operator, with brief explanations (referencing Part I for detail) plus subtle points, and an optional **Formal Semantics** subsection for each (giving `⟦e⟧`, the mathematical meaning — skippable unless you build tools). It also states the "semantic" well-formedness conditions omitted from the Ch. 15 grammar (e.g. `[a:Nat, a:BOOLEAN]` is illegal). `TLA⁺` is built on **Zermelo-Fränkel set theory** — every value is a set. Operators split into **constant** (§16.1, ordinary math) and **nonconstant** (§16.2, action + temporal, what distinguishes `TLA⁺`).

## 16.1 Constant Operators

### 16.1.1 Boolean Operators
`∧ ∨ ¬ ⇒ ≡`, `TRUE`/`FALSE`, `BOOLEAN ≜ {TRUE,FALSE}`, unbounded/bounded quantifiers (`∀x:p`, `∃x∈S:p`), plus abbreviations (`∀x,y:p`, tuple quantification `∀⟨x,y⟩∈S:p`). Formal semantics takes propositional logic + simple unbounded `∃x:p`/`∀x:p` as primitive and defines the general forms from them.

### 16.1.2 The Choose Operator
`CHOOSE x:p` = some arbitrary `v` making `p` true (completely arbitrary if none exists) — mathematicians' **Hilbert's ε**. Bounded `CHOOSE x∈S:p ≜ CHOOSE x:(x∈S)∧p`. Rules (16.2): `(∃x:P(x)) ≡ P(CHOOSE x:P(x))`, and equal predicates give equal choices, so `CHOOSE x:FALSE` is a fixed (unknown) value — hence `1/0 = 2/0` is deducible (both `= CHOOSE c:FALSE`). To block such deductions define a `Choice(v,P)` operator returning an arbitrary value dependent on `v` when no `x` satisfies `P`. Primitive; a tuple `CHOOSE` reduces to the identifier form.

### 16.1.3 Interpretations of Boolean Operators
Since `TLA⁺` is untyped, `2 ∧ ⟨5⟩` is legal but meaningless — three interpretations:
- **Conservative** — value fully unspecified; ordinary logic laws valid only for Booleans.
- **Liberal** — `2∧⟨5⟩` specified to be *some* Boolean; all logic tautologies valid (e.g. treat every non-Boolean as `FALSE`).
- **Moderate** — in between: only expressions involving `TRUE`/`FALSE` get expected values (`FALSE ⇒ √2 = TRUE`, `FALSE ∧ 2 = FALSE`).
`TLA⁺` semantics asserts the **moderate** rules valid; write specs sensible under it (a tool may use liberal). Conservative doesn't even let you use `f[x]` as a Boolean when `f` is Boolean-valued (write `tnat[n]=TRUE`).

### 16.1.4 Conditional Constructs
`IF p THEN e₁ ELSE e₂`; `CASE p₁→e₁ □ … □ pₙ→eₙ` (+ optional `□ OTHER→e`) = some `eᵢ` with `pᵢ` true (unspecified which if several; unspecified/`OTHER`-value if none). Formal semantics defines both via `CHOOSE`.

### 16.1.5 The Let/In Construct
`LET Δ₁ … Δₙ IN e` = `e` in the context of the definitions; each `Δᵢ` may use the earlier ones. Semantics given later in §17.4.

### 16.1.6 The Operators of Set Theory
`∈ ∉ ∪ ∩ ⊆ \ UNION SUBSET`, constructors `{e₁,…,eₙ}`, `{x∈S:p}`, `{e:x∈S}`, plus `=`/`≠`. Set constructs generalize with tuples/multiple bounds (`{⟨a,b⟩∈Nat×Nat:a>b}`, `{⟨a,b,c⟩:a,b∈Nat,c∈Real}`). Semantics: `∈` primitive; `{x∈S:p}` and `{e:x∈S}` (simple forms) primitive, everything else (`=`, `∪`, `∩`, `⊆`, `\`, `SUBSET`, `UNION`, `{e₁,…,eₙ}`, `{}`) defined by the rules they satisfy. `∪` and `UNION` treated as equally primitive.

### 16.1.7 Functions
`f[v]` (specified only for `v ∈ DOMAIN f`), `DOMAIN f`, `[S→T]`, explicit `[x∈S↦e]`, recursive `fcn[x∈S] ≜ e`, and `EXCEPT`: `[f EXCEPT ![u]=a, ![v]=b]` = `f` modified at `u`,`v`; general clause `![v₁]…[vₙ]=e`; `@` inside a clause = the "original value" `f[u]…`. Multi-argument functions have tuple domains; `f[v₁,…,vₙ]` abbreviates `f[⟨v₁,…,vₙ⟩]`. Semantics takes `f[e]`, `DOMAIN`, `[S→T]`, `[x∈S↦e]` primitive; defines `IsAFcn(f) ≜ f = [x∈DOMAIN f↦f[x]]`; two functions equal iff same domain + same values.

### 16.1.8 Records
`[h₁↦e₁,…,hₙ↦eₙ]`, set of records `[h₁:S₁,…,hₙ:Sₙ]` (legal only if the `hᵢ` distinct), `EXCEPT` with `!.h`, field access `r.h`. A record **is a function** whose domain is a finite set of strings: `r.h ≜ r["h"]`, so `[fo↦7,ba↦8]` = `[x∈{"fo","ba"}↦…]`. Field names are strings of letters/digits/`_` (≥1 letter). Semantics defines record constructs via function constructs.

### 16.1.9 Tuples
`⟨e₁,…,eₙ⟩` is a **function** with domain `1..n`, `⟨…⟩[i]=eᵢ`. Cartesian product `S₁×…×Sₙ` = set of such n-tuples; `×` is **not associative** — `⟨1,2,3⟩`, `⟨⟨1,2⟩,3⟩`, `⟨1,⟨2,3⟩⟩` are unequal (triple vs pairs). The 0-tuple `⟨⟩` is the unique empty-domain function; a 1-tuple `⟨e⟩` differs from `e` (equality unspecified). Sequences (module §18.1) are n-tuples. Semantics defines tuples/products via functions and `Nat`.

### 16.1.10 Strings
A string is a **tuple of characters**: `"abc" = ⟨"abc"[1],"abc"[2],"abc"[3]⟩`. What a character *is* is unspecified, but different characters differ (`"a"[1]≠"A"[1]`). `STRING ≜ Seq(Char)` = set of all strings. Clever `Ascii` operator maps letters to ASCII codes via `CHOOSE`. ASCII-version character set listed; strings are `"`-delimited, so special chars use `\`-escapes (`\"`, `\\`, `\t`, `\n`, `\f`, `\r`) — `\` may appear in a string only as the first char of one of these six pairs.

### 16.1.11 Numbers
A digit sequence `63` = the natural number `6*10+3` (also binary `\b111111`, octal `\o77`, hex `\h3F`/`\H3F`, decimal `3.14159`). **Numbers are predefined**, but `Nat`, `+`, etc. are **not** — you could define `+` so `40+23 ≠ 63` (standard `Naturals`/`Integers`/`Reals` give the usual meaning). Semantics: `Nat`/`Zero`/`Succ` in module `Peano`; `Real` a superset of `Nat` in `ProtoReals`.

## 16.2 Nonconstant Operators

These distinguish `TLA⁺` from ordinary math and require considering operators' **arguments**, so we describe the meaning of whole **basic expressions** (built from `TLA⁺` operators, declared constants, declared variables), not operators in isolation.

### 16.2.1 Basic Constant Expressions
Built only from constant operators + declared constants. A **valid** formula is `TRUE` regardless of the values assigned to its constants (e.g. `(S⊆T) ≡ (S∩T=S)`). Semantics: `⟦c⟧` defined inductively; validity of basic constant formulas taken as the primitive notion.

### 16.2.2 The Meaning of a State Function
A **state** = assignment of values to variables (formally a function from variable names to values; `s⟦x⟧` = `x`'s value in `s`). A **state function** is built from declared variables, constants, constant operators (and `ENABLED`). It maps each state to a constant value. A Boolean state function is a **state predicate**; **valid** iff `TRUE` in every state. Semantics: `s⟦e⟧` defined inductively for ENABLED-free state functions; the "mapping on states" isn't literally a function (no set of all states — Russell's paradox), so a semi-formal exposition is used.

### 16.2.3 Action Operators
A **transition function** is built from state functions using priming `'` (and other action operators); it maps each **step** `s→t` to a value (unprimed `x` = value in `s`, primed `x'` = value in `t`). An **action** is a Boolean transition function; **valid** iff true on every step. Meanings:
- `[A]_e ≜ A ∨ (e'=e)`; `⟨A⟩_e ≜ A ∧ (e'≠e)`
- `ENABLED A` = state function true in `s` iff some `A`-step `s→t` exists
- `UNCHANGED e ≜ e'=e`
- `A·B` = true on `s→t` iff some `u` with `A`-step `s→u` and `B`-step `u→t`.
Semantics defines these on transition functions via existential quantification over states (`∃_state`, using `IsAState`). Worked example: `ENABLED (b∧(y'=y))` reduces to `s⟦b⟧` when `s⟦b⟧` is a Boolean, showing silly expressions only matter where the spec is sensible.

### 16.2.4 Temporal Operators
A temporal formula is true/false for a **behavior** (state sequence). `□F` true for `σ` iff `F` true for `σ` and all suffixes; `□[A]_e` true iff every successive state pair is an `[A]_e` step. All others defined in terms of `□`:
- `◇F ≜ ¬□¬F`
- `WF_e(A) ≜ □◇¬(ENABLED⟨A⟩_e) ∨ □◇⟨A⟩_e`
- `SF_e(A) ≜ ◇□¬(ENABLED⟨A⟩_e) ∨ □◇⟨A⟩_e`
- `F ⤳ G ≜ □(F ⇒ ◇G)`
- `∃x:F` (hiding) — defined via `♮σ` (stuttering-removed sequence) and `σ ∼ₓ τ` (same up to stuttering and the values of `x`): true for `σ` iff `F` true for some `τ` with `σ ∼ₓ τ`.
- `∀x:F ≜ ¬(∃x:¬F)`
- `F ⇉ G` (guarantee, §10.7): `G` doesn't become false before `F` does — `F⇒G` holds and, for every finite prefix where `F` holds, `G` holds on the one-longer prefix.
Semantics: a behavior is a function `Nat→states` (`σ[i]`); `σ ⊨ F` is the meaning; `σ⁺ⁿ` = behavior with first `n` states deleted; `□`/`∃`/`⇉` given explicit inductive definitions (`σ⊨□F ≜ ∀n∈Nat:σ⁺ⁿ⊨F`, etc.).

---
*Next: Chapter 17 — The Meaning of a Module.*
