---
name: tlaplus-contribution
description: Follow the tlaplus/tlaplus contribution conventions - engage maintainers early, make surgical diffs, write tests first, split PRs, use commit categorization tags and DCO sign-off. Use before any edit or PR, when authoring tests/docs, or crafting commit messages for this repo. For the mechanics of building/running tests see tlaplus-build-workflow.
user-invocable: true
disable-model-invocation: false
---

# Contributing to tlaplus/tlaplus

TL;DR (from `CONTRIBUTING.md`): **engage maintainers early & often, be surgical, write lots of tests.** TLA+ validates safety-critical systems, so quality gates are strict — a large surprise PR is *very unlikely to be merged*. Build/test commands: [[tlaplus-build-workflow]].

## Process
1. **Engage first.** Comment on an existing issue or open one before coding; join the [monthly meeting](https://groups.google.com/g/tlaplus/c/CpAEnrf-DHQ/m/YrORpIfSBwAJ) / [mailing list](https://groups.google.com/g/tlaplus) for substantial work. Agree on scope, touched code, and required tests.
2. **Fork → branch → PR against upstream `master`.** (Run CI on your own by PRing within your fork.)
3. **Write tests first.** Good existing coverage of the changed area is a **prerequisite to merge**; prefer submitting tests as a separate PR so they land immediately.
4. **Be surgical.** Smallest diff that does the job; don't restyle unrelated code (keeps diffs reviewable/bisectable).
5. **Split changes.** Several small PRs > one large PR.
6. **Craft commits.** Treat commits as communication; ideally build & tests pass on every commit (amend rather than pile up check-ins — git tips in `DEVELOPING.md`).

## Commits & sign-off (essentials)
Tag commits `[Type][Component]` (e.g. `[Bug][TLC]`, add `[Changelog]` if notable) and **always sign off**:
```bash
git commit -s -am "message"     # -s = DCO Signed-off-by (required; CI enforces)
```
Full tag list, an example message, the DCO rationale, Java style guidance, and where-to-find-work are in `references/commits-and-style.md`.

## Minimal acceptable PR (review checklist)
1. Linked issue with maintainer agreement.
2. Small, focused diff; nearby style matched.
3. New/updated unit test (or `test-model/` spec+`.cfg`) covering the change — ideally a tests-first PR.
4. `ant ... compile compile-test dist test` passes ([[tlaplus-build-workflow]]).
5. Commit with `[Type][Component]` tags + `-s` DCO sign-off.

## Validation
For a proposed change: name the issue to engage, the smallest diff, the test to add first, the commit tags, and confirm `-s` is present — before opening the PR.

## References (local)
- `references/commits-and-style.md` — commit tags, DCO, Java style, where to find work
- `CONTRIBUTING.md`, `DEVELOPING.md` (git + style sections), `general/docs/contributions.md`, `.github/CODE_OF_CONDUCT.md`
