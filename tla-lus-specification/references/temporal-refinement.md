# Temporal Reasoning, Composition, and Refinement

Use this reference for liveness, hiding, implementation arguments, composition, and real-time constraints.

## Safety, liveness, and temporal reasoning

For a behavior suffix beginning at state `i`, `[]F` requires `F` at every suffix and `<>F` requires `F` at some suffix. Consequently:

- `~[]F <=> <>~F`.
- `[](F /\ G) <=> []F /\ []G`.
- `<>(F \/ G) <=> <>F \/ <>G`.
- `[]` does not distribute over disjunction, and `<>` does not distribute over conjunction.
- `[]<>F` means infinitely often.
- `<>[]F` means eventually forever.
- `F ~> G` means `[](F => <>G)`.

A proof rule such as generalization from `F` to `[]F` is not the formula `F => []F`. Keep meta-level inference distinct from temporal implication.

## Fairness

Use the complete variable tuple `vars`:

```tla
Liveness ==
  /\ \A p \in Proc : WF_vars(Handle(p))
  /\ \A p \in Proc : SF_vars(Retry(p))

Spec == Init /\ [][Next]_vars /\ Liveness
```

- `WF_vars(A)`: if `<<A>>_vars` eventually remains enabled continuously, nonstuttering `A` steps occur infinitely often.
- `SF_vars(A)`: if `<<A>>_vars` is enabled infinitely often, nonstuttering `A` steps occur infinitely often.
- Strong fairness implies weak fairness. Use strong fairness only when another action can repeatedly disable and re-enable `A`, permitting starvation under weak fairness.
- Do not add fairness to environment choices merely to make a desired theorem pass unless the environment contract actually promises it.
- Prefer a conjunction of `WF`/`SF` on named subactions to an ad hoc temporal response formula.

Combining fairness conditions on disjunctions or moving quantifiers inside fairness is not generally valid. It requires a disjointness argument: once one indexed action is enabled, another cannot become enabled before the first occurs, or an equivalent property appropriate to the fairness form.

## Machine closure

A safety-plus-liveness spec is machine closed when every finite behavior allowed by its safety part extends to an infinite behavior satisfying the liveness part. This prevents liveness from retroactively forbidding a finite safety prefix.

A practical sufficient form is:

```tla
Init /\ [][Next]_vars /\ Fairness
```

where `Fairness` is a conjunction of weak or strong fairness on subactions `A` satisfying `A => Next`.

Audit machine closure when:

- fairness names an action that is not a subaction of `Next`;
- liveness is written directly with nested temporal operators;
- a high-level spec permits guesses that later obligations must justify;
- real-time bounds can become mutually inconsistent;
- component composition introduces joint constraints.

Non-machine-closed high-level correctness conditions can be intentional, but are not directly implementable specifications. State that distinction.

## Hiding and refinement mappings

Temporal existential quantification hides a flexible variable. The common module idiom is:

```tla
Inner(h) == INSTANCE Internal WITH hidden <- h
ExternalSpec == \EE h : Inner(h)!Spec
```

Intuitively, a visible behavior satisfies the result if some stuttering-equivalent augmentation with `h` satisfies the internal spec. This is not ordinary per-state existential quantification.

To prove a concrete spec `CSpec` implements an abstract spec `ASpec`, show `CSpec => ASpec`. When abstract state is hidden, construct state functions of concrete variables as witnesses: the refinement mapping.

Proof obligations:

1. Concrete initial states map to abstract initial states.
2. Under a strong concrete inductive invariant, every concrete `Next` step maps either to an abstract `Next` step or to stuttering of all mapped abstract variables.
3. The mapping is defined and correctly typed on all reachable concrete states.
4. Concrete liveness implies abstract liveness. Recalculate enablement; substitution does not automatically distribute through fairness.

The central step obligation has the shape:

```tla
Inv /\ CNext => ANextBar \/ UNCHANGED abstractVarsBar
```

If no state function can map the concrete present to the abstract present because the abstraction depends on history or prophecy, use a refinement relation with hidden auxiliary state, a history variable, or a prophecy variable. Keep interface refinement independent of a specific implementation when it is intended to define a reusable representation mapping.

## Composition

The composition of component specifications is conjunction because each formula constrains the same universe:

```tla
System == ComponentA /\ ComponentB
```

Classify the composition along three axes:

- Interleaving or noninterleaving: at most one component acts per step, or simultaneous component actions are permitted.
- Disjoint or shared state: components own separate state, or multiple components constrain/change common state.
- Separate or joint actions: communication uses distinct steps, or one step must satisfy actions from multiple components.

Conjoining ordinary stuttering-closed component specs generally permits simultaneous nonstuttering actions. To require interleaving, encode ownership in actions or conjoin an explicit global interleaving constraint. Do not assume physical simultaneity determines the correct mathematical choice.

Shared-state composition needs explicit attribution of every possible shared-state change. Joint-action composition couples component internals and weakens modularity; use it when the abstraction genuinely treats communication as one atomic event.

