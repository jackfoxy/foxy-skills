# Chapter 6 — Some More Math

Source: [SpecifyingSystems-21-07-04.pdf](~/eBooks/TLA+/SpecifyingSystems-21-07-04.pdf) (Leslie Lamport, *Specifying Systems*), pp. 65–73.

Fills in the remaining math foundations: powerful set operators (`UNION`, `SUBSET`, set constructors), why an untyped formalism allows "silly" expressions, what recursive definitions actually mean, the operator-vs-function distinction, and the `CHOOSE` operator. Concepts here are simple to use but subtle in their foundations.

## 6.1 Sets

Beyond the §1.2 basics, two powerful unary operators:
- **`UNION S`** — union of all the elements of `S` (each element of `S` is itself a set). `UNION {{1,2},{2,3},{3,4}} = {1,2,3,4}`. (Mathematicians write `⋃S`.)
- **`SUBSET S`** — the set of all subsets (power set) of `S`. `SUBSET {1,2} = {{},{1},{2},{1,2}}`. (Written `𝒫(S)` or `2^S`.)

**Set constructors** ("set of all … such that"):
- `{x ∈ S : p}` — elements `x` of `S` satisfying `p`. E.g. `{n ∈ Nat : n%2 = 1}` (odd naturals). `x` bound in `p`.
- `{e : x ∈ S}` — values of form `e` as `x` ranges over `S`. E.g. `{2*n+1 : n ∈ Nat}` (odd naturals). `x` bound in `e`; generalizes like `∃` (`{e : x ∈ S, y ∈ T}`; `x` may be a tuple).

**`FiniteSets` module:** `Cardinality(S)` (number of elements, if finite), `IsFiniteSet(S)`.

**Russell's paradox:** `ℛ ≜` set of all sets `S` with `S ∉ S` gives `ℛ ∈ ℛ ≡ ℛ ∉ ℛ` — contradiction. Resolution: `ℛ` **isn't a set** — it's "too big," and can't be written in `TLA⁺`. A collection `𝒞` is too big to be a set iff there's an operator `SMap` assigning a distinct `SMap(S)` to every set `S` (e.g. `SMap(S) ≜ ⟨1,S⟩` shows length-2 sequences are too big to be a set).

## 6.2 Silly Expressions

