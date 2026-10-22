---
name: qik-chk-shrinking
description: Understand and control QuickCheck shrinking - how the greedy search over shrink candidates works, candidate ordering, shrink for lists, numbers, chars and tuples, genericShrink/subterms/recursivelyShrink, writing invariant-preserving custom shrinkers, shrinking values that depend on each other, forAllShrink and shrinking, noShrinking, withMaxShrinks and maxShrinks, Fixed/NoShrink/Shrink2/Smart/Shrinking modifiers, local minima, cyclic or non-terminating shrinkers, and slow shrinking. Use when a counterexample is large or confusing, shrinking hangs or takes forever, a shrunk input violates an invariant or reports a different failure, or someone writes or reviews a shrink function.
user-invocable: true
disable-model-invocation: false
---

# Shrinking

**Scope:** turning a failing input into a simpler failing input. Producing
inputs is [qik-chk-generators](../qik-chk-generators/SKILL.md); the
shrinking of random functions is in
[qik-chk-functions](../qik-chk-functions/SKILL.md); the loop's code is in
[qik-chk-internals](../qik-chk-internals/SKILL.md).

**Prerequisites:** [qik-chk-generators](../qik-chk-generators/SKILL.md).

**Version:** QuickCheck 2.19.0.0 (`Test.hs` `localMin`, `Arbitrary.hs`
shrinkers, `Modifiers.hs`). QuickCheck 1 (the 2000 paper and Chalmers
manual) had no shrinking at all; see
[qik-chk-history](../qik-chk-history/SKILL.md).

## How the search works

