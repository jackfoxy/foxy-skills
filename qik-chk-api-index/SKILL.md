---
name: qik-chk-api-index
description: Complete API index of QuickCheck 2.19.0.0 - every function, type, class, constructor and field exported by Test.QuickCheck and by each exposed module (Arbitrary, Gen, Gen.Unsafe, Modifiers, Function, Property, Test, Monadic, Poly, Monoids, Features, All, Random, State, Exception, Text, Compat), with cleaned signature, purpose, stability or deprecation, the skill that explains it, and a permalink to its definition at the pinned commit. Use when someone asks what a QuickCheck function does or which module exports it, needs a signature, wants to know whether a name is deprecated or internal, or needs the full list of available combinators, modifiers, or instances.
user-invocable: true
disable-model-invocation: false
---

# QuickCheck API index

**Scope:** lookup. Each row points to the skill that teaches the symbol.

**Prerequisites:** none.

**Version:** QuickCheck 2.19.0.0, commit
`3d8fe8686024760006ca1ca656cbdd82cd71f11e`. Signatures from GHCi
`:browse` with GHC 9.10.3 (package and module qualifiers removed). Other
versions differ: check the [history](../qik-chk-history/SKILL.md) for
changes.

## Where to look

| You want | File |
|---|---|
| Anything importable from `Test.QuickCheck` (the normal import), in Haddock order | [references/test-quickcheck.md](references/test-quickcheck.md) (188 rows) |
| `Monadic`, `Function`, `Gen`, `Gen.Unsafe`, `Poly`, `Modifiers`, `Arbitrary`, `Monoids`, `Features`, `All`, `Random`, `Compat` | [references/other-modules.md](references/other-modules.md) (173 rows; **only here** marks names not re-exported by `Test.QuickCheck`) |
| `Property`, `Test`, `State`, `Text`, `Exception` internals | [references/internal-modules.md](references/internal-modules.md) (169 rows) |

Search a file for the name in backticks (for example `` `forAllShrink` ``).
Operators appear in parentheses; `|` is escaped as `\|` in tables, so
`.||.` is written `(.\|\|.)`.

## Row format

`| symbol | signature or shape | purpose and semantics | owner skill [src] |`

- **Signature**: as GHCi prints it, with qualifiers removed; classes show
  their methods; records their fields.
- **Purpose**: one or two sentences, including the non-obvious behaviour
  (for example `quickCheck` does not set an exit code; `pick` values do not
  shrink).
- **Owner**: the qik-chk skill that explains it.
- **[src]**: GitHub permalink to the definition line at the pinned commit
  (every row has one).

## Stability classes

| Class | Meaning | Where |
|---|---|---|
| Public | documented API, re-exported by `Test.QuickCheck` or in a documented module | main index, other-modules |
| Documented module only | public but must be imported from its module (`Test.QuickCheck.Monadic`, `Function`'s `:->`, `Gen`'s `unGen`, ...) | rows marked **only here** |
| Haddock-hidden | exposed modules with `OPTIONS_HADDOCK hide`: `Property`, `Test`, `Features`, `Random`, `State`, `Exception`, `Text`; anything not re-exported can change in any release | internal-modules, parts of other-modules |
| Deprecated | `DEPRECATED` pragma at 2.19: `withMaxSuccess` (use `withNumTests`), `printTestCase` (use `counterexample`), `(><)` (use composition), `morallyDubiousIOProperty` (use `ioProperty`) | marked in rows |
| Conditional | absent on some compilers: `Test.QuickCheck.All` (needs TH), `witness`/`witnesses` (Typeable), generic functions (`GHC.Generics`), `monadicST` (ST) | see [qik-chk-workflow](../qik-chk-workflow/SKILL.md#compatibility) |

## Frequently needed facts

| Need | Answer |
|---|---|
| Run a `Gen` with a fixed seed | `unGen g (mkQCGen n) size`, importing `Test.QuickCheck.Gen` and `Test.QuickCheck.Random` |
| Function type for properties over functions | `Fun a b` with `applyFun`/`Fn`; `:->` and `Function` from `Test.QuickCheck.Function` (main module exports `Fun`, `Function`, `applyFun`, ...) |
| Testing IO | `ioProperty` (main module); `monadicIO`, `run`, `pick`, `assert` (`Test.QuickCheck.Monadic`) |
| Modifiers | `Positive`, `NonNegative`, `NonZero`, `Small`, `Large`, `OrderedList`, `SortedList`, `NonEmptyList`, `InfiniteList`, `Shrink2`, `Smart`, `Blind`, `Fixed`, `ASCIIString`, `UnicodeString`, `PrintableString`, `Negative`, `NonPositive`, `Sorted` (field names `get...`) |
| Result inspection | `Result` constructors and fields, `isSuccess` ([qik-chk-running](../qik-chk-running/references/result-fields.md)) |

## Pitfalls

- **Version drift.** Rows describe 2.19.0.0; a name present here may be
  missing or different in older releases (see
  [qik-chk-history](../qik-chk-history/references/timeline.md)).
- **Internal names are not API.** Rows in `internal-modules.md` (and
  Haddock-hidden modules generally) can change in any release.
- **Same name, different type.** `Result` exists in `Test.QuickCheck.Test`
  (run result) and `Test.QuickCheck.Property` (per-test result); `reason`
  and `theException` are fields of both.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Variable not in scope: unGen` (or `:->`, `run`, `pick`) | not re-exported by `Test.QuickCheck` | import the module the row names (rows marked **only here**) |
| A row's signature differs from your compiler's output | another QuickCheck version, or GHC printing kinds differently | check `ghc-pkg list QuickCheck`; rerun `browse-api.sh` |
| Name not in the index | not exported at 2.19 (local helper, other package) | search the source at the pinned commit; check companion packages |

## Regenerating and checking

[scripts/browse-api.sh](scripts/browse-api.sh) dumps `:browse` of all 18
exposed modules (qualifiers stripped) and reports every exported top-level
name that does not appear in backticks in the three index files:

```bash
export PATH=$HOME/.ghcup/bin:$PATH
qik-chk-api-index/scripts/browse-api.sh /tmp/quickcheck-api.txt
```

Recorded for this pack: 339 distinct exported names, 0 missing (exit 0);
with `shrinkIntegral` removed from a copy of the index, the script
reported it under both modules and exited 1. It checks names, not the
signatures or the prose, and it does not check constructors and class
methods separately from their type. Run it against a new QuickCheck
version to find additions.
