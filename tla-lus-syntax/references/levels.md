# Levels, Names, and Instantiation

`desk/lib/semantic.hoon` is the port of SANY's semantic pass: name resolution,
arities, the builtin table, per-definition levels, and `INSTANCE` substitution.
It is at parity (108 differential cases via `tools/gen-sem-tests.py`), including
parametrized, nested and higher-order instantiation, `RECURSIVE`-through-`WITH`,
`LAMBDA` and higher-order operator arguments, and tuple / operator-symbol
binders.

## The four levels

| Level | Name | Contains |
|---|---|---|
| 0 | constant | no variables, no priming, no temporal operators |
| 1 | state | variables, unprimed |
| 2 | action | primed variables, `UNCHANGED`, `ENABLED`, `\cdot` |
| 3 | temporal | `[]`, `<>`, `~>`, `-+->`, `WF_`, `SF_`, `\EE`, `\AA` |

Level is computed per definition and propagates through application. The rules
that actually cause errors:

- **`ASSUME` is constant-level.** Asserting a variable's type in an `ASSUME` is
  a level error, not a weak invariant.
- **`CONSTANT` declarations are level 0**; a `.cfg` may only assign level-0
  values to them.
- **Priming an expression primes every flexible variable in it.** `f[e]'` means
  `f'[e']` — not `f'[e]`.
- **A bare action under a temporal operator is generally illegal.** Use
  `[A]_v`, `<<A>>_v`, `WF_v(A)`, `SF_v(A)`.
- `ENABLED` and `\cdot` raise level to action; putting either under `[]`
  directly is a level error.
- An `INVARIANT` must be level ≤ 1; a `PROPERTY` may be level 3. An
  `ACTION_CONSTRAINT` is level 2, a `CONSTRAINT` level 1.

A level violation is reported as a SANY-family diagnostic with the pin's own
text and a source span. See `tla-lus-debugging`.

## Name resolution and scope

- A quantifier binds its identifier only in the **body**, not in its bounding
  set.
- Definitions are visible from their point of definition onward; module-level
  order matters.
- An operator is **not a value**. You cannot pass `Op` where a value is
  expected; pass `LAMBDA` or use a higher-order parameter declaration
  (`Op(_, _)`).
- Arity is checked: applying a 2-ary operator to 1 argument is a semantic
  error, not a partial application.
- Duplicate declarations and shadowing are reported.

## `EXTENDS` versus `INSTANCE`

- `EXTENDS M` imports `M`'s definitions **and** its declarations into the
  current module's namespace; the module is elaborated once in
  dependency-first order (`desk/lib/modules.hoon`, with a parse cache).
- `INSTANCE M WITH v <- e, c <- d` **substitutes** for `M`'s declared variables
  and constants. Unnamed `INSTANCE` imports the substituted definitions
  directly; a named instance (`I == INSTANCE M WITH …`) reaches them as
  `I!Def`, and a parametrized one as `I(x)!Def`.
- **Substitution is not textual replacement.** It avoids capture and handles
  implicit binding inside `ENABLED`, `\cdot`, `WF_`/`SF_` and the guarantee
  operator. Do not assume substitution distributes through any of them.

## Module resolution in this engine

`desk/lib/modules.hoon` resolves `EXTENDS`/`INSTANCE` into a dependency-first
semantic order over a `resolver` gate:

- For an `%inline` bundle, `inline-resolver:modules` serves module text from
  the request's `(map module-name @t)`.
- For a `%clay` bundle, the `%modules` stage **names** the files it needs and
  the agent fetches them (see `tla-lus-internals`). Resolution mirrors the
  inline resolver exactly, so a Clay run reaches the same module graph — and
  the same verdict, report and counterexample — as an inline bundle of the same
  files.
- Standard modules resolve from `desk/lib/stdmods.hoon` (vendored MIT text),
  never from the bundle. See `tla-lus-stdlib`.
- **Module name, not file name.** The root of a bundle is a `module-name`. For
  Clay, file names are lowercased (path segments carry no case) but the
  declared module-name check still validates the original case.
