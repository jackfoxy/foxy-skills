---
name: qik-chk-monadic-state
description: Test effectful and stateful Haskell code with QuickCheck - ioProperty and idempotentIOProperty, the PropertyM monad of Test.QuickCheck.Monadic (run, pick, pre, assert, assertWith, monitor, stop, wp, forAllM, monadicIO, monadicST, runSTGen), assertException and assertDeepException, and model-based testing of mutable APIs with generated command sequences in plain QuickCheck, plus where dedicated state-machine libraries fit. Use when a property needs IO or ST, when testing a mutable data structure, database, file, or service against a model, when IO properties do not shrink, or when someone asks how to test imperative or stateful code with QuickCheck.
user-invocable: true
disable-model-invocation: false
---

# Monadic and stateful properties

**Scope:** properties whose test runs effects, and stateful systems tested
against models. Pure model-based specifications are in
[qik-chk-property-design](../qik-chk-property-design/SKILL.md); domain
recipes (protocols, databases) in
[qik-chk-applications](../qik-chk-applications/SKILL.md).

**Prerequisites:** [qik-chk-properties](../qik-chk-properties/SKILL.md),
[qik-chk-generators](../qik-chk-generators/SKILL.md),
[qik-chk-shrinking](../qik-chk-shrinking/SKILL.md).

**Version:** QuickCheck 2.19.0.0, `src/Test/QuickCheck/Monadic.hs` and
`Property.hs` at commit `3d8fe868`. Method background: Claessen and Hughes,
*Testing Monadic Code with QuickCheck* (Haskell Workshop 2002), linked from
the module documentation.

## Choose the tool

