# Ecosystem: ports, companions, and alternatives

Companion to [qik-chk-history](../SKILL.md). **None of these was
installed, read in source, or run for this pack** except where marked.
Entries are orientation only: names, roles, and the source of the
mention. Verify current status before relying on any of them.

## Contents

- [Haskell companions to QuickCheck](#haskell-companions-to-quickcheck)
- [Haskell alternatives](#haskell-alternatives)
- [Erlang and Quviq](#erlang-and-quviq)
- [Other languages](#other-languages)
- [How to describe the relationship](#how-to-describe-the-relationship)

## Haskell companions to QuickCheck

| Package | Role | Source of mention |
|---|---|---|
| `quickcheck-instances` | `Arbitrary`/`CoArbitrary`/`Function` instances for types outside `base` (text, containers, time, ...) | upstream `README` |
| `QuickCheck-GenT`, `quickcheck-transformer` | monad-transformer versions of `Gen` | `Gen.hs` documentation |
| `tasty-quickcheck` | tasty integration | **run** for this pack (0.11.1) |
| `hspec` (`Test.Hspec.QuickCheck`) | hspec integration | **run** for this pack (2.11.18) |
| `test-framework-quickcheck2` | test-framework integration | general knowledge |
| `quickcheck-state-machine`, `quickcheck-dynamic` | state-machine and dynamic-logic testing on top of QuickCheck | general knowledge |
| `quickcheck-classes`, `quickcheck-laws`-style packages | ready-made law suites for type classes | general knowledge |
| `hint`, `split` | used by the upstream `instances` test suite, not by users | upstream `QuickCheck.cabal` |

## Haskell alternatives

| Library | Difference from QuickCheck | Source of mention |
|---|---|---|
| SmallCheck, Lazy SmallCheck | exhaustive testing of all values up to a depth instead of random sampling | cited in *How to Specify It!* |
| SmartCheck | counterexample reduction and generalisation | cited in *How to Specify It!* |
| Hedgehog | integrated shrinking (shrink trees built with the generator), no type-class-based generation | general knowledge |
| LeanCheck, speculate, extrapolate (Matela Braquehais) | enumerative testing, property discovery | thesis cited in *How to Specify It!* |
| QuickSpec | discovers equational properties by testing | general knowledge |

## Erlang and Quviq

- **Quviq QuickCheck** (Erlang, commercial) is mentioned on the Chalmers
  page as "a commercial version in Erlang" marketed by "our associated
  company, Quviq"; *How to Specify It!* gives John Hughes's affiliation as
  Chalmers and Quviq AB. It is known for state-machine testing (`eqc_statem`) and,
  per the paper listed in [papers.md](papers.md), telecoms testing.
- **PropEr** is an open-source Erlang library inspired by QuickCheck
  (paper cited in *How to Specify It!*).
- **PropCheck**/StreamData (Elixir) exist in the same family (general
  knowledge).

## Other languages

The Chalmers page: "similar libraries have been implemented for many other
programming languages, from Scala to Google's Go - too many to keep an
up-to-date list here." Examples commonly cited: ScalaCheck (Scala, book
cited in *How to Specify It!*), Hypothesis (Python), fast-check
(JavaScript/TypeScript), jqwik (Java), proptest and quickcheck (Rust),
FsCheck (.NET), PrologCheck (Prolog, cited in *How to Specify It!*),
`testing/quick` (Go standard library). They share the idea (random
generation, properties, shrinking) but differ in generator design,
shrinking strategy (Hypothesis and Hedgehog shrink through the generator
rather than with a separate `shrink` function), and statefulness support.

## How to describe the relationship

- "QuickCheck" without qualification in Haskell means the `QuickCheck`
  package (version 2.x), descended from the Chalmers QuickCheck 1.
- Quviq QuickCheck is a separate, commercial product for Erlang that
  shares authors and ideas, not code.
- Ports in other languages are independent implementations; behaviour
  documented in this pack (sizes, shrinking order, coverage statistics,
  output text) is specific to Haskell QuickCheck 2.19.
- %quiz (Urbit, Hoon) is another property-testing library in the same
  family; this pack does not document it.
