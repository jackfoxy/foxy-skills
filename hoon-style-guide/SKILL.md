---
name: hoon-style-guide
description: Comprehensive style guide for writing clean, idiomatic, and maintainable Hoon code following community conventions including naming, formatting, documentation, and idiomatic patterns. Use when writing new code, reviewing code, establishing team standards, or ensuring code quality.
user-invocable: true
disable-model-invocation: false
validated: safe
checked-by: ~sarlev-sarsen
---

# Hoon Style Guide Skill

Comprehensive style guide for writing clean, idiomatic, and maintainable Hoon code following desired conventions. Use when writing new code or reviewing code.

## Overview

This guide covers naming conventions, code organization, formatting, documentation practices, and idiomatic patterns that make Hoon code readable and maintainable.

## Learning Objectives

1. Follow Hoon naming conventions
2. Format code for readability
3. Write effective comments and documentation
4. Organize code into coherent structures
5. Apply idiomatic Hoon patterns
6. Avoid common anti-patterns

Syntax and compiler-failure details belong in the companion skills:
`hoon-basics` for parseability and rune usage, `type-system` for casts and
molds, `data-structures` for container APIs, and
`debugging-specialist-assistant` for compiler/runtime failures.

## 1. Naming Conventions

### faces

1. arm names `++`
2. type names `+$`
3. named nouns '=/'

**Use lowercase with hyphens**:
```hoon
::  ✓ Good
++  parse-input
++  validate-user
++  get-current-time
+$  user-profile
=/  user-id  42

::  ✗ Bad, will not build
++  parseInput      :: camelCase
++  ParseInput      :: PascalCase
++  parse_input     :: snake_case
+$  UserProfile    :: PascalCase
+$  user_profile   :: snake_case
=/  userId  42
```

## 2. Code Formatting

### Line Length

**maximum of 80 characters**:
```hoon
::  ✓ Good: Wrap and properly indent long lines
=/  very-long-computation
  %+  combine-results  %+  first-complex-operation  input-data
                                                    threshold
                       default-value

::  ✗ Bad: Too long
=/  very-long-computation  (combine-results (first-complex-operation input-data threshold) default-value)
```

**when wide form exceeds 80 characters**
```hoon
::  ✗ Bad: wide format too long
~|("resolve selected-cte-column: no rows in cte {<cte.selected>}" !!) 

::  ✓ Good: use tall format and align rune parameters
~|  "resolve selected-cte-column: no rows in cte {<cte.selected>}"
    !!

::  ✓ Good: continue message on next ling by adding dot after closing quote
~|  "resolve selected-cte-column: no rows in cte ".
    "and tape must be broken up into multiple lines {<cte.selected>}"
    !!
```

### Indentation

**Use 2 spaces** (not tabs):
```hoon
|%
++  example
  |=  input=@t
  ^-  @ud
  =/  processed  (parse input)
  ?~  processed
    0
  u.processed
--
```

### Wide Form Usage

**Use for simple expressions**:
```hoon
::  ✓ Good: Simple operations
=/  sum  (add a b)
=/  doubled  (mul n 2)
?:(=(x 0) 'zero' 'non-zero')

::  ✓ Good
=/  target-val  (apply-scalar data-row +.target-ps)

::  ✗ Bad
?:  condition
=/  target-val  %+  apply-scalar  data-row
                                  +.target-ps
```

### Tall Form Alignment

**Align children under parent**:
```hoon
::  ✓ Good
?:  condition
  true-branch
false-branch

=/  value
  %+  function  arg-1
                arg-2

::  ✗ Bad
?:  condition
true-branch
false-branch
```

### Tall Form Cell Alignment
Tall form is the default for cell construction. Use wide form only when the
complete expression fits on one 80-character line — and when it does, prefer
it: [%pass wire %arvo %b %wait when] beats a four-line :*. Apply the rule
consistently within a file; a :* for one card and […] for its neighbour
is noise.

