# Specification styles in the primary sources

Background for [qik-chk-property-design](../SKILL.md). Two papers by the
QuickCheck authors classify ways of writing specifications; both are listed
in the [source manifest](../../qik-chk-overview/references/source-manifest.md).

## Contents

- [How to Specify It! (Hughes, TFP 2019 / LNCS 2020)](#how-to-specify-it)
- [Testing Monadic Code with QuickCheck (Claessen and Hughes, 2002)](#testing-monadic-code-with-quickcheck)
- [The 2000 paper's lessons](#the-2000-papers-lessons)

## How to Specify It!

A tutorial on writing properties of **pure** functions, using a binary
search tree (`nil`, `insert`, `delete`, `union`, `find`, `toList`) as the
running example. Five approaches (section 4):

1. **Validity testing** (4.1). Define `valid` (the data invariant) and
   check that `arbitrary` produces valid values, that every operation
   preserves validity, and that `shrink` does too. Invalid test data
   provokes false positives: bug #2 in the paper generates invalid trees and
   makes many unrelated properties fail (section 5.1).
2. **Postconditions** (4.2). After a call, check a relation between
   arguments and result, e.g. `find k (insert k v t) === Just v`. A
   postcondition checks one aspect at a time, which is why it can exercise a
   bug many times without noticing it.
3. **Metamorphic properties** (4.3). Relate two calls instead of
   predicting a result: `insert k v (insert k' v' t)` compared with the
   other order, `delete` after `insert`, and so on. Needs a notion of
   equivalence (`toList` equality), so "preservation of equivalence"
   properties are needed too. Effective in combination; any single one can
   miss bugs; degenerate ones involving `nil` are particularly weak.
   Metamorphic testing comes from Chen, Cheung and Yiu (related work).
4. **Inductive testing** (4.4). "Inductive proofs inspire inductive
   tests": `union nil t === t` plus `union (insert k v t) t'` equivalent to
   `insert k v (union t t')` characterise `union` by induction on its first
   argument (an idea the paper credits to Claessen). The argument assumes
   every tree can be built by `insert` alone, so the paper adds
   **completeness** properties: a tree rebuilt from its list of insertions
   is structurally equal to the original, checked also for trees returned
   by `delete` and `union`. Since the generator builds trees by insertion,
   these properties also justify the generator: they show it can reach
   every shape the API can produce.
5. **Model-based properties** (4.5). Use an abstraction function (here
   `toList`) to a model with obvious operations (sorted association lists)
   and check that each operation commutes with the abstraction. One
   property per operation is a complete specification. The paper's own
   first attempt was wrong (`Data.List.insert` keeps duplicate keys), a
   reminder that models need testing too.

Section 4.6 measures how often a randomly generated key actually occurs in
an independently generated tree (about 21% present, 79% absent after a
million tests), the kind of distribution check the pack recommends in
[qik-chk-distribution](../../qik-chk-distribution/SKILL.md).

Measured results (section 5, Figures 8 and 9): validity properties miss
five of eight bugs; every bug is found by at least one property of each
other kind; mean tests to failure are 77 (postconditions), 56
(metamorphic) and 5.8 (model-based). The union postcondition needs about
50 tests on average for a union bug that the union model-based property
finds in 8.4, because the model checks the whole result while the
postcondition checks one key.

## Testing Monadic Code with QuickCheck

The 2002 Haskell Workshop paper extends QuickCheck to imperative code in
the ST monad (section and page references from the Chalmers PostScript).
It shows that QuickCheck's specification language can express the usual
specification styles directly as tests:

- **algebraic** specifications (equations between operation sequences,
  section 4), tested as **observational equivalence**: two programs are
  equivalent if no generated context can tell them apart;
- **model-based** specifications, both functional and relational
  (sections 5 and 12);
- **pre- and postconditions** (section 11), written in a new monadic
  property language (sections 7 to 9) that became today's
  `Test.QuickCheck.Monadic` (`run`, `pick`, `pre`, `assert`).

Its examples are an imperative queue and the Union/Find algorithm. See
[qik-chk-monadic-state](../../qik-chk-monadic-state/SKILL.md) for the current
API and [qik-chk-history](../../qik-chk-history/SKILL.md) for how the 2002
design maps to 2.19.

## The 2000 paper's lessons

Lessons from the original case studies (ICFP 2000, section 5):

- **QuickCheck changes type design** (5.1.1): the unifier case study used
  `newtype Name = Name String` and `newtype Var = Variable Nat` instead of
  raw strings and integers, so that names could get a generator that makes
  clashes likely. With random strings, unifiable terms would almost never
  be generated.
- **Specifications have bugs too** (5.1.3): no errors were found in the
  unifier, but errors were found in its specification.
- **Monitor the data** (2.4): `classify`/`collect` revealed that an
  `ordered xs ==>` precondition left mostly empty or singleton lists.
