# Chapter 14 — The TLC Model Checker

Source: [SpecifyingSystems-21-07-04.pdf](~/eBooks/TLA+/SpecifyingSystems-21-07-04.pdf) (Leslie Lamport, *Specifying Systems*), pp. 221–264.

The final and longest chapter of Part III: a user's guide to **TLC** (by Yuan Yu), the model checker for `TLA⁺`. TLC explores the reachable states of a finite model of a spec, checking invariants and (some) temporal properties and printing a minimal error trace when a property fails. It handles specs of the form `Init ∧ □[Next]_vars ∧ Temporal` but **cannot handle hiding** (temporal `∃`). The chapter covers what TLC can cope with, how it computes states and checks properties, the `TLC` standard module, and a large practical section on running and debugging.

## 14.1 Introduction to TLC

- The running example is the **alternating bit protocol** (`AlternatingBit`). To run it you write a **model module** (`MCAlternatingBit`) that `EXTENDS` the spec and a **configuration file** (`.cfg`).
- Config-file statements: `SPECIFICATION` (or `INIT`/`NEXT`), `INVARIANT`, `PROPERTY`, `CONSTANT` (assign `CONSTANT Data = {d1,d2}` **model values**, or replace an operator `c <- d`), `CONSTRAINT` (a predicate limiting the state space to keep it finite).
- Without a property, TLC still checks for "silliness" (evaluating an undefined/nonsensical expression) and, unless disabled, **deadlock** — a reachable state with no successor, i.e. a violation of `□(ENABLED Next)`.
- `ABCorrectness` is an ex-post-facto higher-level spec the protocol is checked against.

## 14.2 What TLC Can Cope With

### 14.2.1 TLC Values
- Four kinds: **Booleans**, **Integers**, **Strings**, and **model values** (unspecified primitive constants, unequal to all other values, equal only to themselves). Values built from these with sets, functions, tuples, records. **Comparability** rules govern which values may be compared (see §14.7.2).

### 14.2.2 How TLC Evaluates Expressions
- Evaluates **left-to-right**, expanding definitions. Can enumerate bounded quantifiers/sets/functions (`∃ x ∈ S`, `{x ∈ S : p}`, `[x ∈ S ↦ e]`, `CHOOSE x ∈ S : p`) only when `S` is a **finite** set it can compute. Cannot enumerate over infinite sets (e.g. `Nat`) or evaluate an unbounded `CHOOSE`.
- Recursion pitfalls: a recursively defined operator/function must actually terminate on the values TLC computes.

### 14.2.3 Assignment and Replacement in the Configuration File
- **Assignment** `c = v` gives constant `c` a value; **replacement** `c <- d` replaces operator `c` with an operator `d` defined in the model module. Used to substitute TLC-computable definitions for ones TLC can't handle (e.g. replace `Nat` with `0..n`).

### 14.2.4 Evaluating Temporal Formulas
- TLC evaluates only **"nice"** temporal formulas — four classes built from state predicates and box-action formulas `□[A]_v`, plus simple temporal formulas whose component expressions TLC can evaluate.
- It **cannot** evaluate a plain `◇⟨A⟩_v` alone, nor `WF`/`SF` conjuncts whose action it can't evaluate on the relevant step. A `PROPERTY` may name any formula TLC can evaluate; a `SPECIFICATION` formula must have exactly one box-action conjunct (the next-state action).

### 14.2.5 Overriding Modules
- TLC can't compute `2 + 2` from the `Naturals` definition of `+` efficiently — arithmetic is implemented directly in **Java**. A general **module-overriding** mechanism loads a Java class in place of a module's definitions when it sees `EXTENDS`. Overridden standard modules: `Naturals`, `Integers`, `Sequences`, `FiniteSets`, `Bags`, and the `TLC` module (§14.4). Writing your own Java override is "not too hard."

