# Chapter 10 — Composing Specifications

Source: [SpecifyingSystems-21-07-04.pdf](~/eBooks/TLA+/SpecifyingSystems-21-07-04.pdf) (Leslie Lamport, *Specifying Systems*), pp. 135–168.

So far components appeared as *disjuncts* of one monolithic next-state action. This chapter specifies components *separately* and composes them by **conjunction** — the core insight being that a TLA formula describes the whole universe, so composing systems `F` and `G` = making the universe satisfy `F ∧ G`. Covers disjoint- vs shared-state composition, joint actions, a composition taxonomy, liveness/hiding under composition, open-system specs (`⇉`), and interface refinement.

## Core idea

- A TLA formula specifies a *universe* in which the system behaves correctly. **The composition of systems with specs `F` and `G` is `F ∧ G`.** Each conjunct is viewed as one component's spec. (Simple in principle; the details are the chapter.)

## 10.1 Composing Two Specifications

- `TwoClocks` = two independent hour clocks on `x`, `y`: just `(x ∈ 1..12 ∧ □[HCN(x)]_x) ∧ (y ∈ 1..12 ∧ □[HCN(y)]_y)`. A calculation (using `□(F∧G) ≡ □F ∧ □G`) rewrites it monolithically as `Init ∧ □[TCnxt]_⟨x,y⟩` where `TCnxt` has a disjunct `HCN(x) ∧ HCN(y)` — **simultaneous** advance of both clocks.
- **Interleaving vs noninterleaving:** an *interleaving* spec attributes each nonstuttering step to exactly one component; a *noninterleaving* spec (like `TwoClocks`) permits simultaneous actions by multiple components.
- To make it interleaving, either (a) define each component's action to assert the other's variables are unchanged (`HCNx ≜ HCN(x) ∧ (y'=y)`), needing conditions (i) `HCNx ⇒ HCN(x)`, (ii) `HCNy ⇒ HCN(y)`, (iii) `HCNx ∧ HCNy ⇒ x'=x ∨ y'=y`; or (b) conjoin a global interleaving assumption `□[(x'=x) ∨ (y'=y)]_⟨x,y⟩`.
- **Composition Rule (10.1):** `(I₁ ∧ □[N₁]_v₁) ∧ (I₂ ∧ □[N₂]_v₂) ≡ I₁ ∧ I₂ ∧ □[N₁∧(v₂'=v₂) ∨ N₂∧(v₁'=v₁) ∨ N₁∧N₂]_v` where `v` is the tuple of all variables and `(v₁'=v₁) ∧ (v₂'=v₂) ≡ (v'=v)`. Interleaving iff the `N₁∧N₂` disjunct is redundant (guaranteed if each `Nₖ` leaves the other's tuple unchanged).

## 10.2 Composing Many Specifications

- **Composition Rule** generalizes (`∀` generalizes `∧`) to any set `C` of components, with an interleaving version having a redundant simultaneous disjunct removed when each `Nᵢ` leaves other `vⱼ` unchanged (needs `Nᵢ` to mention other components' variables — a philosophical objection) or by a separate global interleaving conjunct `□[∃ k ∈ C : ∀ i ∈ C\{k} : vᵢ'=vᵢ]_v`.
- Components' `vₖ` need not be *separate variables* — they can be different "parts" of one variable, e.g. an array-of-clocks `ClockArray ≜ ∀ k ∈ Clock : (hr[k] ∈ 1..12) ∧ □[HCN(hr[k])]_hr[k]`, where `vₖ = hr[k]`. Substituting for `v` in the Composition Rule requires the *function* `hrfcn ≜ [k ∈ Clock ↦ hr[k]]` (not `hr` itself — `ClockArray` doesn't even imply `hr` is a function). Force `hr` to be a function with `IsFcnOn(f,S) ≜ f = [x ∈ S ↦ f[x]]` and conjoin `□IsFcnOn(hr, Clock)`. Many equivalent ways to write it — matter of taste.

## 10.3 The FIFO (module `CompositeFIFO`)

- Specify the FIFO as `Sender ∧ Buffer ∧ Receiver` (noninterleaving). Components described by state functions over `in`, `out`, `q`: Sender ↔ `⟨in.val, in.rdy⟩`, Buffer ↔ `⟨in.ack, q, out.val, out.rdy⟩`, Receiver ↔ `out.ack`.
- `q` is internal to Buffer, so Sender/Receiver actions can't mention it → can't reuse `InnerFIFO`; instead reuse `Channel`'s `Send`/`Rcv` and hide `q` in a **submodule** `InnerBuf` (`Buffer ≜ ∃ q : Buf(q)!InnerBuffer`). Submodules can use everything declared before them and are instantiated in the containing module.
- Conjoin `□(IsChannel(in) ∧ IsChannel(out))` (asserting `in`/`out` are records) and, for **relating components' initial states** (`in.ack = in.rdy` etc.), a **separate conjunct** belonging to neither component (one of three choices — assert in all, assign to one, or make separate; the separate/assign choices become formal in open-system specs §10.7).
- `Spec` is noninterleaving (allows a simultaneous `InChan!Send` + `OutChan!Rcv` step), so *not* equivalent to the interleaving `FIFO!Spec` of Ch. 4.

## 10.4 Composition with Shared State

Beyond *disjoint-state* compositions (each component owns a partition of the state):
- **10.4.1 Explicit state changes:** when state can't be partitioned but each component fully describes its state change. Sender/Receiver share `buf`. Trick: `NS ≜ Sndr ∨ (σ ∧ s'=s)`, `NR ≜ Rcvr ∨ (ρ ∧ r'=r)`, where `σ`/`ρ` are actions describing `buf` changes *not caused by* the Sender/Receiver. Need three conditions (an append isn't caused by Receiver ⇒ `ρ`; a head-removal isn't caused by Sender ⇒ `σ`; a step caused by neither can't change `buf`). Freedom in choosing `σ`,`ρ`; strongest choices describe exactly the changes the *other* component permits. Generalizes to the **Shared-State Composition Rule** (four conditions, with `μₖ` = changes to shared `w` attributed to components other than `k`).
- **10.4.2 Composition with joint actions:** when shared state (`memInt`) can't be attributed to either component and communication is a *single* step both perform. Model as a **joint action** — put `Send`/`Reply` in *both* components' next-state actions (`NM`, `NE`). The environment needs an extra `rdy` variable (since it can't reference the memory's internal `ctl`). `Spec = (∃ rdy : IE ∧ □[NE]…) ∧ (∃ mem,ctl,buf : IM ∧ □[NM]…)` (module `JointActionMemory`). A joint action is necessarily noninterleaving.

## 10.5 A Brief Review

- **10.5.1 Taxonomy** (three independent axes, except joint-action ⇒ noninterleaving):
  - **Interleaving vs noninterleaving** — one component per step, or simultaneous steps allowed.
  - **Disjoint-state vs shared-state** — state partitionable among components, or some state changed by multiple.
  - **Joint-action vs separate-action** — a step of one component must occur simultaneously with a step of another, or not.
- **10.5.2 Interleaving reconsidered:** "can components act simultaneously?" is a meaningless question (a step is a math abstraction; overlapping real operations can be modeled either way). Choose whichever is convenient — *but* a noninterleaving spec won't generally implement an interleaving one (it allows simultaneous actions the latter forbids); a noninterleaving spec can be made interleaving by conjoining an interleaving assumption.
- **10.5.3 Joint actions reconsidered:** joint-action specs mix components' actions, destroying the separation that's the whole point of composing. They arise from highly abstract interfaces (`MemoryInterface` collapses two real communication steps into one instantaneous fiction, forcing both components' private state to change together). May occasionally be worth the added complexity, but not as a matter of course.

## 10.6 Liveness and Hiding

- **10.6.1 Liveness & machine closure:** specify liveness by fairness on individual components' actions (e.g. add `WF_hr[k](HCN(hr[k]))` per clock). Subscript question: use `v` (whole state) vs `v_c` (component state) — usually `v_c` isn't wanted. **Is a composition of machine-closed components machine closed?** For *interleaving* compositions, usually yes (each `Nₖ`'s fair actions are subactions of the whole `Next`). For noninterleaving/joint-action, not necessarily — the Ch. 9 Zeno example (9.2) is a joint-action composition where each component (clock, timer, `RTnow`) is machine closed but the whole is Zeno (not machine closed).
- **10.6.2 Hiding:** can `∃ h : (S₁ ∧ S₂)` be written as a composition? **No if `h` is shared** (communication state can't be made internal to separate components). If `h` occurs only in `S₂`: `(∃ h : S₁ ∧ S₂) ≡ S₁ ∧ (∃ h : S₂)`. If different *parts* of `h` occur in each (`S₁` uses `h.c1`, `S₂` uses `h.c2`): split into separate hidden variables.
  - **Compositional Hiding Rule:** if `h` doesn't occur in `Tᵢ` and `Sᵢ = Tᵢ` with `h[i]` substituted for `q`, then `(∃ h : ∀ i ∈ C : Sᵢ) ≡ (∀ i ∈ C : ∃ q : Tᵢ)` for finite `C`. (Fails for infinite `C` only pathologically.) For the interleaving array case where `Sᵢ` mentions all of `h` (via `[h EXCEPT ![i]=exp]`), transform `Sᵢ` into `Ŝᵢ` describing only `h[i]`; hiding `h` erases the interleaving difference.

## 10.7 Open-System Specifications

- All specs so far are **complete-system** (form `E ∧ M`, satisfied by correct behavior of both system `M` and environment `E`). An **open-system spec** describes correct system behavior *conditional on* the environment (a contract between user and implementer). Also called **rely-guarantee** / **assume-guarantee**.
- `M` alone is unimplementable (can't work under arbitrary environment). `E ⇒ M` is too weak (a bad system step could cause the environment to misbehave, making `E` false and the spec vacuously true — even though the system erred first).
- Introduce **`E ⇉ M`** ("`E` implies `M`, and `M` stays true at least one step longer than `E`"): `E ⇒ M`, and if `E`'s safety isn't violated in the first `n` states then `M`'s safety isn't violated in the first `n+1` states. (Precise def §16.2.4.) Open-system spec = **`E ⇉ M`**.
- Transform a composite complete-system spec into open-system by replacing `∧` with `⇉`, after deciding which conjuncts belong to environment, system, or neither. FIFO example: `□(IsChannel(in) ∧ IsChannel(out)) ∧ (in.ack=in.rdy) ∧ Sender ∧ Receiver ⇉ (out.ack=out.rdy) ∧ Buffer`. Little difference from writing the composite complete-system spec — they differ only at the end, in assembling the pieces.

## 10.8 Interface Refinement

Obtaining a lower-level spec by refining the *variables* of a higher-level one.
- **10.8.1 Binary hour clock (module `BinaryHourClock`):** display is a 4-bit register `bits`. Refine by substituting for `hr` in `HC` — but must use `HourVal(bits) ≜ IF bits ∈ [(0..3)→{0,1}] THEN BitArrayVal(bits) ELSE 99` (not bare `BitArrayVal`, whose value on illegal `bits` is unspecified — 99 forces `HC` false). `B ≜ INSTANCE HourClock WITH hr ← HourVal(bits)`. Alternative: `∃ hr : IR ∧ HC` with `IR ≜ □(hr = HourVal(bits))` (via a parametrized instance, since `hr` is already declared). `BHC ≜ ∃ hr : IR(bits,hr) ∧ H(hr)!HC`.
- **10.8.2 Refining a channel (module `ChannelRefinement`):** higher-level channel `h` sending numbers 1..12 refined to lower-level `l` sending each number as 4 separately-acknowledged bits (MSB first). `IR` relates `h` to `l` (and a hidden `bitsSent` remembering bits sent for the current number); `IR` sets `h` to an illegal `ErrorVal` if `l`'s behavior doesn't represent a valid bit protocol. `LSpec ≜ ∃ h : CR(h)!IR ∧ HS(h)!HSpec`.
- **10.8.3 In general:** `LSpec ≜ ∃ h₁,…,hₙ : IR ∧ HSpec` (10.9), where **`IR` is the interface refinement** — a component transforming the lower-level behavior of `l` into the higher-level behavior of `h` (`l → [IR] → h`). `IR` should be *independent of the system* (depend only on interface representation): `∃ h : IR` should be valid (any `l` behavior maps to some `h`).
  - **Data refinement** = the special case where `IR` has the form `□P`, `P` a state predicate expressing higher-level variables as functions of lower-level ones (e.g. `hr = HourVal(bits)`; the Ch. 3 `Channel`↔`AsynchInterface` equivalence is a data refinement). Channel-of-bits refinement is *not* data refinement (`h` depends on the *history* of bits, not `l`'s current state).
  - `LImpl` implements `HSpec` **under interface refinement `IR`** if `LImpl` implements some `LSpec` obtained from `HSpec` by `IR`.
- **10.8.4 Open-system specs:** interface refinement of open-system `HSpec` (with liveness) is subtler; who's blamed for a bad `l` change (system vs environment) determines the form. May fold `Liveness` into `IR` (`LSpec ≜ Liveness ⇒ ∃ h : IR ∧ HSpec` (10.11), etc.).

## 10.9 Should You Compose?

- Monolithic vs closed-composition vs open-system usually makes **little practical difference** — real specs are hundreds/thousands of lines; the forms differ only in the few lines assembling the pieces.
- Writing from scratch: **prefer monolithic** (easier to understand). Exceptions: real-time specs (write as conjunction of untimed + timing). Composition is sensible mainly when **reusing an existing spec** (compose a new component's spec with it, or write a lower-level version as an interface refinement) — rare, and often just as easy to modify/`EXTENDS` the original.
- Composition is just a new *way to write* a complete-system spec — doesn't change the spec; the choice is taste. Disjoint-state compositions are straightforward; **shared-state compositions can be tricky and need care.**
- **Open-system specs are mathematically different** (`E ∧ M` ≢ `E ⇉ M`). Needed for a true legal contract, or for composing off-the-shelf pre-specified components. But likely of theoretical interest only in the near future.

---
*Next: Chapter 11 — Advanced Examples.*
