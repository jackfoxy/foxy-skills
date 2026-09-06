# Chapter 8 — Liveness and Fairness

Source: [SpecifyingSystems-21-07-04.pdf](~/eBooks/TLA+/SpecifyingSystems-21-07-04.pdf) (Leslie Lamport, *Specifying Systems*), pp. 87–116.

The first chapter of Part II and the only one with proofs. Everything so far specified **safety** (what must *not* happen); this adds **liveness** (what must *eventually* happen), expressed in temporal logic via weak/strong fairness. Rigorously defines the meaning of temporal formulas, then shows how to write liveness as fairness conditions and why unrestrained temporal logic is dangerous. (Liveness is the least important, ~5%, part of a spec — you can often omit it.)

## 8.1 Temporal Formulas

- Safety vs liveness: a **safety** property, if violated, is violated at a specific step (can be checked on a finite behavior); a **liveness** property can't be violated at any instant — only an entire infinite behavior reveals it.
- A temporal formula `F` maps a behavior `σ` to a Boolean: `σ ⊨ F`. Boolean/quantifier combinations defined pointwise (`σ ⊨ (F∧G) ≜ (σ⊨F) ∧ (σ⊨G)`, etc.).
- Three base kinds, generalized to actions: with `σⁿ` = the suffix of `σ` from state `n` (`σ⁺ⁿ`), define **`σ ⊨ □F ≜ ∀ n ∈ Nat : σ⁺ⁿ ⊨ F`**. An action `A` as a temporal formula is true of `σ` iff its first two states form an `A` step.
- Read `□` as **always / henceforth**; `σ⁺ⁿ ⊨ F` = "`F` is true at time `n`."
- **Invariance under stuttering** (a new sense of "invariant"): adding/deleting a stuttering step doesn't change `σ ⊨ F`. Sensible formulas must be stuttering-invariant, and TLA only *lets* you write such formulas. State predicates and `□[A]_v` are stuttering-invariant (as are `□F, ¬F, F∧G, ∀…` built from them); a bare action `A` or `□A` (e.g. `□(x'=x+1)`) is **not** — so `□(x'=x+1)` isn't a legal TLA formula.
- Five key derived operators (from arbitrary `F`, `G`):
  - **`◇F ≜ ¬□¬F`** — "eventually" (`F` true at some time; includes now).
  - **`F ⤳ G ≜ □(F ⇒ ◇G)`** — "leads to" (whenever `F`, later `G`).
  - **`◇⟨A⟩_v ≜ ¬□[¬A]_v`** where `⟨A⟩_v ≜ A ∧ (v'≠v)` — eventually a non-stuttering `A` step.
  - **`□◇F`** — "infinitely often" (`F` true at infinitely many instants); `□◇⟨A⟩_v` = infinitely many `⟨A⟩_v` steps.
  - **`◇□F`** — "eventually always" (`F` eventually becomes and stays true).
  - Precedence: `□`,`◇` bind tighter than Boolean ops; `⤳` binds looser than `∧`,`∨`.

## 8.2 Temporal Tautologies

- A **temporal tautology** = a formula true for all behaviors *and* under any substitution for its identifiers (e.g. `□F ⇒ F`), containing temporal operators. Proved by calculating `σ ⊨ … ≡ TRUE` from the operator meanings (or via axioms/inference rules).
- Useful ones: `¬□F ≡ ◇¬F`; `□(F∧G) ≡ □F ∧ □G` (`□` distributes over `∧`); `◇(F∨G) ≡ ◇F ∨ ◇G` (`◇` over `∨`). `□` does **not** distribute over `∨`, nor `◇` over `∧` (only implications hold: `□F ∨ □G ⇒ □(F∨G)`).
- **`□◇` distributes over `∨`; `◇□` distributes over `∧`** (8.1). Reasoning aided by `∃∞ i ∈ Nat : P(i)` ("infinitely many"): `σ ⊨ □◇F ≡ ∃∞ i ∈ Nat : σ⁺ⁱ ⊨ F`.
- **Duality:** from any temporal tautology get a dual by swapping `□↔◇`, `∧↔∨`, and reversing all `⇒` (leaving `≡`, `¬` alone).
- Substituting an action for an identifier in a tautology yields a (possibly non-TLA) tautology; useful equivalences `[A∧B]_v ≡ [A]_v ∧ [B]_v` and `⟨A∨B⟩_v ≡ ⟨A⟩_v ∨ ⟨B⟩_v`.

## 8.3 Temporal Proof Rules

- Ordinary logic rules (Modus Ponens) still apply. Temporal-specific:
  - **Generalization Rule:** from `F` infer `□F`.
  - **Implies Generalization Rule:** from `F ⇒ G` infer `□F ⇒ □G`.
- **A proof rule is NOT a tautology.** The Generalization Rule (from `F` deduce `□F`) does *not* make `F ⇒ □F` a tautology (e.g. `F ⇒ □F` is false for a state predicate true only initially). Confusing the two is a common source of temporal-logic mistakes.

## 8.4 Weak Fairness

- Liveness for the hour clock (never stops) = infinitely many `HCnxt` steps = `□◇⟨HCnxt⟩_hr` (the `⟨…⟩_hr` needed since a bare `□◇HCnxt` isn't a legal TLA formula; and it's `⟨HCnxt⟩_hr`, not `HCnxt`, because a spec's safety already implies any `HCnxt` step changes `hr`). Take `HC ∧ □◇⟨HCnxt⟩_hr`.
- Subscript convention: use `⟨A⟩_v` with `v` = tuple of *all* variables, so "an `A` step occurs" means a *non-stuttering* `A` step (silly to demand a stuttering step eventually occur).
- **`ENABLED A`** = predicate true in states where action `A` is enabled (a step satisfying `A` is possible).
- A too-strong condition `□(ENABLED ⟨A⟩_v ⇒ ◇⟨A⟩_v)` (if ever enabled, eventually taken) is impractical. Weaken to **weak fairness**:
  - **`WF_v(A) ≜ □(□ENABLED ⟨A⟩_v ⇒ ◇⟨A⟩_v)`** — if `A` is *forever* enabled, an `A` step eventually occurs.
  - Three equivalent forms: `□(□ENABLED⟨A⟩_v ⇒ ◇⟨A⟩_v)` (8.7) ≡ `□◇(¬ENABLED⟨A⟩_v) ∨ □◇⟨A⟩_v` (8.8, "infinitely often disabled or infinitely many `A` steps") ≡ `◇□(ENABLED⟨A⟩_v) ⇒ □◇⟨A⟩_v` (8.9, "if eventually enabled forever, then infinitely many `A` steps").
- For the hour clock, `⟨HCnxt⟩_hr` is always enabled, so `HC ⇒ WF_hr(HCnxt)`, and that = `□◇⟨HCnxt⟩_hr`. For the channel, `WF_chan(Rcv)` works because once enabled `Rcv` stays enabled until taken.

## 8.5 The Memory Specification

- **8.5.1 Liveness requirement:** every request must get a response (needn't require requests be issued). Assume `Reply` actions always enabled (`ASSUME ∀ p,r,miOld : ∃ miNew : Reply(…)`). With `vars ≜ ⟨memInt,mem,ctl,buf⟩`: `Liveness ≜ ∀ p ∈ Proc : WF_vars(Do(p)) ∧ WF_vars(Rsp(p))`; internal spec = `ISpec ∧ Liveness`.
- **8.5.2 Another way:** a single fairness condition is simpler than a conjunction. `WF_v(A) ∧ WF_v(B)` and `WF_v(A∨B)` are **not** equivalent in general, but here they are because the spec satisfies **DR1/DR2** (disjointness): whenever `Do(p)` enabled, `Rsp(p)` can't become enabled until a `Do(p)` step occurs, and vice versa. So `Liveness2 ≜ ∀ p ∈ Proc : WF_vars(Do(p) ∨ Rsp(p))`.
- **8.5.3 Generalization — the fairness conjunction rules** (the practical takeaways):
  - **WF Conjunction Rule:** if for distinct `i,j`, whenever `⟨Aᵢ⟩_v` is enabled `⟨Aⱼ⟩_v` can't become enabled until an `⟨Aᵢ⟩_v` step occurs, then `WF_v(A₁) ∧…∧ WF_v(Aₙ) ≡ WF_v(A₁ ∨…∨ Aₙ)`.
  - **WF Quantifier Rule:** likewise `∀ i ∈ S : WF_v(Aᵢ) ≡ WF_v(∃ i ∈ S : Aᵢ)` under the same disjointness (`DR(i,j)`) condition (any set `S`).

## 8.6 Strong Fairness

- **`SF_v(A) ≜ ◇□(¬ENABLED⟨A⟩_v) ∨ □◇⟨A⟩_v`** ≡ `□◇ENABLED⟨A⟩_v ⇒ □◇⟨A⟩_v` — if `A` is enabled **infinitely often** (continually, possibly with interruptions), an `A` step eventually occurs.
- WF requires an `A` step if `A` is *continuously* enabled; SF if `A` is *continually* enabled. **SF is stronger than WF** (`◇□F ⇒ □◇F`). They're equivalent when `A`, once disabled infinitely often, either eventually stays disabled or is taken infinitely often (as with the channel `Rcv`).
- Analogous **SF Conjunction/Quantifier Rules** hold. SF is harder to implement and less common — use it only when needed; write WF when they're equivalent.
- Specify liveness as a conjunction of WF/SF properties whenever possible (almost always) — ad hoc temporal formulas lead to errors.

## 8.7 The Write-Through Cache

- Add liveness: every request eventually gets a response, requiring fairness on all `Next` actions except `Req(p)` (issues requests), `Evict(p,a)`, and (initially) `MemQWr`.
- **Weak vs strong choice** depends on whether an enabled action *stays* enabled until executed. Weak fairness for `Rsp(p)`, `DoRd(p)`, `MemQWr`, `MemQRd`; **strong fairness for `RdMiss(p)` and `DoWr(p)`** (they can be disabled by another processor's `RdMiss(q)`/`DoWr(q)` filling `memQ`). `DoRd(p)` only needs WF (disabled only by an `Evict` of its own data, which can't recur until `DoRd(p)` runs).
- `vars ≜ ⟨memInt,wmem,buf,ctl,cache,memQ⟩`. Combine via the conjunction rules into (8.35): `∀ p ∈ Proc : WF_vars(Rsp(p) ∨ DoRd(p)) ∧ SF_vars(RdMiss(p) ∨ DoWr(p)) ∧ WF_vars(MemQWr ∨ MemQRd)`. The quantifier rule can't pull `∀ p` inside `WF_vars(Rsp(p)∨DoRd(p))` (two processors can be enabled at once), so (8.35) is as simple as it gets.
- To describe the *weakest* implementing liveness, `MemQWr` fairness could be conditioned on `QCond` (`memQ` full or has a read); but a real device implements WF on all `MemQWr`, so keep (8.35).

## 8.8 Quantification

- **Ordinary (rigid) quantifiers** `∀ r : F`, `∃ r : F` over *constants*: `r` is a **rigid variable** (a constant — same value in every state; logicians' term vs TLA's **flexible variable**). Bounded forms over a constant `S`; `S` lies outside the scope of `r`.
- Temporal `CHOOSE r : F` isn't a legal TLA⁺ formula (not needed).
- **Temporal existential `∃` (bold)**: in `∃ x : F`, `x` is a *flexible variable*. `∃ x : F` asserts existence of a value for `x` in *each state* (values may differ/be disjoint across states) — the **variable-hiding** operator (`∃ x : F` ≈ `F` with `x` hidden). Precise definition is subtle (must be stuttering-invariant); intuitively `σ ⊨ ∃ x : F` iff some `τ` obtained from `σ` by adding/deleting stuttering and changing `x` satisfies `F`. (§16.2.4.)
- Temporal universal **`∀ x : F ≜ ¬∃ x : ¬F`** (rarely used). No bounded versions of `∃`/`∀`.

## 8.9 Temporal Logic Examined

- **8.9.1 Review:** specs progressed from `Init ∧ □[Next]_vars` (8.38, pure safety) → add hiding via `∃` → add liveness: **`Init ∧ □[Next]_vars ∧ Liveness`** (8.39), where `Liveness` is a conjunction of `WF_vars(A)`/`SF_vars(A)`.
- **8.9.2 Machine closure:** a spec (8.39) is **machine closed** iff `Liveness` constrains neither the initial state nor which steps may occur — i.e. every finite behavior satisfying the safety part extends to an infinite one satisfying safety ∧ liveness. Guaranteed machine closed when `Liveness` is a conjunction of WF/SF on **subactions** of `Next` (`A` is a subaction iff `A ⇒ Next`). A non-machine-closed example: (8.40) `(x=0) ∧ □[x'=x+1]_x ∧ WF_x((x>99) ∧ (x'=x−1))` forces `x` to never exceed 99. You seldom want a non-machine-closed spec (usually a mistake).
- Directly-written liveness formulas like (8.41) `∀ p : □((ctl[p]="rdy") ⇒ ◇⟨Rsp(p)⟩_vars)` are appealing but dangerous — easy to accidentally write a non-machine-closed spec. **Express liveness with fairness on subactions** except in unusual cases (rare exceptions in §11.2).
- **8.9.3 Machine closure & possibility:** machine closure = a *possibility* condition (any finite execution can be extended so infinitely many `⟨A⟩_v` occur). TLA specs express safety and liveness, **not possibility** — we never care that something *might* happen, only what *must*. Possibility can be a useful assertion about a *specification* though (e.g. the user should always be *able* to type "a" — the pair `S, □◇⟨A⟩_v` should be machine closed).
- **8.9.4 Refinement mappings & fairness:** for `Spec ⇒ ISpec̄` proofs, overbarring (substitution) distributes over `∧`, `□`, `⟨…⟩`, but **not automatically inside WF/SF** (substitution doesn't distribute over `ENABLED`). In practice, replacing `WF_v(A)` by `WF_v̄(Ā)` gives the right result, but you can instead expand WF/SF and compute the `ENABLED` predicates "by hand" (over states satisfying the safety part), using rules: `ENABLED(A∨B) ≡ ENABLED A ∨ ENABLED B`; `ENABLED(P∧A) ≡ P ∧ ENABLED A`; `ENABLED(A∧B) ≡ ENABLED A ∧ ENABLED B` if no variable primed in both; `ENABLED(x'=exp) ≡ TRUE`, `ENABLED(x'∈exp) ≡ (exp≠{})`.
- **8.9.5 The unimportance of liveness:** in practice liveness matters far less than safety. Most of a spec's value comes from the safety part; liveness is usually easy to write (<5%) — write it, but devote error-hunting effort to safety.
- **8.9.6 Temporal logic considered confusing:** the general spec form is **`∃ v₁,…,vₙ : Init ∧ □[Next]_vars ∧ Liveness`** (8.42), a *restricted* class of temporal formulas. The seductive alternative — express each property as an arbitrary temporal formula and conjoin them — is practical only for the simplest specs; unbridled temporal logic produces unreadable formulas. Most engineers need only the safety-only, no-hiding form (8.38); (8.42) is a building block (Chs. 9, 10; operator `⇉` in §10.7).

---
*Next: Chapter 9 — Real Time.*