### 14.2.6 How TLC Computes States
- A **state** = assignment of values to variables. TLC computes **successor states** of a state `s` by assigning `s`'s values to the unprimed variables, no values to the primed, then evaluating the next-state action.
- Two differences from ordinary evaluation: (1) it does **not** evaluate disjunctions / `∃ x∈S` / implications left-to-right but **splits** them into separate evaluations (one per disjunct / element); (2) for a variable `x` not yet assigned, evaluating `x' = e` (or `x' ∈ S`) **yields TRUE and assigns** `x'`. `UNCHANGED ⟨e₁,…,eₙ⟩` becomes the conjunction of `UNCHANGED eᵢ`.
- **Conjunct order matters**: TLC reports an error if it hits a primed variable that hasn't been assigned yet, or a "silly" expression like `Tail(⟨⟩)`. So put assignments before uses. (Worked example on `(14.4)` finding successor states.)
- The description isn't literally exact (bizarre actions like `(14.6)` produce error messages); it evaluates the **initial predicate** analogously. Evaluates `ENABLED A` by computing whether `A` has a successor; evaluates action composition `A · B` (page 77) by first computing `A`-successors then checking `B`.

## 14.3 How TLC Checks Properties

Defines the formulas derived from the config file: **Init**, **Next**, **Temporal**, **Invariant**, **ImpliedInit**, **ImpliedAction**, **ImpliedTemporal**, **Constraint**, **ActionConstraint** (an `ACTION-CONSTRAINT` eliminates transitions rather than states; ordinary constraint `P` ≡ action constraint `P'`).

### 14.3.1 Model-Checking Mode (default)
- Keeps a directed graph **𝒢** (nodes = states) and a queue **𝒰** of states whose successors aren't yet computed. Algorithm:
  1. Check every `ASSUME`.
  2. Compute initial states; for each, check `Invariant` and `ImpliedInit`, and add to 𝒢/𝒰 if `Constraint` holds.
  3. While 𝒰 nonempty: pop `s`, compute successors `T`; if `T` empty and deadlock-checking on, report **deadlock**; for each successor `t` check `Invariant` and `ImpliedAction` on `s→t`, and add new `t` satisfying `Constraint`/`ActionConstraint`.
- Steps 3(b)–(d) can be run by multiple threads (`workers` option). `ImpliedTemporal` is checked **periodically** and at the end over the behaviors in 𝒢 (`Temporal ⇒ ImpliedTemporal`). Computation of 𝒢 terminates **only if reachable states are finite** — otherwise TLC runs forever.

### 14.3.2 Simulation Mode
- Repeatedly constructs and checks individual random **behaviors** of bounded length (`depth`, default 100). Runs until stopped. Uses a pseudorandom generator with a **seed** and **aril**; both are printed on error so you can (via `seed`/`aril` options) regenerate the failing behavior.

### 14.3.3 Views and Fingerprints
- The nodes of 𝒢 are really values of a **view** (default = tuple of all declared variables). `VIEW myview` sets an alternate view. A nonstandard view (e.g. dropping debugging variables) can reduce the state count but may cause safety checks to still be correct while **`ImpliedTemporal` may be checked incorrectly**.
- Implementation stores **fingerprints** (64-bit hashes) of views, not the views themselves. A **collision** (prob ≈ 2⁻⁶⁴ per pair) can make TLC miss states. On termination TLC prints two collision-probability estimates (one theoretical, one empirical "near miss"). Views/fingerprints apply to model-checking mode only.

### 14.3.4 Taking Advantage of Symmetry
- A spec is **symmetric** w.r.t. a permutation π of a set of model values iff every behavior σ satisfies it iff σ^π does. The Chapter 5 memory specs are symmetric under permutations of `Proc` (and `Adr`).
- `SYMMETRY Perms` (with `Perms = Permutations(Proc)`, from the `TLC` module) tells TLC to skip a state if an equivalent one (under some permutation) is already in 𝒢 — reducing states by up to `n!`. The symmetry set may be an arbitrary set of permutations of model values; used in model-checking mode only.
- **Caution:** `Invariant`/`ImpliedInit`/`ImpliedAction` checking stays correct, but **`ImpliedTemporal` checking may be wrong** with a symmetry set (may miss/invent errors or give a bad counterexample). If the spec isn't symmetric for all permutations in the set, TLC may fail to print an error trace ("Failed to recover the state from its fingerprint").

