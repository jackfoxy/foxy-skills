# Chapter 18 — The Standard Modules

Source: [SpecifyingSystems-21-07-04.pdf](~/eBooks/TLA+/SpecifyingSystems-21-07-04.pdf) (Leslie Lamport, *Specifying Systems*), pp. 339–348.

The final chapter of Part IV (and the book, before the Index) — a reference giving the actual `TLA⁺` source of the standard modules. Two reasons to use them: specs read better with familiar operators, and tools can have built-in knowledge of standard operators (TLC has efficient implementations; a theorem prover might have decision procedures). Covers `Sequences`, `FiniteSets`, `Bags`, and the numbers modules (`Naturals`/`Integers`/`Reals` via `Peano`/`ProtoReals`); `RealTime` was already given in Chapter 9. Some definitions are subtle (the reals), others obvious (`1..n`).

## 18.1 Module `Sequences`

Defines operators on **finite sequences** — a length-`n` sequence is a function with domain `1..n` (the same as an n-tuple, so tuples *are* sequences). Uses `LOCAL INSTANCE Naturals` (imports `Naturals` definitions without re-exporting, so a module can use sequences without extending `Naturals`). Operators:
- `Seq(S) ≜ UNION {[1..n → S] : n ∈ Nat}` — set of all finite sequences over `S`.
- `Len(s)` — length; `s ∘ t` — concatenation; `Append(s,e) ≜ s ∘ ⟨e⟩`.
- `Head(s) ≜ s[1]`; `Tail(s)` — all but the first element.
- `SubSeq(s,m,n)` — the subsequence `⟨s[m],…,s[n]⟩` (undefined if `m<1` or `n>Len(s)`, empty if `m>n`).
- `SelectSeq(s, Test(_))` — subsequence of elements satisfying `Test` (recursive `LET`).

## 18.2 Module `FiniteSets`

Defines the two operators from §6.1, using `LOCAL INSTANCE Naturals, Sequences`:
- `IsFiniteSet(S)` — true iff some finite sequence contains all of `S`'s elements (`∃ seq ∈ Seq(S) : ∀ s ∈ S : ∃ n ∈ 1..Len(seq) : seq[n]=s`).
- `Cardinality(S)` — defined (via a recursive `LET`) only for finite sets: 0 for `{}`, else `1 + Cardinality(S∖{CHOOSE x : x∈S})`.

## 18.3 Module `Bags`

A **bag** (multiset) is a set that may contain multiple copies of an element — represented as a **function whose range is a subset of the positive integers** (`B[e]` = number of copies of `e`). Useful e.g. for a network's in-transit messages. `LOCAL INSTANCE Naturals`. Operators (in "customary style," an operator applied to a non-bag has an unspecified value):
- `IsABag(B)`, `BagToSet(B)` (elements with ≥1 copy), `SetToBag(S)` (one copy each), `BagIn(e,B)` (the `∈` for bags), `EmptyBag`, `CopiesIn(e,B)` (= 0 if not in `B`).
- `B1 ⊕ B2` (union, copies add), `B1 ⊖ B2` (difference, copies subtract, floored at 0), `BagUnion(S)` (the `UNION` analog over a set of bags).
- `B1 ⊑ B2` (subset analog: `B2` has ≥ as many copies of every element), `SubBag(B)` (the `SUBSET` analog), `BagOfAll(F,B)` (the `{F(x):x∈B}` analog), `BagCardinality(B)` (total copies, for a finite bag).
- A `LOCAL Sum` (defined inside `Bags`, not exported) is used to implement several of these.

## 18.4 The Numbers Modules

The usual number sets/operators are in `Naturals`, `Integers`, `Reals`, which must be **consistent** — a module extending both `Naturals` and something extending `Reals` must get one and the same `+`. This is achieved by having both derive `+` from a common **`ProtoReals`** module, locally instantiated by both.
- **`Naturals`** defines `+ − * ^ < ≤ > ≥ .. Nat` and (uniquely) integer division `÷` and modulus `%`, defined so `a%b ∈ 0..(b−1)` and `a = b*(a÷b) + (a%b)`.
- **`Integers`** extends `Naturals`, adds `Int` and unary minus `−` (written `−.` when defined/used as an operator argument).
- **`Reals`** extends `Integers`, adds `Real`, ordinary division `/`, and `Infinity`. As in math (not programming), integers *are* reals: `Nat ⊆ Int ⊆ Real`. `Infinity` (a mathematical ∞) satisfies `−Infinity < r < Infinity` for all `r∈Real` and `−(−Infinity)=Infinity`.

The precise details are **of no practical importance** — when writing specs just assume the operators have their usual meanings; the modules exist for completeness and can serve as models for defining other math structures.

### Module `Peano`
Defines `Nat` (with `Zero`, successor `Succ`) as an arbitrary set satisfying **Peano's axioms** — via `PeanoAxioms(N,Z,Sc)`, an `ASSUME`d existence, and `CHOOSE`. Separated into its own module because tuples and strings (§16.1.9–10) are defined in terms of natural numbers, and `Peano` uses neither — so **no circularity**. (`0`/`1` = `Zero`/`Succ[Zero]`; `ProtoReals` could use `0`/`1` but that would hide the dependency on `Peano`.)

### Module `ProtoReals`
Most `Naturals`/`Integers`/`Reals` definitions come from here. `EXTENDS Peano`. Defines the reals as a **complete ordered field containing the naturals**, using the classic result that the reals are *uniquely defined up to isomorphism* as an ordered field in which every bounded-above subset has a least upper bound. `IsModelOfReals(R,Plus,Times,Leq)` asserts: `Nat ⊆ R` embedded (`Succ[n]=n+Succ[Zero]`), `R` is an **Abelian group** under `+` (identity `Zero`), an Abelian group under `*` on `R∖{Zero}` (a **field**), distributivity, **ordered field** axioms on `≤`, and the **least-upper-bound** (completeness) property. A `THEOREM` asserts such a model exists; `RM ≜ CHOOSE …`, `Real ≜ RM.R`. Then `+`, `*`, `≤`, `−`, `/`, `Int`, `Infinity`/`MinusInfinity`, and exponentiation `a^b` (defined by its four axioms + a continuity condition, via `CHOOSE`) are derived.

### Modules `Naturals`, `Integers`, `Reals` (final form)
Each does `LOCAL R ≜ INSTANCE ProtoReals` and defines its operators by delegating — e.g. `a + b ≜ a R!+ b`, `a ÷ b ≜ CHOOSE n ∈ R!Int : …`. The **ugliness** of definitions like `a R!+ b` demonstrates the lesson: **don't define infix operators in a module that may be used with a named instantiation.**

---
*End of Part IV and of the book's main text (the Index follows).*
