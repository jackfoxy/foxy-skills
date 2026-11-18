# Scalar functions

Named computed expressions in the optional `SCALARS` clause (after `FROM`/joins, before `WHERE` in a query; before the verb in `UPDATE`/`DELETE`). Reference scalar names in `SELECT` and `WHERE`; later scalars may reference earlier ones.

```
SCALARS { <name> <scalar-function> } [ ...n ]

<scalar-node> ::= <scalar-function> | <qualified-column> | <unqualified-column> | <cte-column> | <literal>
```

A `<cte-column>` operand requires the CTE to have returned exactly one row.

## Inline invocation

Any scalar function may also be written in place, without a `SCALARS` definition: in `SELECT` (with or without `AS`), in `WHERE` predicates of queries, `UPDATE`, and `DELETE`, in `UPDATE` `SET` values, and in `IF`/searched-`CASE` predicates (also inside `SCALARS` definitions). It behaves exactly like a `SCALARS` definition referenced by name.

```
FROM adoptions
WHERE YEAR(adoption-date) = 2024 AND LEN(name) > 3
SELECT UPPER(name) AS name, species, adoption-fee * 2;

UPDATE adoptions SET adoption-fee = adoption-fee + 5 WHERE LOWER(species) = 'cat';
```

- Inline arithmetic takes **no `END`**; it ends at the first non-operator token. `ABS(col1) + 1` is one arithmetic expression.
- Unaliased inline `SELECT` items are named `scalar-<n>` (zero-based `SELECT` position), like `literal-<n>` for literals.
- Standing alone, constants need parentheses inline: `PI()`, `E()`, `TAU()`, `PHI()`. Bare `PI` etc. only as arithmetic operands or function arguments. A `FROM` column named `e`/`pi`/`tau`/`phi` takes precedence over the constant everywhere, even over `PI()`.
- `GETUTCDATE()` is the query time everywhere; each `RAND` call is evaluated separately.
- Two-argument `MIN`/`MAX` are scalars; one-argument `MIN(col)`/`MAX(col)` are aggregates (see [queries.md](queries.md)). In `SELECT`/`HAVING` an aggregate may be a scalar argument or arithmetic operand; aggregates are not allowed in the SCALARS clause or `WHERE`.
- **Not allowed** in `JOIN ... ON` predicates (`scalar functions are not supported in this predicate`), `INSERT`/`UPSERT` `VALUES`, `MERGE`, `GROUP BY`, `ORDER BY`.
- AST: each inline call becomes a generated scalar `inline.<i>` appended to the statement's `scalars` (after `SCALARS` definitions; `<i>` is its index in that list) and is referenced as `[%scalar-name 'inline.<i>']` / `[%selected-scalar 'inline.<i>' alias]`.

```
FROM adoptions A
SCALARS full-label CONCAT(name, ' (', species, ')')
        fee-tier IF adoption-fee > 75 THEN 'premium' ELSE 'standard' ENDIF
SELECT name, species, adoption-date, full-label, fee-tier;
```

## Control flow

```
IF <predicate> THEN <scalar-node> ELSE <scalar-node> ENDIF
CASE [ <scalar-node> ] WHEN { <scalar-node> | <predicate> } THEN <scalar-node> [ ...n ] [ ELSE <scalar-node> ] END
COALESCE ( <scalar-node> [ ,...n ] )
```

- `IF` — `ELSE` is required; `THEN`/`ELSE` must be the same type, or numeric (converted to their common type, see Mixed numerics).
- `CASE` — **simple form** with a leading expression compares it to each `WHEN` value; **searched form** omits it and evaluates each `WHEN` as a predicate. First match wins. `ELSE` optional; with no match and no `ELSE` the query crashes. All `THEN`/`ELSE` must share a type or be numeric (converted to their common type). Simple-form numeric `WHEN` values match by exact value across types.
- `COALESCE` — first existing argument (outer joins); none exists → result does not exist. Numeric arguments convert to their common type.

## Arithmetic

```
<arithmetic-op> ::= + | - | * | / | % | ^
```

