---
name: generators
description: Master Hoon generators including naked generators (simple values), %say generators (with arguments), and %ask generators (interactive prompts). Use when creating command-line tools, scripts, one-off computations, testing utilities, or accessing system state via scries.
user-invocable: true
disable-model-invocation: false
validated: safe
checked-by: ~sarlev-sarsen
---

# Generators Skill

Master Hoon generators including naked generators, %say generators, %ask generators, and their use cases. Use when creating command-line tools, scripts, one-off computations, or testing utilities.

## Overview

Generators are Hoon programs that produce a value and exit. They're simpler than Gall agents, perfect for CLI tools, data processing, and testing.

> **IMPORTANT**: Generators are pure computations. They cannot make HTTP requests, send pokes, produce Gall cards, or cause side effects. For operations requiring effects (network requests, pokes, subscriptions), use threads (spider) or Gall agents.

## Learning Objectives

1. Understand generator types and use cases
2. Write naked generators for simple tasks
3. Build %say generators with arguments
4. Create interactive %ask generators
5. Access the system with scries
6. Build testing and utility generators

## 1. Generator Types

### Naked Generator

Simplest form - just returns a value:
```hoon
::  /gen/hello.hoon
'Hello, World!'
```

**Usage**: `+hello` in dojo

### `%say` Generator

Takes arguments and returns tagged value:
```hoon
::  /gen/add.hoon
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] [a=@ud b=@ud ~] ~]
:-  %noun
(add a b)
```

**Usage**: `+add 5 10` → `15`

### `%ask` Generator

Interactive, prompts for input:
```hoon
::  /gen/greet.hoon
:-  %ask
|=  *
^-  (unit @t)
%-  print
%-  crip
%-  weld  "What's your name? "
%-  trip
scan
```

**Usage**: `+greet` → prompts for input

## 2. Naked Generators

### Basic Example

```hoon
::  /gen/add-two.hoon
::
::  Simple computation (naked generators have no bowl access)
::
(add 2 2)
```

> **Note**: Naked generators do not have access to the bowl (no `now`, `eny`, `bec`). They can only perform pure computations or scries. Use a `%say` generator if you need system data like the current time.

### With Computation

```hoon
::  /gen/fibonacci.hoon
::
::  Generate first 10 Fibonacci numbers
::
=/  count  10
=/  a  0
=/  b  1
=/  result  *(list @ud)
|-
?:  =(count 0)
  (flop result)
=/  next  (add a b)
$(count (dec count), a b, b next, result [a result])
```

### Using Scries

```hoon
::  /gen/list-apps.hoon
::
::  List all Gall apps
::
.^(arch %cy /===/app)
```

## 3. %say Generators

### Structure

```hoon
:-  %say
|=  $:  [now=@da eny=@uvJ bec=beak]
        [required-args]
        [optional-args]
    ==
:-  %output-mark
computation
```

### Components

- `now`: Current time
- `eny`: Entropy (randomness)
- `bec`: Beak (ship, desk, case)
- `required-args`: Unnamed required arguments
- `optional-args`: Named optional arguments
- `output-mark`: Type of output (%noun, %json, %txt, etc.)

### Examples

#### Simple Args

```hoon
::  /gen/greet.hoon
::
::  Greet a person
::
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] [name=@t ~] ~]
:-  %noun
(cat 3 'Hello, ' name)
```

**Usage**: `+greet 'Alice'` → `'Hello, Alice'`

#### Multiple Required Args

```hoon
::  /gen/multiply.hoon
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] [a=@ud b=@ud ~] ~]
:-  %noun
(mul a b)
```

**Usage**: `+multiply 5 10` → `50`

#### Optional Args

Optional arguments use bunt (default) values, not units. When the user omits an optional argument, it receives its type's default value (e.g., `0` for `@ud`, `''` for `@t`).

```hoon
::  /gen/power.hoon
:-  %say
|=  $:  [now=@da eny=@uvJ bec=beak]
        [base=@ud ~]
        [exp=@ud ~]
    ==
:-  %noun
::  exp defaults to 0 (bunt of @ud) when omitted
::  Use a sentinel check or provide a sensible default
=/  exponent  ?:(=(exp 0) 2 exp)
(pow base exponent)
```

**Usage**:
- `+power 5` → `25` (exp defaults to bunt 0, treated as 2)
- `+power 5, =exp 3` → `125`

