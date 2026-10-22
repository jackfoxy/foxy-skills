---
name: qik-chk-foundations
description: The ideas underneath QuickCheck (Haskell) and property-based testing - properties as executable specifications, universal claims checked by sampled evidence, falsification and counterexamples, oracles, preconditions, random versus systematic testing, and exactly what a passing run does and does not establish. Use when someone is new to QuickCheck or property-based testing, asks whether a passing QuickCheck run proves anything, compares properties with example-based unit tests, or needs the conceptual vocabulary before designing properties or generators.
user-invocable: true
disable-model-invocation: false
---

# QuickCheck foundations

**Scope:** concepts that every other `qik-chk-*` skill assumes. No API
detail beyond the first property; for writing good properties go to
[qik-chk-property-design](../qik-chk-property-design/SKILL.md), for test data
to [qik-chk-generators](../qik-chk-generators/SKILL.md).

**Prerequisites:** basic Haskell (functions, type classes, `Bool`).

**Version:** QuickCheck 2.19.0.0 (tag `2.19`, commit `3d8fe868`), GHC 9.10.3;
see the [source manifest](../qik-chk-overview/references/source-manifest.md).

## The model in one paragraph

A **property** is a Haskell function that states a claim, usually
universally quantified over its arguments: `prop_reverse xs = reverse
(reverse xs) == xs` claims something for *every* list `xs`. QuickCheck
**samples**: it generates random arguments (100 by default), evaluates the
property on each, and reports either `+++ OK, passed 100 tests.` or the
first argument it found that makes the claim false: a **counterexample**,
which it then **shrinks** to a simpler failing argument. The
specification and the oracle are the same thing: the property's `Bool`
result decides pass or fail, so no expected outputs are written by hand.

## What a run establishes

| Outcome | What you know | What you do not know |
|---|---|---|
| `Failed! Falsified ...` with a counterexample | The claim is **false**: the printed input is a concrete witness (re-run it to confirm; see [replay](../qik-chk-running/SKILL.md)). | Whether the shrunk input is the *smallest* one; shrinking finds a local minimum. |
| `+++ OK, passed N tests.` | The claim held on N sampled inputs from *this* generator. | That it holds for all inputs. Inputs the generator rarely or never makes were not tested. |
| `*** Gave up! Passed only K tests` | Too many inputs failed a precondition; only K meaningful tests ran. | Anything about the inputs that were discarded. |
| `+++ OK, failed as expected.` | An `expectFailure` property did fail. | - |

A pass is **evidence, not proof**. The evidence is only as good as the
distribution of test data: the ICFP 2000 paper's central point is that
"it is meaningless to talk about random testing without discussing the
distribution of test data" (Claessen and Hughes 2000, section 1). The
executable example below includes a false property that passes 100 tests
because the default `Int` generator never produces the one bad value.

## Why random testing works (and when it does not)

- **Small inputs find most bugs.** QuickCheck starts with small sizes and
  grows them (size 0 to 99 over a default run), so short lists and small
  numbers are tried first. Most bugs in pure functions have small
  witnesses.
- **Random beats it-seems-systematic more often than intuition says.** The
  2000 paper cites Duran and Ntafos (1984) and Hamlet and Taylor (1990) to
  argue that random testing compares favourably with partition testing
  (section 6.1); QuickCheck adds programmer control over the distribution.
- **It fails for needles in haystacks.** A bug triggered by one exact
  value (a magic constant, `minBound`, a hash collision) is unlikely to be
  hit. Write explicit example tests for known boundaries, or a generator
  that makes the rare case common; see
  [qik-chk-workflow](../qik-chk-workflow/SKILL.md) (regression cases) and
  [qik-chk-debugging](../qik-chk-debugging/SKILL.md) (rare-case diagnosis).
- **It only observes what Haskell can observe.** Non-termination is not a
  test result (QuickCheck can only time out; see
  [qik-chk-running](../qik-chk-running/SKILL.md)), and a property can
  only check what it computes (paper section 6.5).

## Vocabulary used throughout the pack

