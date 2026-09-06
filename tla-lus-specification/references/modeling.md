# Modeling and Specification

Use this reference to design or review a system model before focusing on syntax or tool options.

## Semantic frame

- A state assigns values to all declared variables.
- A step is a pair of consecutive states.
- A behavior is an infinite sequence of states.
- A specification is a temporal formula selecting the allowed behaviors.
- A state predicate is Boolean-valued in one state. An action is Boolean-valued on a step. A temporal formula is Boolean-valued on a behavior.
- Safety says what must not happen; a violation has a finite bad prefix. Liveness says what must eventually happen; no finite prefix alone proves a violation.
- TLA+ specifications normally permit stuttering so that an implementation can take steps invisible at the current abstraction level and independently specified components can compose.

The canonical safety form is:

```tla
vars == <<x, y, z>>

Spec == Init /\ [][Next]_vars
```

`[Next]_vars` abbreviates `Next \/ UNCHANGED vars`. Do not use `[]Next`; a raw action is not stuttering-invariant.

## Select the abstraction deliberately

Before declaring variables, answer:

- What design risk should the model expose?
- Which part of the real system is inside the model, and which part is environment?
- Which externally visible events define correctness?
- What failures, delays, reordering, duplication, or loss are possible?
- Which changes are atomic in the model?
- Which details can vary without changing the property being checked?

Prefer the simplest abstraction that still exposes the suspected errors. For concurrency work, model control state, ownership, queues, messages, and failure transitions precisely; abstract irrelevant byte layouts and computation. If an abstraction hides a meaningful race, refine the grain of atomicity.

Write short sample behaviors before the module. Include normal operation, concurrent operations, boundary cases, retries, and failures. Derive candidate actions from the transitions between states.

## Standard module skeleton

```tla
------------------------------ MODULE Example ------------------------------
EXTENDS Naturals, Sequences

CONSTANTS Node, MaxQueue
ASSUME /\ Node # {}
       /\ MaxQueue \in Nat \ {0}

VARIABLES pc, queue

vars == <<pc, queue>>

TypeOK ==
  /\ pc \in [Node -> {"idle", "busy"}]
  /\ queue \in Seq(Node)

Init ==
  /\ pc = [n \in Node |-> "idle"]
  /\ queue = <<>>

Start(n) ==
  /\ n \in Node
  /\ pc[n] = "idle"
  /\ Len(queue) < MaxQueue
  /\ pc' = [pc EXCEPT ![n] = "busy"]
  /\ queue' = Append(queue, n)

Finish(n) ==
  /\ n \in Node
  /\ pc[n] = "busy"
  /\ pc' = [pc EXCEPT ![n] = "idle"]
  /\ UNCHANGED queue

Next == \E n \in Node : Start(n) \/ Finish(n)

Spec == Init /\ [][Next]_vars

THEOREM Spec => []TypeOK
=============================================================================
```

Adjust names and operators to the repository's conventions. Keep `vars` complete. Each nonstuttering action should constrain all next-state variables through assignments, membership, or `UNCHANGED`.

## Constants, variables, and types

- Use constants for model parameters fixed across a behavior: process sets, capacities, topology, operator parameters.
- Use variables only for state that may change.
- Put only constant-level facts in `ASSUME`: nonempty sets, numeric bounds, and assumptions on constant operators.
- Express types as a state predicate such as `TypeOK`, then check `Spec => []TypeOK`.
- The language does not enforce `TypeOK`. Every action must preserve it.
- If two variants must be provably distinct, represent them with tagged records, such as `[tag |-> "Nat", value |-> 1]` and `[tag |-> "Text", value |-> "1"]`.

Start invariant work with:

```tla
Init => Inv
Inv /\ [Next]_vars => Inv'
Inv => SafetyProperty
```

`Inv` may need to be stronger than the desired property. A property can be invariant of the full spec without being inductive by itself.

## Action design

Structure an action as enabling conditions followed by next-state effects:

```tla
Receive(p, msg) ==
  /\ CanReceive(p, msg)
  /\ inbox' = [inbox EXCEPT ![p] = Append(@, msg)]
  /\ UNCHANGED <<pc, network>>
```

Use:

- `x' = expression` for a determined next value.
- `x' \in SetExpression` for a nondeterministic next value.
- `UNCHANGED <<...>>` for untouched variables.
- `Next == \/ Action1 ... \/ ActionN` or an existential over an indexed family of actions.