### 14.3.5 Limitations of Liveness Checking
- A **safety** violation always has a finite counterexample → discoverable. A **liveness** violation may be impossible to discover with a finite model. Example: `EvenSpec` (starts `x=0`, repeatedly `+2`, `WF`) — with a finite-state constraint, all generated infinite behaviors end in infinite stuttering where the action is disabled/never taken, so TLC won't report the (true) failure of `◇(x=1)`.
- **Advice:** make sure your finite model permits infinite behaviors satisfying the spec's liveness condition, and sanity-check by having TLC verify a liveness property the spec does **not** satisfy (confirm it reports an error).

## 14.4 The `TLC` Module

The standard `TLC` module (Figure 14.5) defines handy operators; usually your spec module `EXTENDS TLC`, which is overridden by a Java implementation.
- **`Print(out, val) ≜ val`** — but evaluating it prints `out` and `val` (debugging aid; often placed inside `IF/THEN` to limit output).
- **`Assert(val, out)`** — equals TRUE if `val = TRUE`; otherwise prints `out` and halts.
- **`JavaTime`** — an arbitrary `Nat`, but TLC yields the current wall-clock time (ms since 1 Jan 1970 UT, mod 2³¹); combine with `Print` to find slow operators.
- **`d :> e`** and **`f @@ g`** — build/combine functions; `d₁:>e₁ @@ … @@ dₙ:>eₙ` is the function with domain `{d₁,…,dₙ}` mapping each `dᵢ↦eᵢ`. (`⟨"ab","cd"⟩` = `1:>"ab" @@ 2:>"cd"`.) TLC uses these to print function values.
- **`Permutations(S)`** — set of all permutations of finite `S` (for `SYMMETRY`). Explicit permutations via `:>`/`@@` express more complex symmetries (e.g. permuting processors together with their addresses).
- **`SortSeq(s, ≺)`** — sorts sequence `s` by total order `≺`; its efficient Java implementation lets you write a fast `FastSort` replacing a user-defined `Sort`.

## 14.5 How to Use TLC