- Operands are a numeric type: unsigned `@ub` `@ud` `@uv` `@uw` `@ux` (all compute as `@ud`), signed `@sb` `@sd` `@sv` `@sw` `@sx` (all compute as `@sd`), float `@rh` `@rs` `@rd` `@rq`. Any numeric types mix; the result is their common type (see Mixed numerics), and a numeric with a non-numeric type conflicts (`number system conflict: ~.ud %lus ~.t`). Unsigned subtraction below zero crashes. `%` on a float crashes (`remainder not implemented for @rd`). `x ^ -y` is `1 / x ^ y`; `0 ^ -1` is division by zero. Float operations round toward zero.
- `/` on integer types is **integer division** and truncates toward zero: `5 / 2 END` is `2`, not `.~2.5`. Use float operands for a fractional result.
- An arithmetic scalar in the `SCALARS` clause must **terminate with `END`**: `col1 + col2 * 3 END`. Inline arithmetic has no `END`.
- Put whitespace between a numeric literal and a following operator (`1+1` fails; `1 +1`, `1 + 1` work). After a column or `)` none is needed, except `-`, which a column name absorbs.
- Precedence: `^` (highest), then `*` `/` `%`, then `+` `-`. `^` is right-associative; the rest left-associative. Parentheses override.
- Only mathematical functions and constants (below) may appear inside arithmetic — not string functions.

```
2 + 3 * 4 END            :: 14
2 ^ 3 ^ 2 END            :: 512 (right-assoc)
(ABS(--3) + FLOOR(.~2.9)) * SQRT(16) END
```

## Mixed numerics

Every operand converts to the operation's **common type** before it runs; comparisons instead compare exact values.

- Common type = most granular: float > signed > unsigned.
  - floats: the wider, `@rq` > `@rd` > `@rs` > `@rh`.
  - integer + float: the float, but at least `@rd` (`@ud + @rh` → `@rd`).
  - signed + unsigned → signed. Same notation kept (`@ux + @sx` → `@sx`), different notations → decimal (`@ux + @ud` → `@ud`, `@sx + @ud` → `@sd`).
  - sized: sized + unsized keeps the width (`@udD + @ud` → `@udD`, `@udD + @sd` → `@sdD`); two widths → the larger (`@udD + @udE` → `@udE`).
  - commutative and associative; non-numeric types combine only with themselves.
- Conversion: float widening and unsigned→signed are exact; integer→float rounds past the float's precision (2^53 for `@rd`). A value converted to a sized type must fit: `@udD 200 + @sd` crashes `--200 exceeds @sdD`.
- `^`: the base's type, except (in order) a float exponent → common type (`2 ^ .~0.5` → `@rd`); a float base with an integer exponent stays its type (`.~~1.5 ^ 2` → `@rh`); an integer base with a negative literal or any non-literal signed exponent → `@rd`, even `@sd ^ @sd`-column (`2 ^ -3` → `.~0.125`); an unsigned base with a non-negative signed literal exponent becomes signed (`@ux ^ --2` → `@sx`). The exponent itself is not converted.
- One-argument functions compute in their argument's type. `MAX`, `MIN`, `RAND`, and `IF`/`CASE`/`COALESCE` branches convert to the common type. `ATAN2` uses the common float, `@rd` for two integers.
- Comparisons (`=` `<>` `<` `>` `<=` `>=`, `BETWEEN`, `IN`/`NOT IN`, simple `CASE` `WHEN`, `JOIN ... ON`) are exact by value: `--2 = .~~2`; `9.007.199.254.740.993 > .~9007199254740992`; `.~0 = .~-0`; NaN equals nothing (only `<>` is true).
- Not converted: `INSERT`/`UPSERT`/`UPDATE` values (column type or its sized/unsized base only), set operations, foreign keys, natural joins (same name and aura).

## DateTime

`GETUTCDATE()` · `YEAR(t)` · `MONTH(t)` · `DAY(t)` · `HOUR(t)` · `MINUTE(t)` · `SECOND(t)` · `ADD-TIME(t, dr)` · `SUBTRACT-TIME(t, dr)`

- `t` is `@da` or `@dr`. For a `@dr`, the component functions return whole units (`HOUR(~d1h3)` → 27). `YEAR`/`MONTH` apply to `@da`.
- `ADD-TIME`/`SUBTRACT-TIME` take a date-or-duration plus a `@dr`; result type matches the first arg.

## System

`VERSION()` — Obelisk version from `desk.docket-0` as `@t` `'<major>.<minor>.<patch>'`, fixed at desk build time.

## Mathematical

`ABS` · `LOG` (natural; crashes ≤0) · `FLOOR` · `CEILING` · `ROUND(value, length)` · `SIGN` · `SQRT` (crashes <0) · `MAX(a,b)` · `MIN(a,b)` · `RAND(low,high)` · `DEGREES` · `SIN` · `COS` · `TAN` · `ASIN` · `ACOS` · `ATAN` · `ATAN2(y,x)`