align all cell items to the same column
```hoon
::  ✓ Good
:+  %fn  type.expr
          |=  =data-row
          ^-  dime
          ?-  number-system
              ::
              %rd  :-  number-system
                      (~(abs rd:math [%z .~1e-15]) +:(f.expr data-row))
              ::
              %sd  [number-system (sun:si (abs:si +:(f.expr data-row)))]
              ::
              %ud  (f.expr data-row)
              ==

::  ✗ Bad
:+  %fn
  type.expr
  |=  =data-row
  ^-  dime
  ?-  number-system
      ::
      %rd  :-  number-system
                (~(abs rd:math [%z .~1e-15]) +:(f.expr data-row))
      ::
      %sd  [number-system (sun:si (abs:si +:(f.expr data-row)))]
      ::
      %ud  (f.expr data-row)
      ==
```


For syntax constraints on wide, tall, bracket, and paren forms, use
`hoon-basics`. This section only covers readability preferences.

## 3. Comments and Documentation

### File Headers

arm and core header blocks gap indented 

**Document purpose and structure**:
```hoon
|%
  ::  User Management Library
  ::
  ::  Provides functions for creating, updating, and querying user data.
  ::  Implements validation, password hashing, and role-based access.
  ::
  ::  Usage:
  ::    =/  user  (create-user 'alice@example.com' 'password')
  ::    =/  valid  (validate-credentials user credentials)
  ::
...
--
```

### Arm Documentation

1. one empty comment line before ++ arm
2. arm description comments gap indented

**Describe purpose**:
```hoon
::
++  parse-http-request
  ::  Parse an HTTP request into structured data
  ::
  ::  Returns:
  ::    unit of parsed request, ~ if invalid
  |=  raw-request=@t
  ^-  (unit http-request)
  ...
```

### Inline Comments

**Explain why, not what**:
```hoon
::  ✓ Good: Explains reasoning
=/  timeout  ~s30
::  30-second timeout prevents hanging on slow connections

::  ✗ Bad: States the obvious
=/  timeout  ~s30
::  Set timeout to 30 seconds
```

## 4. Code Organization

### Core Structure

**Organize from general to specific**:
```hoon
|%
::  +|  Types
::
+$  user  [id=@ud name=@t]
+$  state  [users=(map @ud user)]

::  +|  Constants
::
++  max-users  1.000
++  default-name  'Guest'

::  +|  Public API
::
++  create-user
  ...
++  get-user
  ...

::  +|  Internal Helpers
::
++  validate-name
  ...
++  generate-id
  ...
--
```

### File Organization

**One major component per file**:
```
/lib/user-management.hoon     :: User CRUD operations
/lib/authentication.hoon      :: Auth logic
/lib/validation.hoon          :: Input validation
/sur/types.hoon               :: Shared type definitions
```

### Arms

Do not propogate unnecessary arms.
Short helper arms only called from one other arm should be collapsed into the calling arm.

The exception is calling single use arms from ?- ?+ ?: ?. ?^ ?@ ?+ or ?~ where it makes sense to have boundaries.

Do not introduce an arm whose only job is to build a cell. A helper arm earns
its place only when it (a) has more than one caller, or (b) is called from a
?-/?+/?:/?./?^/?@/?~ branch and materially reduces nesting.
Before adding one, count lines both ways: a five-line arm that saves one line
per call site at six call sites is not a win.

## 5. Idiomatic Patterns

### Pattern 1: Safe APIs

Prefer APIs that make failure explicit when absence is expected. Return `unit`
for lookups, parsing, and optional values; reserve crashes for invariant
violations. For container-specific access rules, use `data-structures`.

### Pattern 2: Standard Library Operations

| Intent | Use | Never |
|---|---|---|
| map, dropping `~` results | `murn` | `turn` + `skim` + `?>` |
| all / any | `levy` / `lien` | `?&`/`?\|` recursion; `?=(^ (skim …))` |
| concat-map | `zing` + `turn` | `weld` in a `\|-` (but see "Recursion and wet gates" below) |
| append one element | `snoc` | `(weld a ~[b])` |
| prefix test | `=(a (scag (lent a) b))` | element-wise `\|-` |

```hoon
::  ✓ Good: use a clear stdlib traversal
(turn items |=(n=@ud (mul n 2)))

::  ✗ Bad: hand-rolled recursion for a simple map
|-  ^-  (list @ud)
?~  items  ~
[(mul i.items 2) $(items t.items)]
```

### Pattern 3: Type Annotations

```hoon
::  ✓ Good: Explicit return types
++  process
  |=  input=@t
  ^-  (unit @ud)
  ...

::  ✗ Bad: Inferred (unclear contract)
++  process
  |=  input=@t
  ...
```