### 14.5.1 Running TLC
- Command: `program_name options spec_file` (e.g. `java tlatk.TLC`). Each module `M` in its own `M.tla`. Options include:
  - **`-deadlock`** (don't check deadlock), **`-simulate`**, **`-depth num`**, **`-seed num`**, **`-aril num`** (simulation controls);
  - **`-coverage num`** (print how often each action conjunct fires — a `0` count flags dead/too-small parts), **`-recover run_id`** (restart from a checkpoint), **`-cleanup`** (delete old run files), **`-difftrace`** (abridged error states), **`-terse`** (shorter values);
  - **`-workers num`** (threads — no more than #processors), **`-config config_file`** (`.cfg`; defaults to `spec_file`'s name), **`-nowarning`** (suppress warnings about likely-erroneous but legal expressions like `[f EXCEPT ![v]=e]` with `v ∉ DOMAIN f`).

### 14.5.2 Debugging a Specification
- **Normal output:** version/date; mode (`Model-checking` or `Running Random Simulation with seed …`); optional `Implied-temporal checking--relative complexity = N` (liveness time ∝ complexity, always slower than safety); `Finished computing initial states`; periodic `Progress(diameter): N states generated, M distinct, K left on queue`; on success `Model checking completed. No error has been found.` plus collision estimates and final totals + **diameter**. May print `-- Checkpointing run …` (a run id usable with `recover`).
- **Error reports:**
  - Syntax errors → `ParseException in parseSpec:` then the Syntactic Analyzer's message (Ch. 12); run SANY early.
  - **Invariant violated** → `Invariant Inv is violated` and a **minimal-length behavior** printed as a sequence of states (each a `TLA⁺` predicate; the action producing each state is named, e.g. `<Action at line 66 in AlternatingBit>`).
  - Hardest errors: TLC forced to evaluate something it can't handle or a "silly" value (e.g. an off-by-one making `q[0]` out of domain) → `Error: Applying tuple … to integer 0 which is out of domain`, a behavior leading there, and the **nested-expression positions** (a tree, high-level first) locating the fault. May need `Print` to pinpoint.

### 14.5.3 Hints on Using TLC Effectively
- **Start Small** — begin with a tiny model (one-element sets, length-one queues); it catches most simple errors fast. Increase size gradually (reachable states grow ~exponentially). Then try simulation mode on larger models (may get lucky on subtle errors).
- **Be Suspicious of Success** — safety is trivially satisfied by doing nothing (a forgotten `SndNewValue` still passes). Use `coverage`; verify TLC **reports violations** of properties that *should* be violated (e.g. `∀ d : (sent=d) ⇒ □(sent=d)` should fail if `sent` changes); check that expected reachable states actually occur (via an invariant that should fail, or `Print` in an invariant).
- **Let TLC Help You Figure Out What Went Wrong** — name invariant conjuncts separately so TLC says which fails; add `Print`; define an `ErrorState` predicate (copied from the last state of the trace) as a new `INIT` to rerun from the failure without recomputing everything (also works for `□[A]_v`: use next-to-last state as init and last state primed as next-state). Model values in the trace must be declared as constants and assigned to themselves.
- **Don't Start Over After Every Error** — fixing may take several tries; recheck a correction by starting from the failing state, or use **checkpoints** + `recover` (a checkpoint saves 𝒢 and 𝒰 only; restart is valid as long as the view and symmetry set are unchanged).
- **Check Everything You Can** — verify all properties you expect (higher- and lower-level), e.g. an invariant `Cardinality({msgQ[i] : …}) ≤ 2`. Testing a conjectured invariant teaches you about the spec even when it holds.
- **Be Creative** — even specs outside TLC's reach may be checkable via `CONSTANT` replacement (e.g. replace `Nat` with `0..n`, changing the meaning but still finding errors — the goal is finding errors, not proving correctness).
- **Use TLC as a `TLA⁺` Calculator** — a module with only `ASSUME` statements (no spec) lets TLC evaluate expressions (`Print(g[2], TRUE)`), check tautologies (`∀ F,G ∈ BOOLEAN : (F⇒G) ≡ (¬F ∨ G)`), or hunt counterexamples to a conjecture. Still needs a config file, even an empty one.

## 14.6 What TLC Doesn't Do

- No program can generate all behaviors of an arbitrary spec. Java overrides of `Naturals`/`Integers` handle only `−2³¹ .. 2³¹−1` (error outside). Two deliberate deviations from `TLA⁺` semantics (for efficiency):
  1. **`CHOOSE`** is only guaranteed consistent when the set expressions are *syntactically* identical — `CHOOSE x∈{1,2,3}:x<3` and `CHOOSE x∈{3,2,1}:x<3` may differ. (This also affects `CASE`, defined via `CHOOSE`.)
  2. **Strings** are treated as primitive values, not as sequences — so `"abc"[2]` is an error to TLC even though it's legal `TLA⁺`.

## 14.7 The Fine Print

### 14.7.1 The Grammar of the Configuration File
- Given precisely by module `ConfigFileGrammar` (Figure 14.6), which `EXTENDS BNFGrammars` (§11.1.4); `ConfigGrammar.File` is the set of syntactically correct comment-stripped config files. Extra restrictions: at most one `INIT`, one `NEXT`, one `SPECIFICATION` (allowed only if no `INIT`/`NEXT`), one `VIEW`, one `SYMMETRY`; multiple instances of other statements are allowed and merged (e.g. two `INVARIANT` lines = one combined list).

### 14.7.2 Comparable TLC Values
- Precise rule for when two TLC values are **comparable**:
  1. Two **primitive** values are comparable iff same value type (so `"abc"`/`"123"` comparable; `"abc"`/`123` not).
  2. A **model value** is comparable with any value (equal only to itself).
  3. Two **sets** are comparable iff same cardinality **or** all elements of one are comparable with all of the other (`{1}` vs `{"a","b"}` comparable by cardinality difference; `{1,2}` vs `{"a","b"}` **not**).
  4. Two **functions** `f`,`g` comparable iff their domains are comparable and, when domains equal, `f[x]`/`g[x]` comparable for every `x` (`⟨1,2⟩` vs `⟨"a","b","c"⟩` comparable; `⟨1,"a"⟩` vs `⟨2,"bc"⟩` comparable; `⟨1,2⟩` vs `⟨"a","b"⟩` **not**).

---
*End of Part III. Next: Part IV — The TLA⁺ Language (Chapter 15 — The Syntax of TLA⁺).*
