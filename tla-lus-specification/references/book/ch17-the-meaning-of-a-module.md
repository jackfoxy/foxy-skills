# Chapter 17 — The Meaning of a Module

Source: [SpecifyingSystems-21-07-04.pdf](~/eBooks/TLA+/SpecifyingSystems-21-07-04.pdf) (Leslie Lamport, *Specifying Systems*), pp. 317–338.

Chapter 16 gave the meaning of a *basic expression* (only built-in operators, declared constants/variables); this chapter defines the meaning of a whole **module** in terms of basic expressions — completing the semantics of `TLA⁺`. It also states the remaining **context-dependent** syntactic conditions omitted from Ch. 15 (illegal cases: `F(x)` for a 2-arg `F`, double-priming `(x'+1)'`, undeclared `x+1`, redefining `F`). Deliberately semi-formal, using examples in place of the fully rigorous definitions. Central technical devices: **arity/order**, **λ expressions**, **levels**, and **contexts**.

## 17.1 Operators and Expressions

Develops a uniform way to write every operator application as `Op(e₁,…,eₙ)`.

### 17.1.1 The Arity and Order of an Operator
Every operator has an **arity** and an **order**, in three classes:
- **0th-order** — an ordinary expression (takes no args); arity `_`.
- **1st-order** — takes expressions as args; arity `⟨_,…,_⟩`.
- **2nd-order** — args may be expressions *or* 1st-order operators; arity `⟨a₁,…,aₙ⟩` where each `aᵢ` is `_` or `⟨_,…,_⟩` (e.g. `G(f(_,_),x,y)` has arity `⟨⟨_,_⟩,_,_⟩`).
No 3rd-/higher-order operators (little use, harder level-checking). `TLA⁺` is still first-order logic (quantification only over 0th-order operators).

### 17.1.2 λ Expressions
A `TLA⁺` expression can equal only a 0th-order operator; to say what a 1st-/2nd-order operator *equals*, generalize to **λ expressions** (`λ x,y : x∪{z,y}`). Used only to *explain* semantics — **not writable in `TLA⁺`**. λ parameters are bound identifiers; renaming them (**α conversion**) preserves meaning; applying a λ expression (**β reduction**) substitutes args for parameters. The `n=0` case `λ : exp` is just `exp` (generalizing an ordinary expression).

### 17.1.3 Simplifying Operator Application
All the syntactic forms of application translate to `Op(e₁,…,eₙ)`:
- Fixed-arity constructs (infix `+`, `ENABLED`, `WF`, `f[e]`, `IF/THEN/ELSE`) → e.g. `+(a,b)`, `Apply(f,e)`, `IfThenElse(p,e₁,e₂)`.
- Variable-arity constructs (`{e₁,…,eₙ}`, records) → repeated fixed-arity operators (`{e}=Singleton(e)`, `[h↦e]=Record("h",e)`, `@@`); `CASE` reduces to two-arm `CASE`.
- Bound-variable constructs → 2nd-order operators over λ expressions (`∃x∈S:x+z>y` = `ExistsIn(S, λ x:x+z>y)`); the `S` moves outside the bound scope.
- Instantiation applications `M(x)!Op(y,z)` → `M!Op(x,y,z)`.
- `LET` deferred to §17.4; only LET-free λ expressions considered here.
"Identifier" now includes operator symbols like `+`.

### 17.1.4 Expressions
Inductive definition: an expression is a 0th-order operator, or `Op(e₁,…,eₙ)` with `Op` an operator (not a λ expression) and each `eᵢ` an expression or 1st-order operator, and it must be **arity-correct**. So a λ expression appears in an expression only as an argument of a 2nd-order operator (only 1st-order λ expressions can appear). λ parameter identifiers can't clash with meaningful identifiers.

## 17.2 Levels