When a test fails, QuickCheck has a **tree** of candidates: the children of
the failing input are `shrink x`, each child has its own children, and so
on. The search is **greedy and depth-first**
([Test.hs L604](https://github.com/nick8325/quickcheck/blob/3d8fe8686024760006ca1ca656cbdd82cd71f11e/src/Test/QuickCheck/Test.hs#L604)):

1. Try the candidates in list order.
2. The **first** candidate that still fails replaces the current input;
   restart from its children. Passing (or discarded) candidates are skipped.
3. Stop when no candidate fails (a **local minimum**) or when
   successful plus unsuccessful attempts reach `maxShrinks`
   (default `maxBound`, so effectively only the first condition).

Consequences:

- **Order matters.** Put the most aggressive candidates first (empty
  structure, a subtree, zero) and the smallest steps last.
- **The result is a local minimum**, not a global one. Two list elements
  that must stay equal for the bug to show cannot both shrink, so `[4,4]` is
  reported instead of `[0,0]` (executed in ShrinkTraps.hs).
- **All arguments shrink together.** Since 2.13 a multi-argument property
  shrinks its arguments as one tuple, so shrink steps of different
  arguments interleave.
- **Every candidate is a full test run.** Expensive properties make
  expensive shrinking.

The final report `(after 23 tests and 6 shrinks)` counts successful steps.
While shrinking, the temporary progress line shows counts such as
`6.2 shrinks`: 6 successful steps and 2 failed attempts since the last
success.

## The standard shrinkers

| Shrinker | Candidates, in order |
|---|---|
| `shrinkIntegral x` | `-x` if x is negative and `-x > x`; then `x - x`, `x - x/2`, `x - x/4`, ... (values approaching x from 0) |
| `shrinkList shr xs` | remove chunks of length n, n/2, n/4, ..., 1 (all positions); then shrink one element at a time with `shr` |
| `shrinkRealFrac x` | integers first, then smaller numerators, then smaller denominators |
| `shrinkDecimal x` | values with fewer decimal digits (Double/Float) |
| `shrinkBoundedEnum x` | towards `minBound` |
| tuples | first component's candidates, then the second's (one component at a time) |
| `Maybe` | `Nothing`, then shrink the payload |
| `genericShrink x` | `subterms x` (immediate same-type subterms) ++ `recursivelyShrink x` (shrink each field) |

Full details: [references/shrinkers.md](references/shrinkers.md).

## Procedure: write a shrinker for your type

1. **Candidates must be simpler and must not include the input itself**,
   otherwise shrinking cycles forever (bounded only by `maxShrinks`).
2. **Order from big steps to small:** whole structure to a trivial value,
   then to subterms, then field-wise shrinks.
3. **Preserve every invariant the generator guarantees.** `genericShrink`
   and tuple/list shrinking know nothing about invariants (sortedness,
   `lo <= hi`, valid indices, non-emptiness). Either filter candidates
   (`filter valid`), or shrink a representation that cannot be invalid
   (start plus non-negative width) and rebuild.
4. **Shrink dependent values together.** If one value constrains another
   (a list and an index into it), write one shrinker for the pair that
   repairs the dependency (clamp the index), or quantify in nested `forAll`s
   so the inner value is regenerated for each shrunk outer value.
5. **Test the shrinker:** `forAll gen (all valid . shrinker)`.
6. **Do not shrink both sides of a tuple in tandem.** The class
   documentation warns that
   `[Branch x' l' r' | x' <- shrink x, l' <- shrink l, r' <- shrink r]` stops
   once any one component is fully shrunk; use `shrink (x, l, r)` instead.

Template (from the `Arbitrary` class documentation, adapted):

```haskell
data Tree a = Nil | Branch a (Tree a) (Tree a)

instance Arbitrary a => Arbitrary (Tree a) where
  arbitrary = ...
  shrink Nil = []
  shrink (Branch x l r) =
    [Nil] ++                                       -- most aggressive first
    [t | t@Branch{} <- [l, r]] ++                  -- non-Nil subterms
    [Branch x' l' r' | (x', l', r') <- shrink (x, l, r)]
```

`shrink x = Nil : genericShrink x` would shrink `Nil` to `Nil` and loop.

## Controls

| Control | Effect |
|---|---|
| `forAllShrink gen shr` | quantify with an explicit shrinker |
| `forAll gen` | quantify with **no** shrinking of that value |
| `shrinking shr x0 f` | shrink an explicit starting value |
| `noShrinking p` | no shrinking for quantifiers inside `p` |
| `withMaxShrinks n p`, `Args{maxShrinks = n}` | bound total shrink attempts; `0` disables shrinking |
| `Fixed x`, `NoShrink x` | this argument never shrinks (`NoShrink` only from `Test.QuickCheck.Modifiers`) |
| `Blind x` | still shrinks, but is not printed |
| `Shrink2 x` | also tries two consecutive shrink steps of one value |
| `Smart i x` | interleaves candidates to resume near the position of the last success |
| `Shrinking s x` with `ShrinkState s a` | thread explicit state through shrinking steps |
| `verboseShrinking p` | print every failing candidate (see [qik-chk-debugging](../qik-chk-debugging/SKILL.md)) |
| Ctrl-C during shrinking | QuickCheck stops and reports the last failing candidate (changelog 2.7) |

## Failures specific to shrinking

| Symptom | Cause | Fix |
|---|---|---|
| Shrinking never finishes | candidate list contains the input, or cycles | make candidates strictly simpler; bound with `withMaxShrinks` |
| Counterexample violates an invariant | generic/tuple shrinking left the generator's domain | invariant-preserving shrinker |
| Reported failure differs from the original (an exception) | shrinking reached an input the generator never makes (empty list from a `listOf1`, index past the end) | preserve guarantees and dependencies in the shrinker |
| Counterexample still large | local minimum: elements must change together; or slow shrinker stopped by `maxShrinks` | shrink a representation where coupled values move together; check `numShrinkTries` |
| Shrinking slow | each candidate is a full property run; many candidates per step | put big steps first; shrink cheaper representations; cap with `withMaxShrinks` |
| Values inside `ioProperty` or from `pick` do not shrink | by design | generate outside IO, use `forAllShrink`/`idempotentIOProperty` ([qik-chk-monadic-state](../qik-chk-monadic-state/SKILL.md)) |

## Executable examples

| File | Shows | Expected |
|---|---|---|
| [InvariantShrink.hs](examples/InvariantShrink.hs) | `genericShrink` of a valid interval such as `Interval (-1) (-1)` yields invalid candidates (`Interval 1 (-1)`); a width-based shrinker stays valid | both report the minimal failing `Interval 0 6` (the generic one only because a precondition discards invalid candidates); the invariant check fails for `genericShrink` and passes for the width-based shrinker |
| [ShrinkTraps.hs](examples/ShrinkTraps.hs) | cyclic shrinker cut off at 200 shrinks; local minimum `[4,4]`; `Shrink2` does not escape it; paired representation reaches the minimum; `noShrinking` | five expected failures |
| [DependentShrink.hs](examples/DependentShrink.hs) | plain list `shrink` escapes `listOf1` (reports `[]` with an exception); independently shrunk index reaches `([0],1)`; clamping shrinker and nested `forAll` report the real bug | exceptions for the first two, clean failures for the last two |

Recorded (seeded run of ShrinkTraps.hs, seed 3):

```text
=== independent shrinking: local minimum (expect Fail)
*** Failed! Falsified (after 7 tests and 2 shrinks):
[4,4]
```

Run: `qik-chk-workflow/scripts/run-examples.sh qik-chk-shrinking`.

## Go deeper

- [references/shrinkers.md](references/shrinkers.md): candidate lists of
  every standard shrinker, modifier shrinking, and the generic helpers.
- [references/search.md](references/search.md): the rose-tree search, how
  multi-argument properties shrink, and what the counters in `Result` mean.
