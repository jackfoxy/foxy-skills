# Foundations: theory and evidence

Notes behind [qik-chk-foundations](../SKILL.md). Paper citations refer to
section numbers of the versions listed in the
[source manifest](../../qik-chk-overview/references/source-manifest.md).

## Contents

- [Specifications as oracles](#specifications-as-oracles)
- [Sampling and confidence](#sampling-and-confidence)
- [Distribution is part of the test](#distribution-is-part-of-the-test)
- [What QuickCheck cannot observe](#what-quickcheck-cannot-observe)
- [Falsification, not verification](#falsification-not-verification)

## Specifications as oracles

The 2000 paper's conclusion summarises the design: "two relatively old
ideas, namely specifications as oracles and random testing" made
convenient for Haskell through an embedded language for properties, type
based default generators, and an embedded language for custom generators
(Claessen and Hughes, ICFP 2000, section 7).

Section 6.2 relates this to the **oracle problem**. Comparing against
another implementation (an older version, or a simple and obviously
correct one) is one oracle; an executable specification is another; a
*result checker* in the sense of Blum and Kannan, which checks an output
more cheaply than computing it, is a third. All three are expressible as
properties. QuickCheck adds conditional properties and custom generators,
so a property can be stated only for inputs where it makes sense (no
testing insertion into an unordered list).

## Sampling and confidence

A passing run of N tests says: in N draws from this generator, no
counterexample appeared. If counterexamples make up a fraction p of the
generator's output, the chance of missing them all is (1 - p)^N. With the
default N = 100, a bug present in 1% of generated inputs is missed about
37% of the time; at 0.1% it is missed about 90% of the time. Two
consequences:

1. The number of tests matters for rare bugs: `withNumTests` raises it
   per property.
2. The **generator** matters more: making the interesting case common
   changes p by orders of magnitude, which no test count can match.

QuickCheck itself makes one statistically justified claim:
`checkCoverage` tests coverage requirements with a confidence bound
([qik-chk-distribution](../../qik-chk-distribution/SKILL.md)). A plain
pass carries no confidence figure.

## Distribution is part of the test

From the 2000 paper's introduction: random testing is most effective when
test data follows the distribution of actual data, but for reusable code
that distribution is unknown, and a uniform distribution over an infinite
set (such as all lambda terms) is not even meaningful. QuickCheck's answer
is to put the distribution under the tester's control and provide ways to
observe it.

The paper's `prop_Insert` example shows the risk: with the precondition
`ordered xs`, almost all accepted lists have length 0 or 1, because random
longer lists are rarely ordered (section 2.4). The same effect is
reproduced in
[FilterVsConstruct.hs](../../qik-chk-generators/examples/FilterVsConstruct.hs).

## What QuickCheck cannot observe

- **Non-termination.** Section 6.5: "What we cannot do is observe
  non-termination in a test result." A property like
  `reverse (xs ++ undefined) == undefined` cannot be tested. `within` turns
  slow evaluation into a failure, but only where the runtime can interrupt
  it ([qik-chk-running](../../qik-chk-running/SKILL.md)).
- **Laziness.** A property only evaluates what its `Bool` needs. A bottom in
  a part of the result that is never inspected is never found; `total`
  forces a value fully ([TimeoutsAndEvaluation.hs](../../qik-chk-running/examples/TimeoutsAndEvaluation.hs)).
- **Side effects.** Pure properties cannot see IO. `ioProperty` and
  `Test.QuickCheck.Monadic` run IO inside a property
  ([qik-chk-monadic-state](../../qik-chk-monadic-state/SKILL.md)).

## Falsification, not verification

A property-based test is an attempt to *falsify* a universal claim. A
found counterexample is decisive: if it reproduces (same input, same
code), the claim is false. A pass is inconclusive. This asymmetry drives
the working style the rest of the pack recommends: state claims as
strongly as you can (strong claims are easier to falsify), make sure the
generator can reach every interesting input, measure what was tested, and
keep counterexamples as regression tests.
