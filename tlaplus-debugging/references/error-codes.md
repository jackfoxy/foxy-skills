# TLC / SANY Error-Code Taxonomy

Source: `tlatools/org.lamport.tlatools/src/tlc2/output/EC.java` (236 codes) + `MP.java` (message text). Diagnose by the code **range**.

| Range | Category | Typical meaning |
|-------|----------|-----------------|
| `1000`–`1005` | GENERAL / SYSTEM | `GENERAL`(1000), `SYSTEM_OUT_OF_MEMORY`(1001), `_TOO_MANY_INIT`(1002), `_LIVENESS`(1003), `SYSTEM_STACK_OVERFLOW`(1005) |
| `1101`–`1102` | command-line | `WRONG_COMMANDLINE_PARAMS_SIMULATOR`(1101) / `_TLC`(1102) |
| `2000`–`2001` | value parse/format | `TLC_PP_PARSING_VALUE`, `TLC_PP_FORMATING_VALUE` |
| `2100`–`2299` | **TLC runtime / checking** | metadir, init-state, assumptions, invariant/property violations, deadlock, liveness, module-arg, features-unsupported (see key codes below) |
| `3000`–`3001` | check driver | `CHECK_FAILED_TO_CHECK`, `CHECK_COULD_NOT_READ_TRACE` |
| `3100`–`3114` | TLC parameter errors | bad/missing `-config`, `-workers`, `-depth`, `-coverage`; unrecognized flag; too many input files |
| `4000`–`4002` | **SANY parser** | `SANY_PARSER_CHECK_1`(lexical) / `_2`(syntactic) / `_3`(semantic+level) |
| `5001`–`50xx` | **`.cfg` config file** | `CFG_ERROR_READING_FILE`, `CFG_GENERAL`, `CFG_MISSING_ID`, `CFG_TWICE_KEYWORD`, `CFG_EXPECT_ID`, `CFG_EXPECTED_SYMBOL` |

## Key 2xxx checking codes
- `TLC_ASSUMPTION_FALSE` 2104 — an `ASSUME` evaluated FALSE.
- `TLC_STATE_NOT_COMPLETELY_SPECIFIED_INITIAL` 2106 / `_NEXT` 2109 — a variable lacks a value in `Init`/an action.
- `TLC_INVARIANT_VIOLATED_INITIAL` 2107 / `_BEHAVIOR` 2110 — invariant false in an initial / reachable state.
- `TLC_INVARIANT_EVALUATION_FAILED` 2111.
- `TLC_ACTION_PROPERTY_VIOLATED_BEHAVIOR` 2112 — action property violated.
- `TLC_DEADLOCK_REACHED` 2114 — a reachable state has no successor.
- `TLC_TEMPORAL_PROPERTY_VIOLATED` 2116 — liveness violation (often a lasso; `TLC_BACK_TO_STATE` 2122).
- `TLC_NO_STATES_SATISFYING_INIT` 2118 / `_AND_CONSTRAINT` 2256.
- `TLC_FEATURE_UNSUPPORTED_LIVENESS_SYMMETRY` 2279 — `SYMMETRY` with liveness (unsound).
- `TLC_LIVE_*` 2212–2259 — liveness-formula handling issues (non-bool predicate, can't handle formula, tautology, state-level fairness, no fairness but live property, etc.).

Run `tla2sany.SANY -error-codes` (CI uses this) for machine-readable codes.
