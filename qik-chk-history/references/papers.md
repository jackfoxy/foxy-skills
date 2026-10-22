# Papers

Companion to [qik-chk-history](../SKILL.md). Status: **read** means the
text was obtained and read for this pack (access 2026-10-20);
**not read** entries are listed for orientation only, with bibliographic
details taken from the reference lists of the papers that were read.

## Read

### QuickCheck: A Lightweight Tool for Random Testing of Haskell Programs

Koen Claessen and John Hughes, ICFP 2000. Obtained from a mirror
(`https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf`);
the Chalmers link `http://www.md.chalmers.se/~koen/Papers/quick.ps` did
not resolve.

| Section | Content | Used in |
|---|---|---|
| 2 | properties as Haskell functions, polymorphism, conditional laws (`==>`), monitoring test data (`prop_Insert` mostly tests short lists), infinite structures | [qik-chk-foundations](../../qik-chk-foundations/SKILL.md), [qik-chk-distribution](../../qik-chk-distribution/SKILL.md) |
| 3 | `Arbitrary`, generators for user-defined types and the size problem for recursive types, generating functions with `coarbitrary` and `variant` | [qik-chk-generators](../../qik-chk-generators/SKILL.md), [qik-chk-functions](../../qik-chk-functions/SKILL.md) |
| 4 | implementation: `Gen` as a function of seed and size, `Testable` | [qik-chk-internals](../../qik-chk-internals/SKILL.md) |
| 5 | case studies: unification, Lava circuit properties, propositional theorem proving (Stålmarck), pretty printing, Edison | [qik-chk-applications](../../qik-chk-applications/SKILL.md) |
| 6 | discussion: random testing (Duran and Ntafos 1984; Hamlet and Taylor 1990), correctness criteria and the oracle problem, test data generation, "Gen is not a monad... morally", lazy evaluation | [qik-chk-foundations/references/theory.md](../../qik-chk-foundations/references/theory.md) |

### Testing Monadic Code with QuickCheck

Koen Claessen and John Hughes, Haskell Workshop 2002 (`QuickCheckST.ps`
from the Chalmers page). Imperative queues and Union/Find in `ST`;
algebraic specifications tested by observational equivalence;
model-based (functional and relational) and pre/postcondition
specifications; the `PropertyM` monadic property language and its
semantics. Summary: [stateful-testing.md](../../qik-chk-monadic-state/references/stateful-testing.md).

### How to Specify It! A Guide to Writing Properties of Pure Functions

John Hughes, Trends in Functional Programming (TFP 2019), LNCS 12053, pp. 58-83 (2020),
doi:10.1007/978-3-030-47147-7_4; full text from Chalmers research
(`https://research.chalmers.se/publication/517894/file/517894_Fulltext.pdf`).
Five approaches (invariants/validity, postconditions, metamorphic,
inductive, model-based) on a binary search tree with eight buggy
variants, measured effectiveness, and advice on generators and shrinkers.
Summary and numbers:
[specification-styles.md](../../qik-chk-property-design/references/specification-styles.md).

### Chalmers QuickCheck manual

The QuickCheck 1 online manual (`manual.html` and frames), read as
QuickCheck 1 documentation; used for history and for the
"observing test case distribution" principle. Its `oneof ["a", ...]`
example only type-checks with `elements`.

## Not read

| Work | Why listed | Status |
|---|---|---|
| Koen Claessen, *Shrinking and showing functions* (Haskell Symposium 2012) | basis of `Test.QuickCheck.Function` | ACM Digital Library returned 403; the pack documents `Function` from source only |
| John Hughes, *Experiences with QuickCheck: Testing the Hard Stuff and Staying Sane* (in *A List of Successes That Can Change the World*, LNCS 9600, 2016) | cited by *How to Specify It!* | not read |
| Thomas Arts, John Hughes, Joakim Johansson, Ulf Wiger, *Testing telecoms software with Quviq QuickCheck* (Erlang Workshop 2006) | Quviq state-machine testing | not read |
| Colin Runciman, Matthew Naylor, Fredrik Lindblad, *SmallCheck and Lazy SmallCheck* (Haskell Symposium 2008) | exhaustive small-value testing, alternative to random generation | not read |
| Lee Pike, *SmartCheck* (Haskell Symposium 2014) | counterexample reduction and generalisation | not read |
| Andreas Löscher, Konstantinos Sagonas, *Targeted property-based testing* (ISSTA 2017) | search-guided generation | not read |
| Manolis Papadakis, Konstantinos Sagonas, *A PropEr integration of types and function specifications with property-based testing* (Erlang Workshop 2011) | PropEr | not read |
| Rudy Matela Braquehais, PhD thesis (York, 2017) | property discovery by enumerative testing | not read |
| Tom Moertel, ICFP 2001 contest story | user experience linked from Chalmers | link domain parked at access |

The ICFP 2000 paper's own references (Duran and Ntafos; Hamlet and
Taylor; Blum and Kannan on program checking; Celentano et al. and Maurer
on grammar-based test generation) are the context for its discussion
section.