> **Note**: Optional args are NOT units. Do not use the `?~(exp default u.exp)` pattern -- `exp` is a bare `@ud`, not a `(unit @ud)`. The third tuple in the `%say` gate sample holds optional arguments that receive their type's bunt value when omitted.

#### Using System Data

```hoon
::  /gen/ship-info.hoon
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] ~ ~]
:-  %noun
:*  our=p.bec
    desk=q.bec
    time=now
    random=eny
==
```

### Output Marks

```hoon
::  JSON output
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] [data=@t ~] ~]
:-  %json
%-  pairs:enjs:format
~[['data' s+data] ['timestamp' (sect:enjs:format now)]]

::  Text output
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] ~ ~]
:-  %txt
%-  crip
%-  weld  "Current time: "
(scow %da now)
```

## 4. %ask Generators

> **WARNING**: `%ask` generators are poorly documented and rarely used in practice. The `readline`/`print` API shown below may not match actual Urbit implementations and varies across runtime versions. The examples here are illustrative of the intended pattern but may not compile as-is. Prefer `%say` generators for most use cases. If you need interactive input, consider using a Gall agent with a front-end instead.

### Interactive Input (Illustrative)

```hoon
:-  %ask
|=  *
^-  (unit [@t @ud])
%-  print
%-  crip
(weld "Enter name: " ~)
=/  name  (scan (trip readline) (star prn))
%-  print
%-  crip
(weld "Enter age: " ~)
=/  age  (scan (trip readline) dem)
`[(crip name) age]
```

### Multi-Step Wizard (Illustrative)

```hoon
:-  %ask
|=  *
^-  (unit config)
%-  print  "=== Configuration Wizard ==="
%-  print  "Server address:"
=/  server  (trip readline)
%-  print  "Port:"
=/  port  (scan (trip readline) dem)
%-  print  "Use SSL? (y/n):"
=/  ssl  =((trip readline) "y")
`[server=(crip server) port=port ssl=ssl]
```

## 5. Common Patterns

### Pattern 1: Data Processing

```hoon
::  /gen/process-csv.hoon
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] [file=@t ~] ~]
:-  %noun
=/  content  .^(@t %cx /(scot %p p.bec)/[q.bec]/(scot r.bec)/[file])
=/  lines  (split-on '\n' (trip content))
%+  turn  lines
|=(line=tape (split-on ',' line))
```

### Pattern 2: Testing Utility

```hoon
::  /gen/test-json.hoon
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] ~ ~]
:-  %noun
=/  test-data
  :*  name='Alice'
      age=30
      active=%.y
  ==
=/  json  (to-json test-data)
=/  back  (from-json json)
=(test-data back)
```

### Pattern 3: Batch Data Generation

> **Note**: Generators cannot produce Gall cards or effects. They are pure computations. For operations requiring pokes, subscriptions, or other side effects, use threads (spider) or Gall agents.

```hoon
::  /gen/batch-data.hoon
::  Generate a list of test data entries
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] [count=@ud ~] ~]
:-  %noun
=/  result  *(list [@ud @t])
=/  idx  0
|-
?:  =(idx count)
  (flop result)
$(idx +(idx), result [[idx (scot %ud idx)] result])
```

### Pattern 4: System Query

```hoon
::  /gen/app-state.hoon
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] [app=@tas ~] ~]
:-  %noun
.^(vase %gx /(scot %p p.bec)/[app]/(scot %da now)/dbug/state/noun)
```

### Pattern 5: Random Generation

```hoon
::  /gen/random-list.hoon
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] [len=@ud ~] ~]
:-  %noun
=/  rng  ~(. og eny)
=/  result  *(list @ud)
|-
?:  =(len 0)
  result
=^  val  rng  (rads:rng 100)
$(len (dec len), result [val result])
```

## 6. Advanced Generators

### File Processing

```hoon
::  /gen/read-and-process.hoon
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] [path=path ~] ~]
:-  %json
=/  file-path  /(scot %p p.bec)/[q.bec]/(scot %da now)/[path]
=/  content  .^(@t %cx file-path)
=/  processed  (process-content content)
(result-to-json processed)
```

### Scrying Agent State

> **Note**: Generators cannot make HTTP requests or produce side effects. They are pure computations. For HTTP requests, use threads (spider) or Gall agents via Iris. Generators can, however, scry into agent state.