- `TLA⁺` is untyped, so every syntactically well-formed expression has a meaning — even a "silly" one like `3/"abc"` or `3/0`. Mathematically these are no sillier than usual; e.g. `∀ x ∈ Real : (x≠0) ⇒ (x*(3/x) = 3)` is true, and substituting `x=0` yields a formula containing `3/0` that is still true (because `0≠0` is `FALSE` and `FALSE ⇒ P` holds).
- A correct formula may contain silly subexpressions, **but the truth of a correct formula never depends on the meaning of a silly one**. The value of `3/0` is *unspecified* (the `Reals` module doesn't define it), so `0*(3/0) = 3` has unknown truth.
- No syntactic rule can forbid `3/0` without also forbidding legitimate expressions. Type systems' costs (complexity, restrictions) outweigh their benefits for *specifications* (unlike programming, where types aid compilation and catch errors).

## 6.3 Recursion Revisited

- What `fact[n ∈ Nat] ≜ IF n=0 THEN 1 ELSE n*fact[n−1]` **means**: it's justified by proving it defines a *unique* function `fact` with domain `Nat` satisfying (6.1). Formally it abbreviates `fact ≜ CHOOSE fact : fact = [n ∈ Nat ↦ …]`, i.e. `f[x ∈ S] ≜ e` abbreviates `f ≜ CHOOSE f : f = [x ∈ S ↦ e]`.
- A recursive definition **need not define a function**. If no `f` satisfies `f = [x ∈ S ↦ e]`, `CHOOSE` yields some unspecified value. E.g. `circ[n ∈ Nat] ≜ CHOOSE y : y ≠ circ[n]` is legal but defines `circ` to be some unknown value (no such function exists).
- **No mutually recursive definitions** in `TLA⁺` (two functions defined in terms of each other). Workaround: combine into one **record-valued recursive function** `mr[n] ≜ [f ↦ …, g ↦ …]`, then `f[n ∈ Nat] ≜ mr[n].f`, `g[n ∈ Nat] ≜ mr[n].g`.
- Recursion is common in programming (limited primitive operations) but less needed in math, where powerful logic/set operators are available — e.g. `Head`, `Tail`, `∘` were defined *without* recursion in §5.4. Still, some things are best defined inductively.

## 6.4 Functions versus Operators

Two fundamentally different kinds of objects (`fact` is a **function**, `Tail` is an **operator**):
- **A function is a value**; an operator is not. `fact` by itself is a complete expression (`fact ∈ S` is legal); `Tail` alone is not (`Tail ∈ S` is gibberish).
- **A function has a domain (a set); an operator does not.** `Tail` can't be a function because its domain would have to include all sequences — too big to be a set. So `Tail` must be an operator.
- **Operators can't be defined recursively**, but an illegal recursive *operator* definition can usually be recast via a recursive *function*. E.g. define `Cardinality(S)` using a local recursive function `CS[T ∈ SUBSET S] ≜ IF T={} THEN 0 ELSE 1 + CS[T \ {CHOOSE x : x ∈ T}]`, then `Cardinality(S) ≜ CS[S]`.
- **Operators can take operators as arguments** (functions can't). E.g. `IsPartialOrder(R(_,_), S) ≜ …` takes a 2-argument operator `R`; can use an infix parameter `IsPartialOrder(_≺_, S)`. `IsPartialOrder(>, Nat)` is legal (and `= TRUE`); `IsPartialOrder(+, 3)` is legal but silly.
- Minor differences: `Tail(s)` is defined for *all* `s` (even silly `Tail(1/2)`, some unknown value); `fact[1/2]` is well-formed but its value is unspecified. `TLA⁺` forbids infix *function* definitions (so `/` must be an operator).
- Syntactic vs semantic errors: `2("a")` is not syntactically valid (2 isn't an operator), but `2["a"]` (= `2.a`) *is* syntactically valid, just semantically silly (we don't know if 2 is a function). The **parser** (Ch. 12) catches syntactic errors; **TLC** (Ch. 14) reports semantic silliness when it tries to evaluate it.
- The operator/value distinction exists because `TLA⁺` is a **first-order** (not higher-order) logic; mathematicians use operators like `SUBSET`, `∈` without noticing they aren't values.
- **Choosing operator vs function:** if a *variable* may hold `V` as its value, `V` must be a function (e.g. `mem` in §5.3). Otherwise it's taste — the author usually prefers operators.

## 6.5 Using Functions

- `f' = [i ∈ Nat ↦ i+1]` (6.6) and `∀ i ∈ Nat : f'[i] = i+1` (6.7) both imply `f'[i]=i+1`, but are **not equivalent**: (6.6) uniquely determines `f'` (a function with domain `Nat`); (6.7) is satisfied by many `f'` (and doesn't even imply `f'` is a function). (6.6) ⇒ (6.7), not vice-versa.
- In specs we almost always want to specify the new value of the whole variable `f`, so prefer the (6.6) form.

## 6.6 Choose

- `CHOOSE x : F` (Hilbert's ε); `CHOOSE x ∈ S : p` means `CHOOSE x : (x ∈ S) ∧ p`.
- **Most common use: naming a uniquely-specified value.** E.g. `Reals` defines `a/b ≜ CHOOSE c ∈ Real : a = b*c`. Since no `c` satisfies `a = 0*c` for `a≠0`, `a/0` is unspecified; likewise `a/"xyz"`.
- **`CHOOSE` is deterministic — NOT nondeterministic.** There's no nondeterministic operator in math: if an expression equals 42 today, it equals 42 forever. So `(x = CHOOSE n : n ∈ Nat) ∧ □[x' = CHOOSE n : n ∈ Nat]_x` allows only a **single** behavior — `x` always equals the one particular (unspecified) natural `CHOOSE n : n ∈ Nat`. This is very different from `(x ∈ Nat) ∧ □[x' ∈ Nat]_x`, which is highly nondeterministic (any natural, possibly different each state).

---
*Next: Chapter 7 — Writing a Specification: Some Advice.*