Restrictions inherited from TLA logic with no counterpart in ordinary math (e.g. double-priming `(x'+y)'` forbidden — `'` applies only to state functions). Four **levels**:
- **0 constant** — only constants/constant operators (`c+3`).
- **1 state** — may add unprimed variables (`x+2*c`).
- **2 transition** — anything but temporal operators (`x'+y>c`).
- **3 temporal** — any TLA operator (`□[x'>y+c]_⟨x,y⟩`).
An expression's meaning depends on its level (state-level = mapping states→constants, transition-level = steps→constants, temporal-level = behaviors→constants). Level-correctness is defined by inductive rules (`e'` level-correct with level 2 iff `e` has level ≤1; `ENABLED e` level 1 iff `e` level ≤2; `∃x:e` (constant `x`) keeps `e`'s level; `∃x:e` (variable `x`, hiding) has level 3 iff `e` has level ≠2). **Level-correctness doesn't depend on the levels of declared identifiers.** Levels generalize to operators (a rule) and to λ expressions; the fully general definition is complex but unnecessary to know. **Constant levels**: expressions from constant-level operators + declared constants have constant level.

## 17.3 Contexts

Syntactic correctness and meaning of a basic expression depend on the declared identifiers' **arities and levels**, supplied by the **context** it appears in. Built-in operators are treated like declared/defined ones (standard context specifies all built-ins). Definitions:
- A **declaration** assigns an arity + level to a name.
- A **definition** assigns a LET-free λ expression to a name.
- A **module definition** assigns a module's meaning to a module name.
A **context** = set of declarations, definitions, module definitions satisfying: **C1** each operator name declared or defined at most once; **C2** no declared/defined name is a λ parameter identifier; **C3** every operator name in a definition's expression is a λ parameter or is *declared* (not defined) in the context; **C4** no module name gets two definitions. (Module and operator names are handled separately — the same string can be both.) A **𝒞-basic λ expression** contains only symbols declared in 𝒞 (plus λ parameters) and is arity-/level-correct. A special definition `Op ≜ ?` marks a name as illegal to use.

## 17.4 The Meaning of a λ Expression

Defines `𝒞⟦e⟧` — the meaning of λ expression `e` in context 𝒞 — as a 𝒞-basic λ expression, obtained by replacing all *defined* operator names with their definitions and applying **β reduction**. Inductive rules cover: an operator symbol (→ itself if declared, or its λ definition if defined); `Op(e₁,…,eₙ)` with `Op` declared (→ `Op(𝒞⟦e₁⟧,…)`) or defined (→ β reduction of `d̄(…)` with α conversion); a λ expression (→ extend 𝒞 with parameter declarations); a `LET`-with-INSTANCE. The last rules **define the meaning of `LET`** (the one operator Ch. 16 didn't cover):
- `Op(p₁,…,pₙ) ≜ d` in a LET means `Op ≜ λp₁,…,pₙ:d`.
- `Op[x∈S] ≜ d` means `Op ≜ CHOOSE Op : Op=[x∈S↦d]`.
- `LET Op₁≜d₁ … Opₙ≜dₙ IN exp` = nested single-definition LETs.
`e` is **legal** in 𝒞 iff these rules make `𝒞⟦e⟧` a legal 𝒞-basic expression.

## 17.5 The Meaning of a Module

A module's meaning in a context 𝒞 consists of **six sets**:
- **Dcl** declarations (`CONSTANT`/`VARIABLE`, extended modules)
- **GDef** global (non-LOCAL) definitions (+ from extended/instantiated modules)
- **LDef** local definitions (`LOCAL`; not exported)
- **MDef** module definitions (submodules, extended modules)
- **Ass** assumptions (`ASSUME`, extended modules)
- **Thm** theorems (`THEOREM`, extended, and instantiated modules' assumptions/theorems).
Computed by an **algorithm** processing statements top-to-bottom; the **current context** `CC = 𝒞 ∪ Dcl ∪ GDef ∪ LDef ∪ MDef`; α conversion keeps λ parameters clash-free.

### 17.5.1 Extends
`EXTENDS M₁,…,Mₙ` (must be first) unions the `Mᵢ`'s Dcl/GDef/MDef/Ass/Thm. Legal iff the `Mᵢ` are defined in 𝒞 and no symbol gets two meanings — **except** duplicates reached via chains of EXTENDS from the *same* original definition are allowed (so `EXTENDS Naturals, M₁, M₂` can be legal when all define `+` via `Naturals`). Shared declared constants/variables go in a common module `P` extended by all.

### 17.5.2 Declarations
`CONSTANT c₁,…,cₙ` / `VARIABLE v₁,…,vₙ` add to Dcl; legal iff none already declared/defined in CC.

### 17.5.3 Operator Definitions
`Op ≜ exp` or `Op(p₁,…,pₙ) ≜ exp`; legal iff `Op` not already in CC and the λ expression legal in CC; adds `CC⟦λp₁,…,pₙ:exp⟧` to GDef (LOCAL → LDef).

### 17.5.4 Function Definitions
`Op[fcnargs] ≜ exp` ≡ `Op ≜ CHOOSE Op : Op=[fcnargs↦exp]` (recursive), added to GDef (LOCAL → LDef).

### 17.5.5 Instantiation
`I(p₁,…,pₘ) ≜ INSTANCE N WITH q₁←e₁,…,qₙ←eₙ`, where the `qᵢ` are all of `N`'s declared identifiers (omitted ones default `Op←Op`). For each `N`-definition `Op ≜ λr₁,…,rₚ:e`, add `I!Op ≜ λp₁,…,pₘ,r₁,…,rₚ:ē` to GDef (`ē` = `e` with `eᵢ` substituted for `qᵢ`, per §17.8), and add `I ≜ ?`. Each `N`-theorem `T` yields `Ā₁∧…∧Āₖ ⇒ T̄` in Thm. **Level condition**: if `N` is a *nonconstant* module, a constant `qᵢ` needs `𝒟⟦eᵢ⟧` constant-level, and a variable `qᵢ` needs level ≤1 (can't substitute a nonconstant for a constant, nor a transition for a variable). Forms without `I!` prefix, and LOCAL instantiation (→ LDef), also covered; instantiating a declaration-free module (like `Naturals`) multiple times via chains is allowed.

### 17.5.6 Theorems and Assumptions
`THEOREM exp` adds `CC⟦exp⟧` to Thm (named form `THEOREM Op ≜ exp` = definition + theorem). `ASSUME exp` (exp must be **constant-level**) adds `CC⟦exp⟧` to Ass.

### 17.5.7 Submodules
A `MODULE N … ` submodule is legal iff `N` not defined in CC and the module is legal in CC; adds `N`'s meaning to MDef. Usable in a later `INSTANCE`; a submodule of `M` is *not* exported to a module that instantiates `M`.

## 17.6 Correctness of a Module

Mathematically, a module's meaning is the assertion that every theorem in **Thm** follows from the conjunction `A` of all assumptions in **Ass**: for each `T∈Thm`, the formula `A ⇒ T` is valid (in context Dcl). A module is **semantically correct** iff each such `A ⇒ T` is a valid formula. This completes the semantics: any meaningful question about a spec is whether some formula is a valid theorem.

## 17.7 Finding Modules

To interpret module `M`, a tool needs the meanings of all modules `M` extends/instantiates. Starting from a context `𝒞₀` of only built-ins, when it meets `EXTENDS`/`INSTANCE` of an undefined `N`, it finds `N` (most likely in a file `N.tla`), interprets it in `𝒞₀`, and adds it. A module is **syntactically incorrect** if the set of modules it (transitively) depends on includes itself.

## 17.8 The Semantics of Instantiation

Defines precisely how substitution `ē` (from §17.5.5) is performed, and the level rule, so **substitution preserves validity** (a valid formula in `N` becomes a valid `I!F` in `M`).
- **Level rule motive**: substituting a variable `x` for a constant `c` in `F ≜ □[c'=c]_c` would give invalid `□[x'=x]_x` — so nonconstants can't replace constants in a nonconstant module.
- **Variable capture** (ordinary math): naively substituting `m+1` for `n` in `(n∈Nat)⇒(∃m∈Nat:m≥n)` captures `m`; α conversion prevents it. §17.5.5's meaning avoids this because the capturing subexpression would be syntactically illegal (a bound `m` can't be reused).
- **Implicit binding** in `ENABLED A`, `A·B`, `F⇉G`: the primed (and, for `·`/`⇉`, some unprimed) variables are *implicitly bound*, so naive substitution breaks validity (worked `ENABLED (x'=0∧y'=1)` = TRUE becoming `ENABLED (z'=0∧z'=1)` = FALSE). Instantiation **distributes** over constant operators, `'`, `□`, etc., but **not** over `ENABLED`, `WF`, `SF`, `·`, `⇉`.
- **Algorithm for `ē`**: (1) replace each `F⇉G` by its explicit-quantifier equivalent (17.8); (2) recursively, for each declared variable `x` of `N`, replace primed `x` inside `ENABLED A` (and primed-in-`B`/unprimed-in-`C` for `B·C`) with a fresh symbol `$x` bound by the operator; (3) replace each `qᵢ` with `eᵢ`. Worked nested `ENABLED`/`·` example shown.

---
*Next: Chapter 18 — The Standard Modules.*
