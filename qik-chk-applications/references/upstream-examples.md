# Upstream example programs

Companion to [qik-chk-applications](../SKILL.md). Files under `examples/`
at commit `3d8fe868` (permalinks:
`https://github.com/nick8325/quickcheck/blob/3d8fe8686024760006ca1ca656cbdd82cd71f11e/examples/<file>`).
Each was compiled with GHC 9.10.3 and QuickCheck 2.19.0.0
(`ghc -O0`, package environment from the pack harness) and run once on
2026-10-20. Random outcomes (shrunk values, percentages) vary per run.

| File | Lines | Exit | Built by cabal? |
|---|---|---|---|
| `Simple.hs` | 46 | 1 (deliberate failures) | no |
| `Merge.hs` | 116 | 1 (gives up deliberately) | no |
| `Set.hs` | 207 | 0 | no |
| `Lambda.hs` | 363 | 0 | no |
| `Heap.hs` | 164 | 0 | yes, test suite `test-quickcheck` |
| `Heap_Program.hs` | 197 | 1 (deliberate bug) | no |
| `Heap_ProgramAlgebraic.hs` | 254 | 0 | no |

Exit 1 comes from `main = do True <- $quickCheckAll; return ()`: when any
property fails, the pattern fails ("user error (Pattern match failure in
'do' block ...)"). This is the upstream idiom for making a TH-run file fail.

## Simple.hs

Small first properties run with `$quickCheckAll`, and `$(monomorphic ...)`
to test polymorphic properties at `Integer`:

- `prop_SimonThompson` compares `x == y && y == z` with `2*x == y + z`. It
  **passed** 100 tests although it is false (`x = 0, y = -1, z = 1`): the
  inputs that distinguish the two are rare among random triples. A reminder
  that a pass is evidence, not proof, and that `cover` on the interesting
  case (`2*x == y + z`) would have exposed the gap;
- `prop_ReverseReverse` passes; `prop_Reverse` (`reverse xs == xs`) fails,
  shrunk to `[0,1]`;
- `prop_Error` fails, shrunk to `(0,-1)`;
- `prop_conj` (`.&&.`) and `prop_disj` (`.||.`) combine two failing
  properties with `counterexample` labels; the disjunction prints both
  counterexamples (`Falsified, Falsified`).

## Merge.hs

Merge sort and `merging` of ordered lists:

- `prop_Merge xs ys = ordered xs && ordered ys ==> collect (length xs +
  length ys) (ordered (merge xs ys))` **gives up**: "Passed only 22 tests;
  1000 discarded tests", and the `collect` table shows total lengths 0-4.
  This is the classic demonstration that a precondition on random lists
  starves the test (fix: `OrderedList` or a sorted generator; commented-out
  variants in the file show `Ordered` arguments and a filtered shrinker).
- `prop_Merging` over `[OrderedList Int]` passes.

## Set.hs

Sets as unbalanced binary search trees, with a custom generator and an
invariant-filtering shrinker (shrunk nodes are kept only if `invariant`
holds), and properties comparing against a list model with the helper
`s ==? xs = invariant s && sort (toList s) == nub (sort xs)`:

- invariants, `empty`, `unit`, `size`, `insert`, `delete`, `union`,
  `fromList`, `toSortedList` pass;
- `prop_Size` carries `cover 60 (size s >= 15) "large"`; the run printed
  "Only 53% large, but expected 60%" as a warning (no `checkCoverage`);
- `prop_Mapp` is wrapped in `expectFailure`: mapping a non-monotonic `Fun`
  breaks the search-tree invariant, and the run printed `+++ OK, failed as
  expected` with the shrunk function `Fun: [(-2,3),(0,-2)]`.

## Lambda.hs

An untyped lambda calculus with substitution, evaluation, and a second part
with types:

- The active `subst` does not avoid variable capture; commented lines list
  four more buggy versions ("bug 1" to "bug 4") and a correct one.
  `prop_SubstFreeNoVarCapture` failed: `\o.k` with `k := o` gave `\o.o`
  (`showResult` prints the substitution result with `whenFail`).
- **Generating closed terms**: `arbExp xs n` keeps the list of bound
  variables, only produces `Var` from that list, and only produces lambdas
  when it must (no variables) or size allows. The shrinker filters shrunk
  terms to closed ones.
- `prop_EvalProducesValue` uses `within 1000` to bound evaluation, which may
  not terminate for untyped terms; it passed in this run.
- The second part generates well-typed terms (`WellTyped`) for
  `prop_EvalProducesValueWT`.

Lessons: environment-carrying generators for scoping, filtered shrinking to
keep terms valid, timeouts for possibly divergent evaluation.

## Heap.hs

Skew heaps tested against sorted lists, run by the cabal test suite.
All nine properties passed; `prop_RemoveMin` classifies non-trivial cases
(86% non-trivial in this run).

## Heap_Program.hs

Heaps built from generated `HeapP` programs (see
[stateful-testing.md](../../qik-chk-monadic-state/references/stateful-testing.md#programs-as-data)),
paired with the heap they build (`HeapPP`). `toSortedList` deliberately uses
`toList` after the first element (the correct line is commented out), and
`prop_ToSortedList` failed on
`Insert 2 (Insert 1 (Insert 1 (Insert 1 Empty)))`.

## Heap_ProgramAlgebraic.hs

The same heaps specified **algebraically**: laws such as
`removeMin (insert x empty)`, insert commuting (`prop_InsertSwap`), merging
with an insert on either side, and size and `toList` laws. Heaps are
compared by **observational equivalence**, the 2002 paper's idea:
`h1 =~ h2` quantifies over a generated `Context` (a random sequence of
inserts, removals and merges) and compares the observations `(size,
toSortedList, isEmpty)` after it. Commented-out alternatives show a weaker
equality and a buggy one (`nub` loses duplicates). All twelve properties
passed.

## Recorded output

The complete output of these runs is in the research evidence
(`evidence/upstream-examples.out`, listed in
[qik-chk-overview](../../qik-chk-overview/references/validation-report.md)).
