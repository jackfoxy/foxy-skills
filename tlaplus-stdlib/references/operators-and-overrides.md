# StandardModules, Overrides & Operator Reference

## The two sides
- **TLA+ side:** `src/tla2sany/StandardModules/*.tla` — definitions SANY parses (and a proof would use): `TLC.tla`, `Sequences.tla`, `FiniteSets.tla`, `Naturals.tla`, `Integers.tla`, `Reals.tla`, `Bags.tla`, `TLCExt.tla`, `Randomization.tla`, `Json.tla`.
- **Java side:** `src/tlc2/module/<ModuleName>.java` — methods TLC invokes instead of evaluating the TLA+ body: `TLC.java`, `Sequences.java`, `FiniteSets.java`, `Naturals.java`, `Bags.java`, `Strings.java`, `TLCExt.java`, `Randomization.java`, `Json.java`, plus `AnySet`, `TransitiveClosure`, and annotation-based ones in `overrides/`.

## The override contract
1. **Same name, same arity.** TLA+ `Foo(a,b)` ↔ `public static Value Foo(Value a, Value b)` in `tlc2/module/<Module>.java`. Args/return are TLC `Value` types (`IntValue`, `BoolValue`, `SetEnumValue`, `FcnRcdValue`, …).
2. **Infix operators map via `TLARegistry`** in a `static { }` block, since infix symbols can't be Java method names. From `TLC.java`:
   ```java
   static {
     Assert.check(TLARegistry.put("MakeFcn", ":>") == null, EC.TLC_REGISTRY_INIT_ERROR, "MakeFcn");
     Assert.check(TLARegistry.put("CombineFcn", "@@") == null, EC.TLC_REGISTRY_INIT_ERROR, "CombineFcn");
   }
   ```
   and `Sequences.java`: `TLARegistry.put("Concat", "\\o")`. So `d :> e`→`MakeFcn`, `f @@ g`→`CombineFcn`, `s \o t`→`Concat`.
3. **Keep TLA+ and Java semantically equal** — the TLA+ body is the spec of behavior (used outside TLC, e.g. by TLAPS); the Java is the fast implementation.
4. **`overrides/`** offers `@TLAPlusOperator(identifier=..., module=...)` to register a method without editing a StandardModule's Java class.

## Notable TLC operators (`TLC.tla` / `TLC.java`)

| TLA+ | Meaning |
|------|---------|
| `Print(out,val)` / `PrintT(out)` | emit `out` while evaluating; return `val`/`TRUE` |
| `Assert(val,out)` | `val` if true else fail with `out` |
| `d :> e` | one-element function `[x \in {d} \|-> e]` (`MakeFcn`) |
| `f @@ g` | merge functions, `f` wins on overlap (`CombineFcn`) |
| `Permutations(S)` | set of all permutations of `S` |
| `SortSeq(s, Op(_,_))` | sort sequence `s` by comparator `Op` |
| `RandomElement(S)` | pseudo-random element of `S` (simulation) |
| `Any` | value with `v \in Any = TRUE` for all `v` |
| `ToString(v)` | TLA+ string form of `v` |
| `TLCEval(v)` | force full (non-lazy) evaluation |
| `TLCGet(i)`/`TLCSet(i,v)` | per-worker scratch list + state queries (`"distinct"`,`"queue"`,`"diameter"`,`"level"`,`"duration"`) |