| Term | Meaning in QuickCheck |
|---|---|
| Property | Anything `Testable`: `Bool`, `Property`, functions of `Arbitrary` arguments returning a testable value, and more ([qik-chk-properties](../qik-chk-properties/SKILL.md)). |
| Generator | A `Gen a`: a random value of type `a`, depending on a seed and a **size** ([qik-chk-generators](../qik-chk-generators/SKILL.md)). |
| Arbitrary instance | The default generator and shrinker for a type. |
| Precondition | `cond ==> prop`: tests with a false condition are **discarded**, not passed. |
| Discard ratio | How many discarded tests per passing test are tolerated before giving up (10). |
| Shrinking | Replacing a failing input by a simpler failing one, repeatedly ([qik-chk-shrinking](../qik-chk-shrinking/SKILL.md)). |
| Oracle | The rule that decides pass/fail; in QuickCheck, the property itself (paper section 6.2). |
| Coverage / distribution | Which kinds of inputs were actually tested ([qik-chk-distribution](../qik-chk-distribution/SKILL.md)). |

## Properties and example tests are complementary

| Example-based test | Property |
|---|---|
| States one input and its expected output | States a relation that must hold for all inputs |
| Precise about known edge cases | Explores inputs nobody thought of |
| Never finds a new bug by itself | Can miss a specific known case |
| Expected output must be computed by hand | The oracle is the property |

Keep both: turn every counterexample QuickCheck finds into a permanent
example test, and keep the property to look for new ones
([qik-chk-workflow](../qik-chk-workflow/SKILL.md)).

## Procedure: your first useful property

1. Pick a function and a claim that is true for all inputs, and that
   compares two *different* computations (not `f x == f x`).
2. Give the property a concrete argument type. A polymorphic property
   tested in GHCi defaults its type variables to `()`, where every claim
   about equality is trivially true
   ([qik-chk-property-design](../qik-chk-property-design/SKILL.md)).
3. Run `quickCheck prop`. If it fails, decide whether the code or the
   claim is wrong; both happen (the 2000 paper reports finding errors in the
   *specification* of a unifier, section 5.1.3).
4. If it passes, check what was tested: add `collect`/`classify` and look
   at the distribution ([qik-chk-distribution](../qik-chk-distribution/SKILL.md)).
5. Raise the test count for important properties (`withNumTests 10000`)
   and keep the property in the test suite.

## Pitfalls

- **`quickCheck` never fails the program**; a test `main` must check the
  `Result` ([qik-chk-workflow](../qik-chk-workflow/SKILL.md)).
- **A pass is evidence, not proof**: 100 random tests can miss rare inputs
  (upstream `Simple.hs` passes a false property).
- **Polymorphic properties default to `()`** in GHCi and pass vacuously:
  annotate types.
- **Since 2.15 a property without arguments runs 100 times**, not once;
  use `once` for a single check.

## Troubleshooting

| Symptom | Go to |
|---|---|
| `Gave up!` | [qik-chk-debugging](../qik-chk-debugging/references/symptoms.md#gave-up) |
| Passes but should not | [qik-chk-property-design](../qik-chk-property-design/SKILL.md) |
| `No instance for (Arbitrary T)` / `(Show (a -> b))` | [qik-chk-generators](../qik-chk-generators/SKILL.md), [qik-chk-functions](../qik-chk-functions/SKILL.md) |
| Counterexample hard to read | [qik-chk-shrinking](../qik-chk-shrinking/SKILL.md), `counterexample` in [qik-chk-properties](../qik-chk-properties/SKILL.md) |

## Executable example

[examples/FirstProperties.hs](examples/FirstProperties.hs): a true law that
passes, a false law with its shrunk counterexample, and a false law that
passes 100 tests because the bad input is never generated. Run it with the
[pack harness](../qik-chk-workflow/references/examples-harness.md):

```sh
qik-chk-workflow/scripts/run-examples.sh qik-chk-foundations
```

Recorded run (one sample; random values differ between runs):

```text
=== reverse is identity (false) (expect Fail)
*** Failed! Falsified (after 5 tests and 4 shrinks):
[0,1]
=== rare bug escapes 100 tests (expect Pass)
+++ OK, passed 100 tests.
```

The shrunk counterexample for `reverse xs == xs` is a two-element list of
distinct values; `[0,1]` is typical but the exact numbers depend on the
seed.

## Go deeper

- [references/theory.md](references/theory.md): the evidence argument in
  more detail, oracles, the limits of observation, and what the original
  papers claim.
- History of these ideas: [qik-chk-history](../qik-chk-history/SKILL.md).
