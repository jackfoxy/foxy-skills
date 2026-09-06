# The Override Mechanism

## How it works

In tlc2, a `StandardModule`'s TLA+ body is usually a deliberate dummy that the
Java class in `tlc2.module` **overrides** at load time. `desk/lib/stdops.hoon`
is the Hoon equivalent of that binding.

**The key is `[module operator arity]`, never a bare name.** An override beats
the operator's vendored TLA+ body; an operator with neither an override nor an
explicit body classification is a **typed rejection naming itself**, so nothing
silently evaluates the dummy.

```hoon
+$  op-key   [module=@t name=@t arity=@ud]
```

The registry entry carries the implementation plus its **argument contract**:
whether each argument is lazy, and the operator's `minLevel`.

## Three machine-checked properties

`tools/gen-stdops-tests.py` proves all three against the pinned tree, so the
registry cannot drift from the pin:

1. **Every registry key is an operator the pin declares** and classifies as
   required.
2. **The body-evaluable set equals the pin's un-overridden operators** — so an
   operator the pin evaluates from its TLA+ body (like `Bags!SubBag`) is
   evaluated from its body here too, and one the pin overrides is overridden
   here.
3. **Each operator's laziness and `minLevel` equal its pinned annotation.**

11 differential cases run through `desk/tests/lib/stdops-diff.hoon`; the
hand-written suites are `tests/lib/stdops.hoon` and `tests/lib/tlcmod.hoon`.

## When an override is not enough

Operators needing more than evaluated values — an **operator argument**, a
**lazy set**, or the unevaluated node of an `@Evaluation` override — are
dispatched to `desk/lib/node-eval.hoon`, which owns the environment and the
recursion budget. That is where `SortSeq`, `SelectSeq`, `BagOfAll` and the
`TLCExt` deferring operators land.

## Adding or changing an operator

1. Confirm the pin's own classification first — is it overridden in
   `tlc2.module`, or evaluated from its TLA+ body? Property 2 above will fail
   if you guess wrong.
2. Add the `[module name arity]` key to `registry:stdops` with its laziness and
   `minLevel` taken from the pin's annotation, not from what looks right.
3. If it needs an operator argument, a lazy set, or an unevaluated node, route
   it through `node-eval` instead of implementing it in `stdops`.
4. Regenerate: `python3 tools/gen-stdops-tests.py`, then `python3
   tools/validate.py --check`.
5. Add a differential case (`tla-lus-dev-workflow` §"Adding a case"). For a
   **randomized** operator, read the three rules in `desk/doc/testing.md` first
   — wide seeds, a domain of ten or more elements, and a state count that
   actually depends on the draws.
6. Update `desk/doc/parity-manifest.md` and, if the behaviour deviates,
   `desk/doc/compatibility.md` — the release gate checks refusals in **both**
   directions.

## Values, ordering, and identity

`desk/lib/value.hoon` owns the canonical TLC value mold: equality, order,
rendering, FP64 input bytes, and lazy sets.

- **Strings and model values order lexicographically.** tlc2 orders by intern
  position, which depends on the whole run's path through the Java tools —
  measured with `tools/oracle/InternDump.java`, SANY interns **399** strings
  before a 10-line fixture's own lexemes. Approved differences
  `tlc-value-order`, `tlc-uniquestring`, `tlc-value-model`.
- **A model value's fingerprint folds its name** where tlc2 folds the
  `UniqueString` token. Injective, just not byte-identical.
- **A RECORD compares equal to a FUNCTION** where the domain is a set of names
  — `+fcn-like` admits `%rec`, matching `+to-fcn-pairs`. R3.2 demoted the row
  on the wrong answer and R3.2a closed it the same day; `+fp-enc` already
  encoded both representations to the same bytes, so state identity was never
  at risk. Record form in rendering is tlc2's `isName`, not "the domain is all
  strings".
- **Lazy-set representation classes** follow tlc2's rule: a function is a
  `FcnRcdValue` iff every domain value is `instanceof Reducible`, and
  `Reducible` has exactly two implementors — `IntervalValue` and
  `SetEnumValue`. The same predicate governs `\cup`/`\cap`/`\`/`UNION`
  (eager only when **both** operands are Reducible), and `[D -> R]`/`[a: S]`
  are `SetOfFcnsValue`/`SetOfRcdsValue`. Every **value** agrees with the pin;
  only the class column can differ.
- **`-terse` has no analogue**: it is per-Value-class in tlc2, not a global
  switch, and reproducing it needs each lazy class to keep its source
  descriptor. Rendering only — verdict, counts and trace shape are unaffected.
