# Chapter 7 — Writing a Specification: Some Advice

Source: [SpecifyingSystems-21-07-04.pdf](~/eBooks/TLA+/SpecifyingSystems-21-07-04.pdf) (Leslie Lamport, *Specifying Systems*), pp. 75–83.

The closing chapter of Part I. No new `TLA⁺` — practical guidance on *why*, *what*, and *how* to specify: choosing the abstraction and grain of atomicity, the mechanical steps of writing a spec, a collection of concrete do/don't hints, and advice to specify during design rather than after.

## 7.1 Why Specify

Specification takes effort; the payoff is avoiding errors. Three benefits:
- **Aids design** — writing precisely reveals subtle interactions and corner cases early, when they're cheap to fix.
- **Aids communication** — a clear, concise record that designers agree on and implementers/testers (and users) can rely on.
- **Enables tools** — a formal description that tools (esp. the **TLC model checker**, Ch. 14) can analyze for errors.

Whether the benefit justifies the effort depends on the project. Specification is a tool, not an end in itself.

## 7.2 What to Specify

- You don't specify "a system" — a spec is a **mathematical model of a particular view of part of a system**. First choose *what part* to model; often non-obvious (e.g. a cache-coherence protocol may require inventing a processor/memory interface that doesn't exist in the real design).
- Purpose is to catch errors, so specify the parts most likely to *have* errors. `TLA⁺` is especially good at **concurrency errors** (asynchronous interaction). If that's not where your risk is, you probably shouldn't be using `TLA⁺`.

## 7.3 The Grain of Atomicity

- The most important aspect of the abstraction level: **what changes count as a single step**. Sending a message is many suboperations but usually modeled as one step; send + receipt of a message are usually separate steps in a distributed system.
- Coarser grain → shorter behaviors → simpler spec, but less accurate; may hide important details. Finer grain → more accurate but more complex.
- **Formal handle (action composition `·`):** `A·B` is the action executing `A` then `B` as one step (`s→t` is an `A·B` step iff `∃ u : s→u` is `A`, `u→t` is `B`). An operation of two suboperations `R` then `L` is either fine-grained `R ∨ L` (two steps, spec `S2`... actually `S1`) or coarse-grained `R·L` (one step, `S2`).
- Fine-grained `S1` is a *strengthened* version of coarse-grained `S2` — it allows *fewer* behaviors (forces each `R` to be immediately followed by `L`; `S2` permits other steps in between). Choosing atomicity = deciding whether those extra `S2` behaviors matter.
- The extra behaviors don't matter if each `S2` behavior has an "equivalent" `S1` behavior — obtainable by **commuting** the `Aᵢ` steps past `R` or `L`. Actions `A`,`B` **commute** iff `A·B ≡ B·A`; sufficient condition: (i) neither changes a variable the other may change, and (ii) neither enables/disables the other. The transformation works if `R` commutes with each `Aᵢ` (then `k=n`) or `L` does (`k=0`); generalizes to `m` subactions if all but one commute with every other system action. (The `·` operator rarely appears in real specs — if tempted, find a better formulation.)
- Understanding the fine/coarse relation *helps* you choose but *won't make the choice for you*.

## 7.4 The Data Structures

- Another abstraction dimension: **how accurately to describe data structures** (e.g. actual memory layout of procedure arguments vs an abstract representation).
- Since the goal is catching errors: a precise layout helps only if layout misunderstandings are a real risk, at the cost of complicating the spec. For concurrency-error specs, detailed data structures are needless complication — use high-level abstract representations (e.g. constant parameters like `Send`/`Reply` of §5.1).

## 7.5 Writing the Specification

Once part-to-specify and abstraction level are chosen, the mechanical steps:
1. **Pick the variables; define the type invariant and initial predicate.** This determines the constant parameters and their assumptions (and any extra constants).
2. **Write the next-state action** (the bulk). Sketch sample behaviors first. Decide how to decompose `Next` into a disjunction of actions, then define them — compact and readable, carefully structured. Reduce size by factoring out shared state predicates/functions into definitions. Determine which standard modules you need (`EXTENDS`) and any constant operators for data structures.
3. **Write the temporal part.** For liveness, choose fairness conditions (Ch. 8); combine init + next-state + fairness into the single temporal formula that is the spec.
4. **Assert theorems** — at minimum a type-correctness theorem.

## 7.6 Some Further Hints

- **Don't be too clever.** Cleverness can be wrong. `q = ⟨h'⟩ ∘ q'` is worse than — and actually wrong compared to — `(h' = Head(q)) ∧ (q' = Tail(q))`, since it has unintended solutions where `h'`,`q'` aren't sequences. Best way to specify a new value: a conjunct `v' = exp` or `v' ∈ exp` with `exp` a state function (no primes).
- **A type invariant is not an assumption.** It's a *definition*; defining `TypeInvariant` asserting `n ∈ Nat` does **not** make `n'` a natural in an action. `n' > 7` asserts only `n' > 7` (satisfied by `n' = √96` or `"abc"`). If you need `x'` in a set, make the next-state action imply it, e.g. `Next ≜ (n' ∈ Nat) ∧ (Action1 ∨ Action2)`.
- **Don't be too abstract.** An abstract keyboard `KeyStroke("a", typ, typ')` (one step) is simpler than a concrete `kbd` set with `Press(k)`/`Release(k)` steps — but the concrete version naturally exposes questions (two keys down at once?) the abstract one hides. Choosing abstraction should be a conscious decision; when in doubt, prefer the more concrete representation that mirrors the real system, so you overlook fewer real problems.
- **Don't assume values that look different are unequal.** `TLA⁺` does *not* imply `1 ≠ "a"`. If a message may be a string or a number, tag it as a record with `type` and `value` fields (`[type ↦ "String", value ↦ "a"]` vs `[type ↦ "Nat", value ↦ 1]`) — the differing `type` fields guarantee inequality.
- **Move quantification to the outside.** Prefer `Move ≜ ∃ e ∈ Elevator : Up(e) ∨ Down(e)` over defining `Up`/`Down` each with their own inner `∃ e`. (`∃` outside disjunctions, `∀` outside conjunctions.)
- **Prime only what you mean to prime.** `f[e]'` equals `f'[e']`, not `f'[e]` (unless `e` has no variables). Be careful priming an operator whose definition contains a variable: with `op(a) ≜ x + a`, `op(y)'` = `(x+y)'` = `x'+y'`, while `op(y')` = `x+y'` — there's no way to write `x'+y` via `op` and `'` (`op'(y)` is illegal — you can prime only an expression, not an operator).
- **Write comments as comments.** Don't encode intent as redundant formula structure. A disjunct `∧ x < 0 ∧ FALSE` (meant to signal "not enabled when `x<0`") is completely redundant (`F ∨ FALSE ≡ F`); write it as an actual comment on the `x ≥ 0` conjunct instead.

## 7.7 When and How to Specify

- Specs are usually written **later than they should be** — engineers under time pressure feel it will slow them down, and only write one once the design is too complex to understand.
- But writing a spec **helps you think clearly**, and thinking clearly is hard — make specification *part of the design process*.
- Write the spec **as the system is designed**, not after. It will start incomplete and probably incorrect (e.g. an early `RdMiss(p)` with a `ctl' = [ctl EXCEPT ![p] = "?"]` placeholder and a to-be-added enabling condition). Omitted functionality is added later as new disjuncts of the next-state action. Tools can be applied to these preliminary specs to find design errors early.

---
*End of Part I. Next: Part II — More Advanced Topics (Chapter 8 — Liveness and Fairness).*