### Pattern 4: Crash Handling

Crashes should include useful context. Use `~|` around known crash points, and
put detailed debugging workflows in `debugging-specialist-assistant`.

```hoon
::  ✗ Bad: known danger of crash
(potential-crash param)

::  ✓ Good: guard with message including data
~|  "failed at potential crash site {<param>}"
    (potential-crash param)
```

### Pattern 5: Default Values

```hoon
::  ✓ Good: Provide defaults
++  get-config
  |=  [key=@tas config=(map @tas @t)]
  ^-  @t
  (~(gut by config) key 'default')

::  ✗ Bad: Force caller to handle ~
++  get-config
  |=  [key=@tas config=(map @tas @t)]
  ^-  (unit @t)
  (~(get by config) key)
```

### Pattern 6: quip threading in Gall agents

```hoon
::  ✓ Good
=^  cards  state  (handler args state now.bowl our.bowl)
[cards this]

::  ✗ Bad
=/  result=(quip card app-state)  (handler args state now.bowl our.bowl)
:_  this(state +.result)
-.result
```

`=^` writes through the `=*  state  -` alias and `this` picks up the updated
core, so `this(state …)` is redundant. Likewise `` `this(state state) ``
after a `=.` on `state` is a no-op — write `` `this ``.

**Caveat — these two forms are not interchangeable under refinement.**

`this(state x)` resolves `this` through the `+*` alias, which evaluates `.`
in the *core's own* subject and therefore never sees a `?~`/`?^`/`?=`
refinement made in the arm body. `=^` / `=.` expand to `%=(. state x)` and
write against the **current, refined** subject. So converting
`this(state +.result)` to `=^ cards state` is only safe when nothing earlier
in the arm has narrowed a slot of `state` — see "Type narrowing and
write-back" below.

### Pattern 7: `?-` over a loob

A `?-` with `%.y`/`%.n` arms costs four lines to express a two-way branch.
Use `?:  ?=(%.n -.x)` and let the success path continue at the outer
indentation — this turns nested `each`-handling into a flat sequence of
guards.

```hoon
::  ✓ Good
?:  ?=(%.n -.loaded)  (error-cards p.loaded)
(success-cards p.loaded)

::  ✗ Bad
?-  -.loaded
  %.n  (error-cards p.loaded)
  %.y  (success-cards p.loaded)
==
```

### Pattern 8: list-shape destructuring

Prefer one `?=` over a chain of `?~`/`i`/`t` bindings.

```hoon
::  ✓ Good — "at least four elements", then index directly
?.  ?=([* * * * *] commands)  ~
(f i.commands i.t.commands i.t.t.commands i.t.t.t.commands)
```

## 6. Anti-Patterns to Avoid

### Anti-Pattern 1: Magic Numbers

```hoon
::  ✗ Bad
++  check-limit
  |=  count=@ud
  ?:  (gth count 100)
    'too many'
  'ok'

::  ✓ Good: Named constants
++  max-count  100
++  check-limit
  |=  count=@ud
  ?:  (gth count max-count)
    'too many'
  'ok'
```

### Anti-Pattern 2: Inconsistent Naming

All names below build; the anti-pattern is inconsistent vocabulary and
word order, not illegal characters (for those, see §1).

```hoon
::  ✗ Bad: mixed verbs and word order
++  get-user
++  fetch-account   :: 'fetch' where 'get' is used elsewhere
++  user-remove     :: noun-verb; the others are verb-noun

::  ✓ Good: one verb per action, consistent verb-noun order
++  get-user
++  get-account
++  remove-user
```

### Anti-Pattern 3: duplicated tail in sibling branches

If two branches of a `?^`/`?:` end in the same expression, hoist it into a
`=/` before the test. Two `?-` arms with identical bodies should be one
`?(%a %b)` arm.

## 7. Testing and Examples

### Provide Examples

```hoon
::  ✓ Good: Include usage examples
::
++  create-user
  ::  Example:
  ::    =/  user  (create-user 'Alice' 'alice@example.com')
  ::    =/  saved  (save-user user)
  ::    (get-user id.user)
  |=  [name=@t email=@t]
  ...
```

### Write Testable Code

```hoon
::  ✓ Good: Pure function, easy to test
++  calculate-total
  |=  items=(list @ud)
  ^-  @ud
  (roll items add)

::  ✗ Bad: Side effects, hard to test
::  (Gall agents handle effects separately)
```

