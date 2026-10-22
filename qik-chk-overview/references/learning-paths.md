# Learning paths

Companion to [qik-chk-overview](../SKILL.md). Each path lists skills in
order with what to do at each step. Every step has executable examples;
run them with `qik-chk-workflow/scripts/run-examples.sh <skill>`.

## 1. New to QuickCheck (and maybe to property-based testing)

1. [foundations](../../qik-chk-foundations/SKILL.md): write and run a first
   property; read a counterexample; understand that a pass is evidence,
   not proof. Run `FirstProperties.hs`.
2. [properties](../../qik-chk-properties/SKILL.md): `==>`, `forAll`, `===`,
   `counterexample`, conjunction.
3. [property-design](../../qik-chk-property-design/SKILL.md): from weak to
   strong properties; models and metamorphic relations; avoid vacuous
   and `()`-defaulted properties. Run `WeakToStrong.hs`.
4. [generators](../../qik-chk-generators/SKILL.md): `Arbitrary` for your
   own types; `sized`; modifiers.
5. [running](../../qik-chk-running/SKILL.md): `quickCheckWith`, test
   counts, replaying failures.
6. [workflow](../../qik-chk-workflow/SKILL.md): put the properties in a
   test suite.

Checkpoint: you can write a model-based property for a small data
structure, with a custom generator, run it in `cabal test`, and save a
counterexample as a regression test.

## 2. Experienced with testing, new to QuickCheck

1. [foundations](../../qik-chk-foundations/SKILL.md) (skim) and
   [api-index](../../qik-chk-api-index/SKILL.md) main module.
2. [property-design](../../qik-chk-property-design/SKILL.md): the
   effectiveness numbers from *How to Specify It!*.
3. [generators](../../qik-chk-generators/SKILL.md) and
   [shrinking](../../qik-chk-shrinking/SKILL.md).
4. [distribution](../../qik-chk-distribution/SKILL.md): coverage
   requirements with `checkCoverage`.
5. [workflow](../../qik-chk-workflow/SKILL.md): tasty or hspec, CI.

## 3. Debugging a QuickCheck run

1. [debugging](../../qik-chk-debugging/SKILL.md): find the symptom row.
2. Follow its link: usually
   [running](../../qik-chk-running/SKILL.md) (output, replay, timeouts),
   [distribution](../../qik-chk-distribution/SKILL.md) (vacuity, skew),
   [shrinking](../../qik-chk-shrinking/SKILL.md) (large or non-minimal
   counterexamples), or
   [generators](../../qik-chk-generators/SKILL.md) (gave up, slow).
3. Save the counterexample ([workflow](../../qik-chk-workflow/SKILL.md)).

## 4. Advanced generators and shrinking

1. [generators](../../qik-chk-generators/SKILL.md) `references/recipes.md`:
   dependent fields, recursive types, related inputs that collide,
   boundary cases, valid programs and command sequences, `Arbitrary1`.
2. [shrinking](../../qik-chk-shrinking/SKILL.md): invariant-preserving
   shrinkers, dependent values, local minima, the shrink search.
3. [functions](../../qik-chk-functions/SKILL.md): generating and shrinking
   functions.
4. [distribution](../../qik-chk-distribution/SKILL.md): verify the
   generator with `labelledExamples` and `checkCoverage`.
5. [internals](../../qik-chk-internals/SKILL.md) `architecture.md`: seed
   splitting, rose trees, `localMin`.

## 5. Testing effectful and stateful systems

1. [properties](../../qik-chk-properties/SKILL.md),
   [generators](../../qik-chk-generators/SKILL.md),
   [shrinking](../../qik-chk-shrinking/SKILL.md) as needed.
2. [monadic-state](../../qik-chk-monadic-state/SKILL.md): `ioProperty`,
   `PropertyM`, command sequences against a model.
3. [applications](../../qik-chk-applications/SKILL.md): domain recipes.
4. [history](../../qik-chk-history/references/ecosystem.md): when a
   dedicated state-machine library is worth it.

## 6. Integrating into a project

1. [workflow](../../qik-chk-workflow/SKILL.md): cabal test suite, tasty,
   hspec, regression capture, CI practice, compatibility.
2. [running](../../qik-chk-running/SKILL.md): per-property settings,
   `Result` handling.
3. [distribution](../../qik-chk-distribution/SKILL.md): `checkCoverage` as
   a CI gate.

## 7. Working on QuickCheck upstream

1. [internals](../../qik-chk-internals/SKILL.md): architecture, then
   `upstream-tests.md` and `contributing.md`.
2. [api-index](../../qik-chk-api-index/SKILL.md): run `browse-api.sh` on a
   changed tree to see API additions.
3. [history](../../qik-chk-history/SKILL.md): changelog conventions and
   past breaking changes.
4. [running](../../qik-chk-running/references/size-and-seeds.md): the size
   and seed behaviour users depend on.

## 8. Updating old QuickCheck code or tutorials

1. [history](../../qik-chk-history/SKILL.md): the migration table.
2. [api-index](../../qik-chk-api-index/SKILL.md): current signatures and
   deprecations.
3. [distribution](../../qik-chk-distribution/SKILL.md): the post-2.12
   coverage API.
