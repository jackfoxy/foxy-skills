# Chapter 2 — Specifying a Simple Clock

Source: [SpecifyingSystems-21-07-04.pdf](~/eBooks/TLA+/SpecifyingSystems-21-07-04.pdf) (Leslie Lamport, *Specifying Systems*), pp. 15–22.

The first real example: an hour clock that cycles its display through 1..12. Introduces behaviors, states, steps, stuttering, the standard TLA `Init ∧ □[Next]_v` form, and the first complete `TLA⁺` module.

## 2.1 Behaviors

- A **state** is an assignment of values to variables.
- A **behavior** is a *sequence of states* representing a possible execution.
- We model execution as discrete steps (unlike physicists' continuous `F(t)`).
- **To specify a system = specify its set of allowed behaviors** (the ones representing correct execution).

## 2.2 An Hour Clock

Trivial system: a display cycling through 1..12; variable `hr` holds the display.

- A typical behavior: `[hr=11] → [hr=12] → [hr=1] → [hr=2] → …`
- A **step** is a pair of successive states, e.g. `[hr=1] → [hr=2]`.
- Two pieces:
  - **Initial predicate** `HCini ≜ hr ∈ {1,…,12}` — allowed starting states.
  - **Next-state relation (action)** `HCnxt ≜ hr' = IF hr ≠ 12 THEN hr+1 ELSE 1`. The primed `hr'` is the new-state value ("prime"). An **action** is a formula with primed and unprimed variables; true/false of a *step*.
- Combine into one formula with the temporal operator `□` ("box", = *always*):
  - `HCini ∧ □HCnxt` asserts init holds and every step satisfies `HCnxt`.
- **Stuttering steps** (`hr' = hr`, leaving `hr` unchanged) must be allowed so the clock composes with larger systems (e.g. a weather station changing `tmp` but not `hr`). TLA notation `[HCnxt]_hr ≜ HCnxt ∨ (hr' = hr)`.
- Final spec: **`HC ≜ HCini ∧ □[HCnxt]_hr`**.
- Allowing stuttering lets an infinite behavior end in infinite stuttering = a *halted* system, so only infinite behaviors are needed (no finite ones). Requiring the clock to *keep ticking* (no permanent stutter) needs liveness — deferred to Chapter 8.

## 2.3 A Closer Look at the Specification

- A state assigns values to **all** variables (a potential state of the whole universe), not just `hr`. E.g. a state may assign `√-2` to `hr` — a "universe after a bomb fell on the clock."
- A behavior **satisfies** `HC` iff `HC` is a true assertion about it. `HC` picks out exactly the behaviors where the clock works properly.
- `HC ⇒ □HCini` is a **theorem** (a formula satisfied by *every* behavior; logicians say *valid*): the spec implies `hr` is always a valid display value.

## 2.4 The Specification in TLA⁺

The complete `HourClock` module (typeset ↔ ASCII):

```
---- MODULE HourClock ----
EXTENDS Naturals
VARIABLE hr
HCini == hr \in (1 .. 12)
HCnxt == hr' = IF hr # 12 THEN hr + 1 ELSE 1
HC    == HCini /\ [][HCnxt]_hr
----
THEOREM HC => []HCini
====
```

Notes:
- Specs are partitioned into **modules**; this one is a single module `HourClock`.
- `EXTENDS Naturals` imports arithmetic operators (`+`, `..`), which are *not* built into `TLA⁺` (so `+` could mean matrix addition elsewhere). Logic/set operators (`∧`, `∈`) *are* built in.
- Every symbol must be built-in, declared, or defined; `VARIABLE hr` declares `hr`.
- `..` operator: `i..j` = set of integers from `i` through `j` (empty if `j < i`), so `1..12` replaces `{1,…,12}`.
- ASCII conventions: reserved words in caps (`EXTENDS`); symbols drawn pictorially (`□`→`[]`, `≠`→`#`); TeX notation otherwise (`∈`→`\in`); the exception `≜` is typed `==`.
- The dashed line `----` is purely cosmetic. `THEOREM` asserts the formula follows logically from the module's definitions + `Naturals` + the rules of `TLA⁺`.
- **The spec is the definition of `HC`.** Nothing in the module formally says `HC` (rather than `HCini`) is *the* specification — that meaning lies outside `TLA⁺`. `TLA⁺` is just a language for writing math; engineering judgment supplies the significance.

## 2.5 An Alternative Specification

- `Naturals` also defines modulus `%`: `i % n` = remainder of `i ÷ n` (unique number satisfying `(i%n ∈ 0..(n-1)) ∧ (∃ q ∈ Nat : i = q*n + (i%n))`).
- Rewrite next-state action using `%`: `HCnxt2 ≜ hr' = (hr % 12) + 1`, giving `HC2 ≜ HCini ∧ □[HCnxt2]_hr`.
- `HCnxt` and `HCnxt2` are **not** equivalent as actions (differ on states with `hr` outside 1..12, e.g. `hr=24`). **But** for any behavior starting in an `HCini` state they agree, so `HC ≡ HC2` **is a theorem**. Either may serve as the spec.
- General lesson: **math offers infinitely many ways to write the same thing** (`12 = 6+6 = 3∗4 = 141−129`). When a spec choice yields *equivalent* specs, pick the clearest; when it doesn't, you must decide which one you actually mean.

---
*Next: Chapter 3 — An Asynchronous Interface.*
