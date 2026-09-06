# Diagnostic Codes

```hoon
+$  code-family  ?(%sany %pcal %tlc %lus)
+$  diag-code    [family=code-family num=@ud]
+$  diagnostic   [code severity stage message at=(unit loc) related]
```

Three of the four families are **the pin's own codes with the pin's own text**;
`%lus` is engine-specific. Diagnostics are ordered globally-first (`at=~`), then
by location, then family rank (`%sany` 0, `%pcal` 1, `%tlc` 2, `%lus` 3), then
number, then message — `desk/lib/diagnostics.hoon` `+diag-lte`.

`desk/tests/lib/mp.hoon` byte-matches `MP.getMessage` over 192 cases in both
`-tool` and plain modes, so a message you see here is the message the Java tool
prints.

## `%sany` — parse and semantic

SANY's `4.xxx` codes, e.g. `[%sany 4.200]` for a parse error and `[%sany
4.802]` for a semantic one. The parse-error block is reproduced byte-for-byte:

- the optional `Was expecting "…"` line (the grammar's `expecting` state);
- the JavaCC `Encountered "…" at line L, column C and token "…"` line,
  including the synthetic `Beginning of definition` token, `<EOF>`, and
  `add_escapes` escaping;
- the `Residual stack trace` of the top five production entries with their
  entry positions.

Also reproduced verbatim: `OperatorStack` messages (precedence conflict,
illegal combination, the mistyped-`==` hint, missing expression/operator,
postfix/prefix/infix encounter errors, `.`-reduction errors), `finalReduce`'s
`Couldn't properly parse expression` followed by ` Couldn't reduce expression
stack.`, junction-indent errors (`Item at <loc> is not properly indented …`),
`Removing label at <loc> would change expression parsing.`, `\X`-as-infix
rejection, `@ used in !.@`, and fairness-subscript failures.

Lexical errors pass through the byte-exact `TokenMgrError` text, wrapped as
`Lexical {error: EOF reached, possibly open comment starting around line N`
when the failing lexeme spans lines.

## `%tlc` — config, checking, evaluation

| Range | Meaning |
|---|---|
| `2.103`–`2.121` | run progress and completion messages |
| `2.107` / `2.108` | invariant / property violated **by an initial state** → `violation.initial=&` |
| `2.110` | invariant violated **by a behaviour** → `violation.initial=\|` |
| `2.112` | **implied action** violated → `[%violated [%action …]]` |
| `2.116` | temporal property violated by a behaviour |
| `2.189`–`2.221` | evaluation and runtime errors |
| `2.204` / `2.205` / `2.208` | DFID level lines and counts |
| `2.222`–`2.281` | `TLC_CONFIG_*` — config-vs-graph validation |
| `2.244` | decimal literal rejected at spec load |
| `2.404`, `2.405`, `2.772`–`2.775` | further message classes |

## `%lus` — engine-specific

Four codes, all with no analogue in the Java tool:

| Code | Severity | Stage | Meaning |
|---|---|---|---|
| `[%lus 400]` | error | `%parse` | `parser crashed in <module>` — a genuine port defect; report it |
| `[%lus 401]` | error | `%modules` | `module resolution failed` |
| `[%lus 402]` | warning | `%modules` | `source provenance omitted: it exceeds max-artifact` |
| `[%lus 403]` | warning | `%terminal` | `artifacts reclaimed: the agent-wide retention bound was reached` |

`403` is why an artifact scry can miss on a job that still exists: retention
took the artifact **body**, never the result.

## `CFG_*` — 5.001–5.006

Config-file parse errors, `desk/lib/config.hoon`. `ModelConfig.parse` throws on
the **first** malformed construct, so you get **at most one per file** — fix
them one at a time. `5.006` is the generic *"Expected a keyword"*.

## Promoting a warning to an error

`request.promote=(set diag-code)` is tlc2's `-messagesAsErrors`. It is
**verdict-affecting, not cosmetic**: promotion fires at the moment the
diagnostic is emitted, so a config-stage code aborts before any checking and a
mid-run code aborts mid-run, reporting the statistics reached so far.

**Only warnings are promotable** — tlc2's rule, not a port choice
(`isTlcMessageAsError` is consulted in `printWarning` and nowhere else).
Promoting an error or info code is inert on both sides. An unrecognised code is
inert here (tlc2 refuses it at argument parsing, which is CLI validation, not
the capability).
