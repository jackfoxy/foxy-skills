# Commit Format, DCO & Java Style

## Commit message format
Below the description, above the `Signed-off-by`/`Co-authored-by` trailers, add bracketed tags:
- **Type:** `[Bug]`, `[Feature]`, `[Doc]`, `[Refactor]`
- **Component:** `[TLC]`, `[SANY]`, `[PCal]`, `[Toolbox]`, …
- **`[Changelog]`** for notable commits to surface in the release changelog.

```
Fix off-by-one in SubSeq enumeration

<body explaining what and why>

[Bug][TLC][Changelog]
Signed-off-by: Jane Dev <jane@example.com>
```

## DCO sign-off (required — Linux Foundation)
Every commit needs a Developer Certificate of Origin sign-off (distinct from GPG signing):
```bash
git commit -s -am "message"     # -s adds Signed-off-by
```
CI catches missing sign-off; GitHub provides instructions to add it retroactively.

## Java style (recommended, not enforced — DEVELOPING.md)
No strict formatting; **copy the style of nearby code** rather than restyle. For new files: javadoc on public classes/methods; don't mix tabs/spaces; opening `{` on the same line; braces even for single-statement bodies; lines ≤ 120 chars. Sources are UTF-8 and may contain math characters.

## Where to find work
- [Issues](https://github.com/tlaplus/tlaplus/issues), especially `help wanted` and `good first issue` labels.
- Larger ideas in `general/docs/contributions.md` (man-month-scale: concurrent SCC, liveness under symmetry, TLC error reporting 2.0, runtime API).
- Language-level proposals → [RFCs](https://github.com/tlaplus/rfcs/issues).
- Non-code: developer/user docs, SonarCloud quality fixes.
