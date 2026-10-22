# Sizes and seeds

Companion to [qik-chk-running](../SKILL.md). Code: `computeSize` and
`runATest` in `src/Test/QuickCheck/Test.hs`, `Random.hs`, at commit
`3d8fe868`.

## Contents

- [computeSize](#computesize)
- [Seeds and splitting](#seeds-and-splitting)
- [What replay reproduces](#what-replay-reproduces)
- [Sizes outside the runner](#sizes-outside-the-runner)

## computeSize

For `n` passing tests so far, `d` discards since the last pass,
`ms = maxSuccess`, `mts = maxSize`, `md = maxDiscardRatio` (L240):

```text
if a replay size is given and no test has run yet:   size = replay size
else if n rounded down to a multiple of mts, plus mts, is <= ms,
        or n >= ms, or ms is a multiple of mts:
     size = min mts (n mod mts + d div dDenom)
else size = min mts ((n mod mts) * mts div (ms mod mts) + d div dDenom)

dDenom = clamp (ms * md div 3) to [1, 10]   (1 if md = 0)
```

Consequences:

- Default run: sizes 0, 1, ..., 99 in order (measured: `collect` of
  `getSize` in buckets of 25 gave exactly 25% per bucket).
- `maxSuccess = 1000`: ten passes through 0..99.
- `maxSuccess = 250`, `maxSize = 100`: 0..99, 0..99, 0, 2, 4, ..., 98 (the
  example in the source comment): the last partial cycle is stretched to
  reach large sizes.
- `maxSuccess` below `maxSize` (e.g. 20 tests): sizes are stretched over
  the whole range, 0, 5, 10, ....
- Discards push the size up slowly, so a run with many rejected tests still
  reaches larger sizes. The 2.15 changelog fixed a bug where `maxSuccess`
  and `discardRatio` combined to give too few size increases.
- The upstream test `prop_discardCoverage` in `tests/Misc.hs` depends on
  this exact sequence (a comment in `computeSize` warns about this).

## Seeds and splitting

- `QCGen` wraps splitmix's `SMGen` on GHC (`StdGen` on Hugs). It has `Show`
  and `Read`: `show (mkQCGen 42) == "SMGen 9297814886316923340 13679457532755275413"`
  (2.19 with splitmix 0.1.3.2).
- `newQCGen` gets a fresh seed from the system; `mkQCGen :: Int -> QCGen`
  makes a deterministic one. Both are in `Test.QuickCheck.Random`, which is
  hidden from Haddock but exposed.
- Before each test the runner splits its seed in two: one half runs the
  test, the other becomes the next seed. Inside a test, `>>=` in `Gen`
  splits again for each bind.
- `variant n` derives a seed from an integer by a prefix-free sequence of
  splits ([qik-chk-functions](../../qik-chk-functions/references/function-representation.md)).

## What replay reproduces

`Failure` records `usedSeed` (the runner seed *before* the split for the
failing test) and `usedSize`. `replay = Just (usedSeed, usedSize)` makes the
first test run with exactly that seed and size, so with the same property
code, the same generators, and the same QuickCheck version, the same
failing input is generated and shrinks the same way. `recheck` does this
and adds `once`.

It does not reproduce anything if:

- QuickCheck (or the random/splitmix library) is a different version; the
  `replay` field documentation: "saving a seed from one version of
  QuickCheck and replaying it in another is not supported";
- the generators, the order of quantified arguments, or anything consuming
  randomness before the failing value changed;
- the property depends on IO, time, or global state.

Store counterexamples as explicit tests instead. Test frameworks wrap
replay in their own options: tasty-quickcheck prints
`Use --quickcheck-replay="(SMGen ...,2)" to reproduce.` on failure (seen in
[TastySuite.hs](../../qik-chk-workflow/examples/TastySuite.hs)).

## Sizes outside the runner

| Function | Size |
|---|---|
| `generate g` | 30 |
| `sample g`, `sample' g` | 0, 2, 4, ..., 20 |
| `unGen g seed n` | `n` |
| `labelledExamples` | as the runner, replaying the seed and size of each find |
