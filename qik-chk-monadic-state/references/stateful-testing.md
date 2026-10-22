# Stateful testing techniques

Companion to [qik-chk-monadic-state](../SKILL.md). Sources: Claessen and
Hughes, *Testing Monadic Code with QuickCheck* (Haskell Workshop 2002,
`QuickCheckST.ps` on the Chalmers QuickCheck page), the upstream examples
`examples/Heap_Program.hs` and `examples/Heap_ProgramAlgebraic.hs` at commit
`3d8fe868`, and `src/Test/QuickCheck/Monadic.hs`.

## Contents

- [Ideas from the 2002 paper](#ideas-from-the-2002-paper)
- [Programs as data](#programs-as-data)
- [Generating valid command sequences](#generating-valid-command-sequences)
- [Shrinking command sequences](#shrinking-command-sequences)
- [Specification styles for stateful code](#specification-styles-for-stateful-code)
- [Concurrency](#concurrency)
- [Libraries outside QuickCheck](#libraries-outside-quickcheck)

## Ideas from the 2002 paper

The paper tests an imperative queue in `ST` and the Union/Find algorithm. Its
points, summarised:

- QuickCheck's ordinary property language already expresses algebraic,
  model-based (functional and relational), and pre/postcondition
  specifications of monadic code, given a data type of **queue programs**
  (sections 3-5).
- An algebraic law about imperative operations is tested as
  **observational equivalence**: two program fragments are equivalent if
  every context (a generated program around them) makes the same
  observations (section 4).
- Model-based testing generates random *reachable* states by running
  generated well-formed action sequences (section 5).
- **Lessons** (section 6): representing programs as a data type, not as
  monadic values, prints useful counterexamples and allows static analysis
  of programs (the paper's `delta` predicts the change in queue length).
  Ordinary property operators such as `==>` cannot be used in the middle of
  an `ST` computation, which motivates a monadic property language.
- **PropertyM** (sections 7-9): a property monad transformer with `run`,
  `assert`, `pre`, `pick`, `monitor`; `run` is read as a weakest
  precondition (the 2.19 module keeps `wp`). The current `PropertyM` is the
  descendant of this design.
- **Union/Find** (sections 10-12): tested with pre/postconditions and with a
  relational model. A postcondition failed "after 3 tests" on an element
  unioned with itself: the code forgot the case where both arguments are
  already equivalent.
- Section 13 builds higher-level combinators to make such specifications
  shorter.

## Programs as data

`examples/Heap_Program.hs` applies the same idea to a pure skew heap: a
data type `HeapP` of heap-building programs (`Empty`, `Unit`, `Insert`,
`SafeRemoveMin`, `Merge`, `FromList`) with a sized generator (operations
weighted by size, sub-programs at `s-1` or `s div 2`) and a shrinker that
replaces a program by its sub-programs first. Properties then quantify over
programs and compare the heap they build with a list model. Generating
*programs* instead of values reaches structures that `fromList` alone does
not (here, heaps built by interleaved inserts, merges, and removals).

## Generating valid command sequences

When commands have preconditions (pop only on non-empty, use only handles
already created), generate against the model:

```haskell
genCmds :: Model -> Int -> Gen [Cmd]
genCmds _ 0 = pure []
genCmds m n = do
  c <- oneof (validCmds m)          -- a list of generators valid in state m
  (c :) <$> genCmds (nextModel m c) (n - 1)

prop_api = forAllShrink (sized (genCmds initial)) shrinkValid $ \cmds -> ...
```

References to earlier results (a file handle returned by `open`) are best
represented symbolically, for example as the index of the command that
produced them, and resolved during execution. This keeps commands `Show`able
and shrinkable.

## Shrinking command sequences

- `shrinkList shrinkCmd` removes chunks and single commands, then shrinks
  individual commands.
- With preconditions, filter candidates by replaying them through the model:
  `shrinkValid = filter (valid initial) . shrinkList shrinkCmd`. Invalid
  candidates otherwise either fail for the wrong reason or are discarded.
- Symbolic references must be renumbered or dropped when the command they
  refer to is removed.
- Every shrink candidate reruns the system, so expensive setup makes
  shrinking slow; bound it with `withMaxShrinks`.

See [qik-chk-shrinking](../../qik-chk-shrinking/SKILL.md) for invariant-
preserving shrinkers.

## Specification styles for stateful code

| Style | Check | Notes |
|---|---|---|
| Postcondition | after each command, a predicate on response and model | simplest; weak if the model is not compared |
| Model-based, functional | response equals the model's response | pack example [CommandSequences.hs](../examples/CommandSequences.hs) |
| Model-based, relational | response is one of the responses the model allows | for nondeterministic APIs |
| Algebraic / observational | two command sequences give the same observations in every context | finds bugs without a model |
| Invariant | an invariant of the system state holds after every command | needs an inspection function |

The pure-code versions and their relative effectiveness are in
[qik-chk-property-design](../../qik-chk-property-design/references/specification-styles.md).

## Concurrency

Core QuickCheck has no support for testing concurrent behaviour beyond
running IO. A failure that depends on scheduling may not reproduce from
the seed, and `ioProperty` shrinking reruns the program each time with a
different interleaving. Common approaches, none part of QuickCheck:

- run a generated sequential prefix and then several command lists in
  parallel, and check that the observed results can be explained by some
  sequential interleaving of the model (linearizability);
- repeat each test case several times to raise the chance of a bad
  interleaving;
- control scheduling with a deterministic scheduler.

These are what the libraries below implement.

## Libraries outside QuickCheck

Not part of QuickCheck 2.19, not examined or executed for this pack; names
and roles only, from their public descriptions:

| Library | Ecosystem | Role |
|---|---|---|
| `quickcheck-state-machine` | Haskell, built on QuickCheck | state-machine models with sequential and parallel (linearizability) testing |
| `quickcheck-dynamic` | Haskell, built on QuickCheck | state-machine models plus "dynamic logic" scenarios |
| Quviq QuickCheck (`eqc_statem`) | Erlang, commercial | the state-machine testing approach of Hughes and colleagues; PULSE scheduler for race conditions |
| PropEr (`proper_statem`) | Erlang, open source | QuickCheck-inspired state-machine testing |

Use one of these when the API has many commands with preconditions,
symbolic references, or concurrency; for a handful of commands, the
plain-QuickCheck pattern in the skill is enough. History and research
context: [qik-chk-history](../../qik-chk-history/references/ecosystem.md).