## 8. Performance Considerations

### Document Complexity

```hoon
::  ✓ Good: Note performance characteristics
::  O(log n) lookup using map
++  find-user
  |=  [id=@ud users=(map @ud user)]
  (~(get by users) id)

::  O(n) linear search - use sparingly
++  find-by-name
  |=  [name=@t users=(map @ud user)]
  %+  find  ~(tap by users)
  |=([id=@ud user=user] =(name.user name))
```

### Prefer Standard Library

Use jetted standard-library functions for common traversals and container
operations. See `data-structures` for the concrete list, set, map, mop, jar,
and jug APIs.

## 9. Hoon-Specific Conventions

### Face Punning

**Use when faces match types**:
```hoon
::  ✓ Good: Faces match field names
+$  user  [id=@ud name=@t email=@t]

++  create-user
  |=  [name=@t email=@t]
  ^-  user
  [id=0 name email]  ::  Faces match
```

### Bunting for Defaults

Use bunting for default initialization when the mold is clear. See
`hoon-basics` and `type-system` for the mechanics of bunts.

```hoon
::  ✓ Good: Use * for defaults
=/  users  *(map @ud user)
=/  count  *@ud

::  ✗ Bad: Explicit zeros
=/  users  `(map @ud user)`~
=/  count  0
```

### Irregular for Common Patterns

```hoon
::  ✓ Good: Use irregular forms
[a b c]
(func arg)
=(x y)
name=value

::  ✗ Bad: Overly regular for simple things
:-  a
:-  b
c
```

 ### Recursion and wet gates

Standard-library traversals — `weld`, `turn`, `zing`, `skim`, `sort` — are
wet gates. A self-reference (`$` or `^$`) appearing inside their arguments is
mulled against a type that is still being computed, and the compiler reports
`fuse-loop` / `mint-loop`. The `^-` casts on the trap and on the inner gate
do **not** help: goal propagation does not survive a wet-gate mull.

Inside a recursive traversal, bind every recursive result to an explicitly
typed `=/` before passing it to a wet gate.

```hoon
::  ✗ Bad — fuse-loop
%+  weld  here
%-  zing
%+  turn  names
|=  name=@ta
^-  (list path)
^$(clay-path (snoc clay-path name))

::  ✓ Good
=/  children=(list path)
  |-  ^-  (list path)
  ?~  names  ~
  =/  head=(list path)  ^$(clay-path (snoc clay-path i.names))
  =/  rest=(list path)  $(names t.names)
  (weld head rest)
(weld here children)
```

This is the one place where the "prefer stdlib traversals over `|-`" rule in
the style guide's §5 is overridden. `turn`/`murn`/`levy`/`lien` remain
correct for any
traversal that is *not* self-recursive.

### Type narrowing and write-back

`?~`/`?^`/`?=` narrow the tested wing for the rest of the branch, and the
narrowing propagates to every enclosing structure — testing
`readiness.transient.state` narrows `state` itself. Any later `=.` or `=^`
that writes a *wider* value into `state` then fails:

```
nest-fail
-have.%~
- need  [%~ u [job=[…] failures=@ud retry-wire=/]]
```

The rule: **copy the slot into a local, test the copy.**

```hoon
::  ✗ Bad — narrows +state, so the later =^ cannot write it back
?~  readiness.transient.state  `this
=/  pending=pending-readiness:web  u.readiness.transient.state
…
=^  cards  state  (advance-readiness pending %.n state now.bowl our.bowl)

::  ✓ Good
=/  current=(unit pending-readiness:web)  readiness.transient.state
?~  current  `this
=/  pending=pending-readiness:web  u.current
…
=^  cards  state  (advance-readiness pending %.n state now.bowl our.bowl)
```

Do not paper over it with `^-(wide-type x)` re-binding tricks; copy-then-test
says what it means, and deserves a one-line comment.

Corollary: when an arm both clears a slot (`=.  active.transient.state  ~`)
and calls a handler that returns fresh state, **do not** write the result
back with `=^`. Bind it to `=/  next=(quip card app-state)` and return
`[… -.next]` / `+.next`. The clear is a write into the slot, and the
handler's product is wider than what the surrounding branch has narrowed the
 slot to.