Factor state functions and predicates when they clarify the model. Avoid burying control flow in deeply nested expressions. Move existential quantification outside a disjunction when the same bound selects the participating entity.

Conjunct order can matter to TLC even when the formula is mathematically equivalent: place assignments before expressions that inspect the assigned primed value, and guard partial operations such as `Head`, `Tail`, and out-of-domain function application.

## Data representation

- Sets model unordered unique collections.
- Sequences model ordered queues and logs.
- Bags model unordered collections with multiplicity, such as lossy or duplicating networks.
- Functions model arrays, maps with fixed domains, and indexed process state.
- Records model heterogeneous named fields and tagged variants.
- Tuples model fixed-position products and also are functions over `1..n`.

Prefer records over tuples when field position could be confused. Prefer a single function variable such as `pc \in [Node -> PCState]` over one variable per process. Use `EXCEPT` to update functions and nested structures.

Remember:

- `f' = [i \in S |-> e]` determines the whole next function.
- `\A i \in S : f'[i] = e` does not establish the domain or even that `f'` is a function.
- `[f EXCEPT ![k] = e]` leaves every other domain element unchanged.
- `@` in an `EXCEPT` clause denotes the old value at that clause's target.

## Atomicity and concurrency

The grain of atomicity is a correctness decision, not formatting. Coarser actions simplify the model but may hide interleavings. Finer actions add intermediate control states and behaviors.

An operation can safely be coarsened only when the omitted interleavings do not affect the checked properties. Commutativity offers a proof technique: independent actions commute when neither changes state used or changed by the other and neither enables or disables the other. Do not routinely encode action composition with `A \cdot B`; explicit intermediate control state is usually clearer and easier to check.

## High-level correctness models

Distinguish:

- A low-level operational model: what components do.
- A high-level correctness model: what externally observable histories mean.
- A data-structure module: variable-free mathematical operators.

For linearizability or sequential consistency, history variables and an ordering relation can express which abstract execution explains observed operations. Make the obligations explicit:

- whether all operations in an infinite behavior must eventually be ordered;
- whether future operations may explain earlier results;
- whether prior explanations may change;
- per-client program order;
- the write observed by each read;
- completion and pending-operation policy.

History-based specifications are powerful and easy to underconstrain. Check small litmus tests that should pass and fail. A deliberately non-machine-closed high-level spec may express the intended observational condition, but document that it is not directly implementable.

## Review checklist

- Does `Init` have at least one state under the model constants?
- Does each intended action have a reachable enabling state?
- Does every action constrain every primed variable?
- Are partial operators guarded?
- Does `Next` include all intended system and environment steps?
- Are fault transitions included at the correct atomicity?
- Is `vars` complete and used consistently?
- Does `Init` imply the declared type invariant?
- Is the safety property actually stronger than `TypeOK`?
- Are liveness requirements separated from safety?
- Can an implementation stutter at this abstraction level?
- Do test traces cover the intended concurrency and failure cases?

## Running the model on `%tla-lus`

The modeling advice above is tool-independent, but three things about this
engine change how you should shape a spec you intend to check here:

- **Every model is bounded by `limits`, not by patience.** `max-states`
  (default 100.000) and `max-depth` (default 1.000) end a run with a typed
  `%limited` carrying the statistics so far. Design the `CONSTANT` sets small
  enough that the interesting behaviours are reachable inside the bound, and
  say so when you report a result: a `%limited` run proves less than an `%ok`
  one, and a `CONSTRAINT`-bounded `%ok` proves less again.
- **State identity is an FP64 fingerprint orbit representative**, never
  rendered text — so `SYMMETRY` genuinely collapses the graph, and two states
  that print alike are not thereby equal.
- **The engine is untyped in exactly the way TLA+ is.** `TypeOK` is an
  invariant you must list in the `.cfg`, not a declaration. Write it, check it
  first, and check it *before* the properties you actually care about: almost
  every confusing counterexample here is a type error the model never
  prohibited.

Two port-specific facts worth designing around:

- **Strings and model values order lexicographically**, not by Java intern
  order. Anything whose result depends on set iteration order will differ from
  the Java tool — deliberately, and documented (`tla-lus-parity`).
- **An unseeded run uses seed 0** and is therefore reproducible. A spec drawing
  from `TLC!RandomElement` or `Randomization` gives the same answer every run
  here; at the pin it does not.
