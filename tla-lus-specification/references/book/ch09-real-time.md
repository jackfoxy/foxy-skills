# Chapter 9 — Real Time

Source: [SpecifyingSystems-21-07-04.pdf](~/eBooks/TLA+/SpecifyingSystems-21-07-04.pdf) (Leslie Lamport, *Specifying Systems*), pp. 117–134.

Liveness says a response comes *eventually*; real-time properties say it comes *within N seconds*. This chapter adds quantitative timing by introducing a `now` variable for real time, generalizes it into the reusable `RealTime` module (`RTBound`/`RTnow`), applies it to the memory and cache, and covers the pitfalls: Zeno specifications and hybrid (continuous-physics) systems.

## Setup: representing time with `now`

- Introduce a variable **`now`** (real number, seconds since some epoch; the author uses `now` not `t`). Time changes in *discrete* steps like any other continuously-varying quantity — no need to pick a granularity; `now` may advance by any amount between system steps.
- Steps that change `now` (time passing) leave the discrete system variables unchanged, and vice versa.

## 9.1 The Hour Clock Revisited (module `RealTimeHourClock`)

Goal: strengthen `HC` so the clock ticks once per hour ± `Rho` seconds.
- Auxiliary **timer** `t` = elapsed time since the last `HCnxt` step. `TNext ≜ t' = IF HCnxt THEN 0 ELSE t + (now'−now)`; `Timer ≜ (t=0) ∧ □[TNext]_⟨t,hr,now⟩`.
- `MaxTime ≜ □(t ≤ 3600 + Rho)` (tick at *least* once every 3600+ρ — upper bound on elapsed time).
- `MinTime ≜ □[HCnxt ⇒ (t ≥ 3600 − Rho)]_hr` (tick at *most* once every 3600−ρ — an `HCnxt` step needs ≥3600−ρ elapsed). Note it must be `□[…]_hr`, not the illegal bare `□(HCnxt ⇒ …)`.
- `HCTime ≜ Timer ∧ MaxTime ∧ MinTime`; hide the timer `t` via `∃ t : I(t)!HCTime` (submodule `Inner` + parametrized instance, since you can't write `∃ t : HCTime` directly).
- **`RTnow` — how `now` changes** (must be added, else the spec allows time to stop, letting the clock stop): `NowNext ≜ (now' ∈ {r ∈ Real : r > now}) ∧ UNCHANGED hr`; `RTnow ≜ (now ∈ Real) ∧ □[NowNext]_now ∧ (∀ r ∈ Real : WF_now(NowNext ∧ (now' > r)))`. The **weak-fairness conjunct rules out "Zeno" behaviors** where `now` stays bounded (plain WF isn't enough); it forces `now` to increase without bound.
- Full spec: **`RTHC ≜ HC ∧ RTnow ∧ (∃ t : I(t)!HCTime)`**. Module `EXTENDS Reals, HourClock`, adds `CONSTANT Rho` with `ASSUME (Rho ∈ Real) ∧ (Rho > 0)`.

## 9.2 Real-Time Specifications in General (module `RealTime`)

Generalize timing to any action, giving a reusable module with variable `now`.
- **Real-time bound `RTBound(A, v, δ, ε)`** (`δ`=`D`, `ε`=`E` in TLA⁺): asserts a `⟨A⟩_v` step
  - cannot occur until `⟨A⟩_v` has been continuously enabled ≥ `δ` time units since the last `⟨A⟩_v` step (lower bound; `δ=0` ⇒ vacuous), and
  - `⟨A⟩_v` can be continuously enabled for at most `ε` time units before an `⟨A⟩_v` step (upper bound; `ε = Infinity` ⇒ vacuous). `Infinity` is defined in `Reals` as greater than any real.
- Must be a condition on `⟨A⟩_v` (not bare `A`), with `v` = tuple of all variables in `A`, to be stuttering-invariant. Structured with a submodule/`LET`, hiding an internal timer `t`:
  `TNext(t) ≜ t' = IF ⟨A⟩_v ∨ ¬(ENABLED⟨A⟩_v)' THEN 0 ELSE t + (now'−now)`; `Timer(t)`, `MaxTime(t) ≜ □(t ≤ E)`, `MinTime(t) ≜ □[A ⇒ (t ≥ D)]_v`; `RTBound(A,v,D,E) ≜ ∃ t : Timer(t) ∧ MaxTime(t) ∧ MinTime(t)`.
- **`RTnow(v)`** generalizes `RTnow` (replaces `hr` with arbitrary tuple `v` of all variables other than `now`).
- **`RTBound` + `RTnow(v)` ⇒ `WF_v(A)`** (if `ε < Infinity`): a finite upper bound forces the `⟨A⟩_v` step, so it implies weak fairness. (There's an analogous stronger `SRTBound` for strong fairness, but it's not of much practical use, so it's not defined.)
- The `RealTime` module: `EXTENDS Reals`, `VARIABLE now`, defines `RTBound` and `RTnow` for `0 ≤ δ ≤ ε ≤ Infinity`.

## 9.3 A Real-Time Caching Memory

- **`RTMemory`**: strengthen the linearizable memory (§5.3) so it responds within `Rho` seconds. Add the constraint to the *internal* spec `ISpec` (constraints can mention hidden variables), then hide. Define `Respond(p) ≜ (ctl[p] ≠ "rdy") ∧ (ctl'[p] = "rdy")` (enabled by a pending request, disabled when the response is issued); assert `RTBound(Respond(p), ctl, 0, Rho)` for all `p`. `RTSpec ≜ ∃ mem,ctl,buf : Inner(…)!RTISpec`.
- **`RTWriteThroughCache`**: real-time version of the write-through cache. The object is a real-time *algorithm* (tells an implementer how to meet the bounds), so put `RTBound`s on the *original next-state subactions*, not on a new action.
  - Problem: processors compete to enqueue on the finite `memQ`; a `DoWr(p)`/`RdMiss(p)` can be continually disabled by other processors. The real fix is **scheduling** — add **round-robin** discipline via a variable `lastP` (last processor enqueued) and `position(p)`/`canGoNext(p)`; `RTRdMiss(p)`/`RTDoWr(p)` are `RdMiss`/`DoWr` with the extra `canGoNext(p)` enabling condition, setting `lastP := p`.
  - Assume single upper bounds `Epsilon` (per-processor actions) and `Delta` (`MemQWr`/`MemQRd` dequeuing). A single `RTBound` on the disjunction of a processor's actions suffices when they're never simultaneously enabled and mutually exclusive (separate bound for `RTRdMiss(p)` since `Evict` can disable `DoRd(p)` and enable `RTRdMiss(p)`).
  - Correctness assumption relating the constants: `2*(N+1)*Epsilon + (N+QLen)*Delta ≤ Rho`. Module asserts `THEOREM RTSpec ⇒ RTM!RTSpec` (the real-time cache implements the real-time memory).

## 9.4 Zeno Specifications

- **Zeno behavior:** infinitely many steps in a bounded time interval (`now` = 0, ε/2, 3ε/4, 7ε/8, …) — `ε` seconds never actually pass (named for Zeno's paradox). Real behaviors aren't Zeno.
- Zeno behaviors are harmlessly forbidden by conjoining **`NZ`** (Non-Zeno): `∀ r ∈ Real : WF_now(Next ∧ (now' > r))`, which forces `now` to increase without bound.
- **Danger:** a spec that allows *only* Zeno behaviors. Conjoining `NZ` to it yields `FALSE` (no behaviors). Example: `RTBound(HCnxt, hr, δ, ε)` with `δ > ε` requires the clock to wait ≥δ but tick within ≤ε — impossible unless time never advances; only a Zeno behavior satisfies it, so ∧ `NZ` = `FALSE`.
- A **Zeno specification** = one with a finite behavior satisfying the safety part that *cannot* be extended to an infinite behavior satisfying safety ∧ `NZ` (its only extensions are Zeno). A **non-Zeno** spec = the pair (safety part, `NZ`) is **machine closed** (§8.9.2) — analogous to other non-machine-closed problems, and likely *incorrect* (the timing bounds constrain the system in unintended ways).
- **Non-Zeno result:** a spec of the form `Init ∧ □[Next]_vars ∧ RTnow(vars) ∧ (finite conjunction of RTBound(Aᵢ, vars, δᵢ, εᵢ))` is non-Zeno if each `Aᵢ` is a *subaction* of `Next`, no step is both an `Aᵢ` and `Aⱼ` step (i≠j), and `0 ≤ δᵢ ≤ εᵢ ≤ Infinity`. So `RTSpec` of `RTWriteThroughCache` is non-Zeno. This doesn't directly cover `RTMemory` (its `Respond(p)` isn't a subaction of `INext`), but that spec is non-Zeno anyway (any finite behavior extends by responding immediately then advancing `now`). Conversely, an `RTBound` on a *non-subaction* easily gives a Zeno spec (e.g. `HC ∧ RTBound(hr'=hr−1, hr, 0, 3600) ∧ RTnow(hr)` ≡ `FALSE`).
- **Rule of thumb:** implementation-level real-time constraints are naturally `RTBound`s on subactions (non-Zeno); high-level abstract specs may put `RTBound`s on non-subactions (like `RTMemory`).

## 9.5 Hybrid System Specifications

- A TLA⁺ spec describes a physical entity; `now` differs from other variables only in that we don't abstract away time's continuous nature. Other continuously-varying physical quantities (aircraft position/velocity, reactor parameters) can be represented too — a **hybrid system specification**.
- Replace `RTnow(v)` with a next-state action that describes changes to the continuous variables, e.g. `⟨p',w'⟩ = Integrate(D, now, now', ⟨p,w⟩)` where `D` specifies a differential equation and `Integrate` (from the `DifferentialEquations` module, §11.1.3) solves it. Position `p` and velocity `w = dp/dt` evolve per a switched ODE.
- Any evolution you can describe mathematically can be specified in TLA⁺ (some may need operators for PDE solutions, etc.). Hybrid specs remain largely of academic interest.

## 9.6 Remarks on Real Time

- Real-time constraints are most often **upper bounds** — a strong form of liveness (*when* something must happen, not just that it must). Simple specs (hour clock, write-through cache) replace liveness with timing; complex specs may assert both.
- Real specs the author has seen never needed complicated timing constraints — either simple algorithms where timing is crucial to correctness, or systems where real time appears only through simple timeouts to ensure liveness. (People probably avoid complicated real-time constraints because they're too hard to get right.)
- All real-time specs *can* be written by conjoining `RTnow`/`RTBound` to an untimed spec (in fact `RTBound`s on subactions suffice), but the result can be incredibly complicated — of theoretical interest. `RTnow`/`RTBound` have solved every real-time problem the author has met; whatever real-time property you need, expressing it in TLA⁺ won't be hard.

---
*Next: Chapter 10 — Composing Specifications.*
