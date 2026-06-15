# StandardModules and Overrides

Core paths:

- `tlatools/org.lamport.tlatools/src/tla2sany/StandardModules/*.tla`
- `tlatools/org.lamport.tlatools/src/tlc2/module/*.java`
- `general/docs/current-tools.md`

## Structure

Many standard modules are pairs:

| TLA+ module | Java override |
|---|---|
| `StandardModules/TLC.tla` | `tlc2/module/TLC.java` |
| `StandardModules/Naturals.tla` | `tlc2/module/Naturals.java` |
| `StandardModules/Integers.tla` | `tlc2/module/Integers.java` |
| `StandardModules/Sequences.tla` | `tlc2/module/Sequences.java` |
| `StandardModules/FiniteSets.tla` | `tlc2/module/FiniteSets.java` |
| `StandardModules/Bags.tla` | `tlc2/module/Bags.java` |
| `StandardModules/TLCExt.tla` | `tlc2/module/TLCExt.java` |
| `StandardModules/Randomization.tla` | `tlc2/module/Randomization.java` |
| `StandardModules/Json.tla` | `tlc2/module/Json.java` |

The TLA+ definitions are often valid stubs. TLC may replace them at runtime with Java implementations.

Standard module files include `TLC.tla`, `TLCExt.tla`, `Sequences.tla`, `FiniteSets.tla`, `Naturals.tla`, `Integers.tla`, `Bags.tla`, `Json.tla`, `Randomization.tla`, and trace helper modules.

Java override files include `TLC.java`, `TLCGetSet.java`, `TLCEval.java`, `Sequences.java`, `FiniteSets.java`, `Naturals.java`, `Integers.java`, `Bags.java`, `Randomization.java`, `Json.java`, and trace helpers.

## Override Contract

- Match TLA+ operator behavior and Java override signatures exactly.
- Java method name usually equals the TLA+ operator name, case-sensitive.
- Java override methods are generally `public static` and use `tlc2.value` `Value`/`IValue` types.
- Return type is generally `Value`.
- Higher-order operators may pass `ValueVec` or `OpValue`.
- Module/class correspondence matters: `TLC.tla` maps to `tlc2.module.TLC`.
- For symbolic/infix operators, check registration in `TLARegistry`.
- Test both direct operator behavior and model-checking behavior.
- Keep TLA+ definitions readable even when TLC overrides them.
- Consult `current-tools.md` for operators with behavior that differs from the book.

Example infix registration pattern:

```java
Assert.check(TLARegistry.put("MakeFcn", ":>") == null, EC.TLC_REGISTRY_INIT_ERROR, "MakeFcn");
Assert.check(TLARegistry.put("CombineFcn", "@@") == null, EC.TLC_REGISTRY_INIT_ERROR, "CombineFcn");
```

## Key TLC Operators

| TLA+ operator | Java method | Purpose |
|---|---|---|
| `Print(out, val)` | `Print` | print and return `val` |
| `PrintT(out)` | `PrintT` | print and return `TRUE` |
| `Assert(val, out)` | `Assert` | halt if `val` is false |
| `TLCGet(i)` | `TLCGetValue` | read TLC slot or named key |
| `TLCSet(i, v)` | `TLCSetValue` | write TLC slot |
| `TLCEval(v)` | `TLCEval` | force eager evaluation |
| `JavaTime` | `JavaTime` | current wall-clock time |
| `ToString(v)` | `ToString` | TLA+ string representation |
| `RandomElement(s)` | `RandomElement` | pseudo-random set element |
| `SortSeq(s, Op)` | `SortSeq` | sort sequence with comparator |
| `Permutations(S)` | `Permutations` | permutations of a finite set |
| `d :> e` | `MakeFcn` | single-entry function |
| `f @@ g` | `CombineFcn` | function merge |

## TLCGet Named Keys

```tla
TLCGet("generated")
TLCGet("distinct")
TLCGet("queue")
TLCGet("diameter")
TLCGet("duration")
TLCGet("level")
```

Numeric slots are per-worker after initialization. Initialize in `ASSUME` or `Init` when the value must be visible to all workers.

## Adding an Override

1. Add or update the TLA+ stub in `StandardModules/<Module>.tla`.

```tla
MyOp(x) == CHOOSE v : TRUE
```

2. Add the Java implementation in the matching `tlc2/module/<Module>.java`.

```java
public static Value MyOp(Value x) {
    return result;
}
```

3. For infix/symbolic operators, add a `TLARegistry.put` entry.
4. Add Java tests and a small `.tla`/`.cfg` fixture if model-checking behavior matters.
5. Run targeted tests:

```bash
cd /mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools
ant -f customBuild.xml compile compile-test dist
ant -f customBuild.xml test-set -Dtest.testcases="tlc2/module/*"
```

## Override Mismatch Errors

Check these in `EC.java` / `MP.java`:

- `TLC_MODULE_VALUE_JAVA_METHOD_OVERRIDE_MISMATCH`
- `TLC_MODULE_VALUE_JAVA_METHOD_OVERRIDE_MODULE_MISMATCH`
- `TLC_MODULE_VALUE_JAVA_METHOD_OVERRIDE_IDENTIFIER_MISMATCH`

Fix method name, class/module name, arity/signature, or `TLARegistry` registration.

## Notable Modules

- `Reals.tla`: real arithmetic surface; TLC support may be limited.
- `RealTime.tla`: real-time constraints.
- `Json.tla` / `Json.java`: JSON handling.
- Trace helper modules such as `_JsonTrace.tla`, `_TLCTrace.tla`, `_Possible.tla` are internal support surfaces; inspect before modifying.