| Need | Use | Shrinks |
|---|---|---|
| Inputs are pure; the check runs IO | `prop x = ioProperty (do ...; return (r === e))` | `x` shrinks; the IO reruns per candidate |
| As above, and the IO is idempotent and expensive | `idempotentIOProperty` | also shrinks values generated inside the action, but the IO may run only once and be reused |
| Interleave generation, effects, preconditions, and observations | `monadicIO` with `pick`, `run`, `pre`, `assert`, `monitor` | outer arguments yes; `pick` values **never** |
| Code in `ST` | `monadicST` (or `runSTGen` for a `Gen (ST s a)`) | as `monadicIO` |
| Expect a specific exception | `assertException p v` (WHNF), `assertExceptionIO p io`, `assertDeepException` (NF, needs `NFData`) | normal |
| A stateful API | generate a command list, run it against the system and a model ([below](#model-based-testing-of-stateful-apis)) | the command list shrinks |

There is no `Testable (IO a)` instance in 2.19: an `IO Bool` must go through
`ioProperty` or `monadicIO`.

## Procedure: an IO property

1. **Generate outside the action.** Take inputs as arguments or with
   `forAll`; they then shrink, and each shrink candidate reruns the action.
   The `ioProperty` warning: random values generated inside its argument are
   not shrunk.
2. **Set up fresh state inside the action** (new `IORef`, temp directory,
   empty database). Shared state between tests makes failures irreproducible
   and shrinking unreliable, because every candidate reruns the action.
3. **Return a `Testable` result**: `===` or `counterexample` for good
   messages.
4. **Clean up** with `bracket` or `finally`; a failing test throws.

```haskell
prop_bump :: [Int] -> Property
prop_bump ks = ioProperty $ do
  ref <- newIORef 0
  mapM_ (bump ref) ks
  n <- readIORef ref
  return (n === sum ks)
```

Executed in [MonadicIO.hs](examples/MonadicIO.hs): the seeded bug (increments
above 10 are lost) shrank to `[11]` with `0 /= 11`.

## PropertyM

`newtype PropertyM m a = MkPropertyM ((a -> Gen (m Property)) -> Gen (m Property))`
(L121): a continuation over generators of monadic properties. Combinators
(lines in `Monadic.hs`):

| Combinator | Type (simplified) | Meaning |
|---|---|---|
| `run` (L219) | `m a -> PropertyM m a` | perform an action; also `lift`/`liftIO` via `MonadTrans`/`MonadIO` |
| `pick` (L225) | `Show a => Gen a -> PropertyM m a` | generate a value, printed in counterexamples; not shrunk |
| `forAllM` (L243) | `Gen a -> (a -> PropertyM m b) -> PropertyM m b` | `pick` with a continuation |
| `pre` (L204) | `Bool -> PropertyM m ()` | precondition: discard the test like `==>` |
| `assert` (L161) | `Bool -> PropertyM m ()` | fail with "Assertion failed" |
| `assertWith` (L181, since 2.14.3) | `Bool -> String -> PropertyM m ()` | also prints `Passed: msg` or `Failed: msg` |
| `monitor` (L259) | `(Property -> Property) -> PropertyM m ()` | apply `counterexample`, `classify`, `collect`, ... |
| `stop` (L155) | `Testable p => p -> PropertyM m a` | end with a given property |
| `wp` (L237) | `m a -> (a -> PropertyM m b) -> PropertyM m b` | `run m >>= k` (weakest precondition) |
| `monadic` (L264), `monadic'` (L267) | runner for any monad | `monadic runner m` |
| `monadicIO` (L284) | `PropertyM IO a -> Property` | `monadic ioProperty` |
| `monadicST` (L303), `runSTGen` (L306) | rank-2 `ST` runners | |

Since 2.10 the final value `a` of a `PropertyM m a` must be `Testable` and
is tested; `()` is `Testable` and always succeeds. `fail` (from
`MonadFail`) fails the property with its message, so a refutable pattern in
`do` that does not match fails the test.

`pre` placement matters: a precondition after expensive `run` steps wastes
those steps on every discarded test, and a failing precondition still
counts toward the discard limit ([qik-chk-running](../qik-chk-running/references/result-fields.md#when-the-runner-stops)).

## Model-based testing of stateful APIs

Plain QuickCheck has no state-machine framework; the pattern (from the 2002
paper's model-based sections) is:

1. **Model** the system as a pure value (`[Int]` for a queue, `Map` for a
   key-value store).
2. **Commands** as a data type, with `Show`, one constructor per API call.
3. **A step function** `Model -> Cmd -> (Response, Model)` giving the
   expected response and next model state.
4. **Generate command lists**, ideally depending on the model state when
   commands have preconditions (generate with an accumulating model, or
   filter with the model during execution).
5. **Run** the list against a fresh system, comparing each response with the
   model's; report the first mismatch with `counterexample`.
6. **Shrink** the command list with `shrinkList`, plus a shrinker for single
   commands. If commands have preconditions, re-validate shrunk lists against
   the model (skip or discard invalid ones), or shrinking produces invalid
   programs ([qik-chk-shrinking](../qik-chk-shrinking/SKILL.md)).

Executed in [CommandSequences.hs](examples/CommandSequences.hs): a bounded
queue whose `pop` on exactly three elements returns the newest element.
Recorded:

```text
*** Failed! Falsified (after 7 tests and 7 shrinks):
[Push 0,Push 0,Push 1,Pop]
after Pop: got Right (Just 1), model says Right (Just 0)
```

The shrunk program needs three pushes with differing first and last values,
which is why it is not `[Push 0,Push 0,Push 0,Pop]`.

More techniques (observational equivalence, relational models,
pre/postconditions, parallel testing and the libraries that implement full
state-machine testing): [references/stateful-testing.md](references/stateful-testing.md).

## Pitfalls

- **`pick` values do not shrink**, and `ioProperty` turns off shrinking of
  anything generated inside its action. Counterexamples from `monadicIO`
  properties are therefore often large. Move generation into the outer
  arguments when you can.
- **`idempotentIOProperty` with a non-idempotent action** gives wrong
  shrinking results: during shrinking it may reuse one execution.
- **Leaking state between tests** (global `IORef`, a shared database):
  replay and shrinking assume a test's outcome depends only on its inputs.
- **Lazy results escape the exception handler.** `assertException` checks
  WHNF only; use `assertDeepException` for exceptions hidden inside a
  structure. Exceptions of a different type than the predicate's propagate
  and fail the test.
- **Asynchronous exceptions** (timeouts, Ctrl-C) are not caught as test
  failures since 2.10 ([qik-chk-running](../qik-chk-running/SKILL.md)).
- **Concurrency** is nondeterministic: a passing run proves little, and a
  failing seed may not replay. See the reference for approaches.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Large unshrunk counterexample from `monadicIO` | values from `pick` | generate as outer arguments, or `forAllShrink` around `monadicIO` |
| Failure does not reproduce with the same seed | state shared across tests, time, or concurrency | fresh state per test; inject clocks; isolate |
| `No instance for (Testable (IO Bool))` | missing runner | `ioProperty` or `monadicIO` |
| Many discards | `pre` too strong | generate valid inputs, or derive commands from model state |
| Shrinking takes very long | each candidate reruns expensive IO | `withMaxShrinks`, cheaper setup, or `idempotentIOProperty` when safe |

## Executable examples

| File | Shows |
|---|---|
| [MonadicIO.hs](examples/MonadicIO.hs) | `ioProperty` with shrinking inputs, `PropertyM` with `pick`/`pre`/`monitor`/`assert`, `assertWith`, `assertException(IO)`, `monadicST` |
| [CommandSequences.hs](examples/CommandSequences.hs) | model-based testing of an `IORef` queue with generated and shrunk command lists |

Run: `qik-chk-workflow/scripts/run-examples.sh qik-chk-monadic-state`.

## Go deeper

- [references/stateful-testing.md](references/stateful-testing.md): the 2002
  paper's specification styles, generating valid command sequences,
  observational equivalence, and external state-machine libraries.
