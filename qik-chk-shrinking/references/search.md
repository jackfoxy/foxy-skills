# The shrinking search in detail

Companion to [qik-chk-shrinking](../SKILL.md). Code references are to
commit `3d8fe868`; the overall architecture is in
[qik-chk-internals](../../qik-chk-internals/references/architecture.md).

## Contents

- [Rose trees of results](#rose-trees-of-results)
- [The greedy loop](#the-greedy-loop)
- [Multi-argument and nested properties](#multi-argument-and-nested-properties)
- [Counters in Result](#counters-in-result)
- [Interaction with discards, exceptions and IO](#interaction-with-discards-exceptions-and-io)

## Rose trees of results

Running one test produces a `Prop`, which wraps a **rose tree** of
per-test results (`data Rose a = MkRose a [Rose a] | IORose (IO (Rose a))`,
`Property.hs` L195). The root is the result for the generated input; the
children are the results for its shrink candidates, computed lazily. The
tree is built by `shrinking shr x0 pf` (L394): each node runs the property
on a candidate and lists `shrink` of that candidate as children. Because
the children are lazy, a candidate's subtree is only evaluated if the
search descends into it.

## The greedy loop

`foundFailure` starts `localMin` (`Test.hs` L600-L640). In each step:

1. If successful plus unsuccessful shrink attempts reached `maxShrinks`,
   stop and report the current input.
2. Otherwise evaluate the candidate list. If evaluating it throws, the
   current input is reported (an exception while computing candidates is
   recorded as "Exception while generating shrink-list"; a `discard` thrown
   there just ends shrinking).
3. Walk the candidates in order. For each, run its test (with callbacks).
   - It **fails**: count a successful shrink, reset the per-step failure
     count, and restart the loop from this candidate and its children.
   - It passes or is discarded: count a failed attempt and try the next one.
4. When the candidates run out, the current input is a local minimum.

The search never backtracks to an earlier sibling, and never compares
candidates by size: "smaller" means "earlier in the shrink list". This is
why candidate order is the main lever for counterexample quality.

## Multi-argument and nested properties

For `prop :: A -> B -> C -> Bool`, the `Testable (a -> prop)` instance
(`Property.hs` L172) uses `propertyForAllShrinkShow` to generate and shrink
all arguments as **one tuple**, using `liftShrink2` on pairs. Shrink steps
for different arguments therefore interleave. Before 2.13 the first
argument was shrunk completely, then the second, and so on (changelog
2.13).

Nested quantifiers (`forAll g1 $ \x -> forAll g2 $ \y -> ...`) shrink the
outer value first: rose trees are joined so that "first shrinks outer
quantification" (`joinRose`, L201). When the outer value shrinks, the inner
property is rebuilt for the new outer value, and the inner generator runs
again from the same seed, which is why a dependent inner value stays
consistent (executed in
[DependentShrink.hs](../examples/DependentShrink.hs)).

## Counters in Result

| `Failure` field | Meaning |
|---|---|
| `numShrinks` | successful shrink steps |
| `numShrinkTries` | unsuccessful attempts in total (excluding those since the last success) |
| `numShrinkFinal` | unsuccessful attempts since the last successful step (candidates of the final input that all passed) |
| `failingTestCase` | the printed lines of the final counterexample |

`TestProgress` (passed to `withProgress` callbacks) exposes
`currentShrinks`, `currentFailedShrinks` and `currentTotalShrinks` during
the run.

## Interaction with discards, exceptions and IO

- A candidate whose precondition is false is **discarded**: it counts as
  an unsuccessful attempt, so preconditions guard shrinking from leaving
  the domain, at a cost in attempts (executed: the generic shrinker in
  [InvariantShrink.hs](../examples/InvariantShrink.hs)).
- A candidate that throws an exception counts as **failing**, so shrinking
  can move from the original bug to an exception caused by an invalid
  candidate. Check `theException` in the result.
- Values generated *inside* `ioProperty` are not shrunk: `ioProperty`
  applies `noShrinking` to what the IO action returns. `idempotentIOProperty`
  shrinks but may reuse one execution of the action. Values from `pick` in
  `PropertyM` never shrink (the documentation says so explicitly).
- Ctrl-C during shrinking reports the last failing candidate rather than
  the one being tried (since 2.7). QuickCheck does not catch asynchronous
  exceptions otherwise (since 2.10), so Ctrl-C during testing aborts
  without a counterexample.