Hiding distributes over a conjunction only when the hidden variable is absent from the other conjunct. Shared hidden communication state cannot generally be hidden independently in each component.

For most new system specifications, a monolithic `Next` is easier to understand. Composition is most valuable when reusing a separately specified component, expressing timing as a conjunct, or defining an interface refinement.

## Complete-system and open-system specifications

A complete-system specification constrains both a system and its environment, commonly `Environment /\ Machine`. An open-system specification expresses blame-sensitive rely/guarantee behavior: the machine must remain correct through the step in which the environment first violates its obligation. Ordinary implication `Environment => Machine` is too weak because a machine error may cause the environment predicate to become false and make the implication vacuous.

Use the TLA+ guarantee operator described by the source (`E -+-> M` in tool-supported ASCII if available; verify exact syntax in the target parser) only when a genuine open-system contract is required. Assign initialization and shared constraints deliberately to environment, machine, or neutral context. Prefer a complete-system model for ordinary design checking unless the distinction changes the result.

## Real time

Represent real time with a variable `now` and permit it to advance by arbitrary positive real amounts while discrete system variables remain unchanged. A correct real-time model must also rule out time stopping or converging below a finite bound.

Use timer variables or reusable bounds to express:

- a minimum delay before a nonstuttering action may occur;
- a maximum duration that an action may remain continuously enabled without occurring;
- resetting the timer when the action occurs or becomes disabled.

Hide auxiliary timers from the external specification. A finite upper bound plus non-Zeno time progress generally supplies weak fairness for the bounded action.

Audit for Zeno behavior: infinitely many steps while `now` stays bounded. Inconsistent minimum/maximum bounds may leave only Zeno behaviors, so adding non-Zeno progress makes the spec false. A robust implementation-level pattern applies compatible bounds to mutually exclusive subactions of `Next`, with `0 <= min <= max`, and separately requires `now` to increase without bound.

High-level timing properties may bound an abstract response action that is not literally a `Next` subaction. In that case, establish non-Zenoness directly rather than relying on the sufficient subaction rule.

Hybrid systems extend the same model with continuous physical variables whose next values are constrained by mathematical evolution over `now..now'`. Treat the ODE/PDE solution operator as part of the mathematical model and make discrete mode switches explicit.

## Expert review questions

- Is the liveness obligation stronger than the real implementation or environment can guarantee?
- Can another action interrupt enablement forever, requiring strong rather than weak fairness?
- Does the fair action imply `Next`?
- Does hiding erase behavior needed to state or check the property?
- Does the refinement mapping turn some concrete steps into abstract stuttering?
- Is abstract enablement preserved well enough to derive fairness?
- Does conjunction introduce simultaneous or joint steps not intended by either component?
- Can time diverge, and are timing bounds jointly satisfiable?
- Is a high-level non-machine-closed spec being mistakenly presented as executable behavior?

## What this engine checks, and how

- **The full liveness stack is live**: temporal-property normalization
  (`lib/temporal`), the Manna–Pnueli particle tableau (`lib/tableau`), the
  product graph, the SCC verdict, and the lasso counterexample
  (`lib/liveness`). `<>P`, `[]<>P`, `[]P`, `~>`, `-+->`, `<>[]`, and `WF_`/`SF_`
  all run. A pure `[]P` box-state property routes to the invariant engine.
- **A formula the normalizer cannot decompose is refused with the pin's own
  message** — `TLC cannot handle the temporal formula …` — not a port-specific
  one. If you see that, the Java tool would refuse it too.
- **A runaway `RECURSIVE` temporal expansion stops at `+expand-cap`** (1.000
  nested expansions) and says so by name. tlc2 inlines until the JVM stack
  overflows (EC 1005). Neither side produces a verdict; only the message
  differs.
- **Temporal hiding (`\EE x : F`) is not supported**, as in classic TLC. Model
  the hidden state explicitly, or check the refinement mapping instead.
- **`VIEW` and `ALIAS` are refused *in combination with* a temporal
  `PROPERTY`** — the liveness graph is not view-keyed and the lasso trace is
  not aliased. Both are live on every safety path.
- **DFID does not do liveness** and refuses a genuine temporal `PROPERTY`
  verbatim, exactly as at the pin (upstream issue 548). A `[]P` box-state runs,
  because it is an invariant.
- **Property attribution is post-hoc, as at the pin.** With a lasso built, the
  violated property is recomputed from the counter-example
  (`+eval-on-lasso`/`+violated-props`), so a two-`PROPERTY` spec names the one
  the behaviour actually violates — including tlc2's plural message forms
  (`Temporal properties P1 and P2 were violated.`).

### Checking a refinement

There is no dedicated refinement mode. Do what the Java tool does: write the
refinement mapping as definitions in the implementation module, instantiate the
abstract module under those substitutions, and list the instantiated
specification as a `PROPERTY`. Then check, separately:

1. initial-state correspondence,
2. step simulation, including the mapped **stuttering** steps, and
3. liveness, which the safety argument does not give you.

Report which of the three you actually checked. A green run over a finite
model is evidence for that model, not a proof of implementation.