- All accept any numeric type; two-arg functions take any numeric mix, converted to the common type. Result type generally matches input; `LOG`, `SIN`…`ATAN2` keep a float aura and return `@rd` for integers. `ROUND` length is any integer type. Integer `^`, `SQRT`, `DEGREES` compute in `@rd` and truncate, so values beyond 2^53 lose precision.
- `ROUND` length: positive rounds to that many decimals; negative (`@sd` only) rounds to `10^|length|`; round-half-up toward +inf.
- `RAND(low, high)` is inclusive both ends; **the only non-deterministic `SELECT`** — emits `warning: results are non-deterministic`.

Constants (`@rd`, usable in arithmetic): `PI`, `TAU`, `E`, `PHI`.

### Float accuracy

Float math (`@rh`, `@rs`, `@rd`, `@rq`) is **not IEEE-754 round-to-nearest**. The stdlib float doors default to **round toward zero**; only literal parsing rounds to nearest (ties to even). Two tiers:

- **Single-step (stdlib, one rounding toward zero):** `+` `-` `*` `/`, `ABS`, `SQRT`, `FLOOR`, `CEILING`, `SIGN`, `MIN`, `MAX`. Results are deterministic but can be one ulp below the round-to-nearest value other engines return.
- **Series (pure Hoon in `lib/math`, toward zero at every step):** `LOG`, `SIN`, `COS`, `TAN`, `ASIN`, `ACOS`, `ATAN`, `ATAN2`, `DEGREES`, and `^`. Iteration stops at a tolerance of about 5 ulp of 1.0 (`@rh` `5e-3`, `@rs` `5e-7`, `@rd` `1e-15`, `@rq` `1e-33`). Not correctly rounded; expect last-digit divergence from libm, and never test with exact equality against a literal.

`SIN`, `COS` and `TAN` are only reliable for `0 <= x < TAU`; `lib/math` has no float range reduction except for `@rs`. `@rh` has about three significant digits, so its `TAU` is `.~~6.28` and series results are coarse; `DEGREES` on `@rh`/`@rs` uses the `@rd` value of `TAU`, converted.

`^` is **not** a correctly rounded `pow`. Integer exponents are repeated multiplication (error accumulates per multiply); fractional exponents are evaluated as `EXP(n * LOG(x))`. So `.~2.0 ^ .~0.5 END` and `SQRT(.~2.0)` can disagree, as can `.~2.0 ^ .~-1.0 END` and `.~1.0 / .~2.0 END`. Prefer `SQRT` over `^ .~0.5`, and division over a negative exponent. A negative base with a float exponent that is not a positive whole number (`.0` included) does not terminate.

`ROUND` on a float scales by `10^length` through `^` (repeated multiplication), so rounding to many decimal places is itself inexact.

Comparisons (`=` `<>` `<` `>` `<=` `>=` `IN` in `WHERE`) and `ORDER BY` use float ordering for all four auras. Primary-key and index ordering use float ordering only for `@rd` and signed ordering only for `@sd`; `@rh`, `@rs`, `@rq`, `@sb`, `@sv`, `@sw` and `@sx` keys sort by raw bits, so negative values sort wrong. Predicates and `ORDER BY` compare every signed aura as signed. `-0.0` and `0.0` compare **equal** in a predicate but are **distinct** key values; avoid negative zero in indexed columns.

These are properties of the Urbit float libraries, not of urQL, and may change as `lib/math` gains jets.

## String

`LEN` · `LEFT(s,n)` · `RIGHT(s,n)` · `SUBSTRING(s, start [, len])` (1-based) · `LOWER` · `UPPER` · `LTRIM(s [,pat])` · `RTRIM(s [,pat])` · `TRIM(s [,pat])` · `CONCAT(s [,...n])` · `REPLACE(s, pat, repl)` · `REPLICATE(s, n)` · `REVERSE(s)` · `STRING(num)` · `STRING-CONCAT(s [,...n], delim)` · `PATINDEX(s, pat)` (1-based, 0 if absent) · `QUOTESTRING(s [, open, close])` (default `[ ]`) · `STUFF(s, start, del-count, repl)` (1-based)

- String args/returns are `@t`. `STRING` converts a number to `@t`; `LEN`/`PATINDEX` return `@ud`.
- `STRING-CONCAT`'s **last** argument is the delimiter.