```hoon
::  /gen/check-agent.hoon
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] [app=@tas ~] ~]
:-  %noun
.^(vase %gx /(scot %p p.bec)/[app]/(scot %da now)/dbug/state/noun)
```

### State Migration Helper

```hoon
::  /gen/migrate-state.hoon
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] [app=@tas ~] ~]
:-  %noun
=/  old-state  .^(vase %gx /(scot %p p.bec)/[app]/(scot %da now)/state/noun)
=/  old  !<(state-v0 old-state)
=/  new  (migrate-v0-to-v1 old)
!>(new)
```

## 7. Debugging Generators

### Debugging Tips

```hoon
::  Use ~& for debug output
~/  debug-gen
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] [input=@ud ~] ~]
:-  %noun
~&  >  input
~&  >>  "Processing..."
=/  result  (complex-computation input)
~&  >  result
result
```

### Error Handling

```hoon
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] [data=@t ~] ~]
:-  %noun
=/  result
  %-  mule  |.
  (risky-operation data)
?-  -.result
  %&  p.result
  %|  ~&  >>>  "Error: {<p.result>}"  !!
==
```

## 8. Testing with Generators

### Unit Test Generator

```hoon
::  /gen/test-utils.hoon
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] ~ ~]
:-  %noun
=/  tests
  :~  ['add' .=(5 (add 2 3))]
      ['mul' .=(20 (mul 4 5))]
      ['sub' .=(3 (sub 10 7))]
  ==
%+  turn  tests
|=([name=@t result=?] [name result])
```

### Property Testing

```hoon
::  /gen/prop-test.hoon
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] [iterations=@ud ~] ~]
:-  %noun
=/  rng  ~(. og eny)
=/  passed  0
=/  failed  0
|-
?:  =(iterations 0)
  [passed=passed failed=failed]
=^  val  rng  (rads:rng 1.000)
=/  property  (test-property val)
?:  property
  $(iterations (dec iterations), passed +(passed))
$(iterations (dec iterations), failed +(failed))
```

## 9. Utility Generators

### Data Conversion

```hoon
::  /gen/json-to-noun.hoon
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] [json-text=@t ~] ~]
:-  %noun
=/  parsed  (de-json:html json-text)
?~  parsed  !!
u.parsed
```

### Performance Benchmark

```hoon
::  /gen/benchmark.hoon
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] [iterations=@ud ~] ~]
:-  %noun
=/  start  now
=/  count  iterations
|-
?:  =(count 0)
  (sub now start)
=/  _  (heavy-computation)
$(count (dec count))
```

## 10. Best Practices

### 1. Document Arguments

```hoon
::  /gen/example.hoon
::
::  Example generator
::
::  Arguments:
::    input: Text to process
::    count: Number of repetitions (optional, default 1)
::
::  Usage:
::    +example 'hello'
::    +example 'hello', =count 3
::
:-  %say
|=  $:  [now=@da eny=@uvJ bec=beak]
        [input=@t ~]
        [count=@ud ~]
    ==
...
```

### 2. Validate Input

```hoon
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] [n=@ud ~] ~]
:-  %noun
?>  (gth n 0)
?>  (lte n 1.000)
(process n)
```

### 3. Use Meaningful Output

```hoon
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] ~ ~]
:-  %noun
:*  timestamp=now
    ship=p.bec
    desk=q.bec
    result=(computation)
==
```

### 4. Handle Errors Gracefully

```hoon
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] [file=path ~] ~]
:-  %noun
=/  result
  %-  mule  |.
  .^(@t %cx /(scot %p p.bec)/[q.bec]/(scot %da now)/[file])
?-  -.result
  %&  `p.result
  %|  ~
==
```

## Resources

- [Generator Guide](https://developers.urbit.org/guides/core/hoon-school/K-doors) - Generators tutorial
- [Generator Examples](https://github.com/urbit/urbit/tree/master/pkg/arvo/gen) - Built-in generators
- [Dojo Guide](https://developers.urbit.org/guides/core/environment#dojo) - Using generators

## Summary

Generators:
1. **Naked** - Simple computations, no arguments
2. **%say** - Arguments, system access, return typed value
3. **%ask** - Interactive input prompts
4. **Use cases** - CLI tools, testing, data processing, utilities
5. **Best practices** - Document, validate, handle errors
6. **System access** - Scries, random numbers, timestamps

Generators are perfect for one-off computations, testing utilities, and command-line tools in Urbit.
