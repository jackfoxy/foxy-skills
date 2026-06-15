# Contribution Workflow

Primary sources: `CONTRIBUTING.md`, `DEVELOPING.md`, `general/docs/contributions.md`, `.github/CODE_OF_CONDUCT.md`.

Core rule: engage maintainers early, keep diffs surgical, write tests first.

## Engage Before Code

1. Find an existing issue or open a new one.
2. Comment with proposed scope and approach.
3. For substantial changes, use the monthly community meeting link in `CONTRIBUTING.md`.
4. Agree on touched components and required tests before large implementation work.

Entry points:

- `help wanted` issues
- `good first issue` labels
- `general/docs/contributions.md` for larger ideas
- `https://github.com/tlaplus/rfcs/issues` for language-level proposals

## Multi-Remote Git Setup

```bash
git clone git@github.com:<you>/tlaplus.git
cd tlaplus
git remote add upstream git@github.com:tlaplus/tlaplus.git
git remote rename origin user
git checkout master
git pull upstream master
git checkout -b fix/tlc-invariant-level-check
```

Use names that make branch purpose clear.

## Tests First

- Add or strengthen tests before changing behavior when practical.
- For TLC behavior, expect Java tests plus `.tla`/`.cfg` fixtures under `test-model/` where appropriate.
- For parser work, use parser corpus/XML/semantic tests.
- Tests that provide independent value can be split into a separate PR.

Targeted test pattern:

```bash
cd tlatools/org.lamport.tlatools
ant -f customBuild.xml test-set -Dtest.testcases="your/TestClass*"
```

## Surgical Diff Rules

- Make the smallest diff that solves the task.
- Do not reformat unrelated code.
- Match nearby style.
- Keep commits as logical review units.
- Split unrelated improvements into separate PRs.

Useful cleanup commands:

```bash
git rebase -i master
git add <files>
git commit --amend
git add --patch <filename>
```

## Commit Message Format

Put tags after the body and before trailers:

```text
Short imperative summary

Explain why this change is needed and any notable test/risk context.

[Bug][TLC]
[Changelog]

Signed-off-by: Name <email>
```

Type tags: `[Bug]`, `[Feature]`, `[Doc]`, `[Refactor]`.

Component tags: `[TLC]`, `[SANY]`, `[PlusCal]`, `[Toolbox]`, `[TLATeX]`.

Use `[Changelog]` for notable user-visible or release-note-worthy changes.

## DCO Sign-Off

All commits require Developer Certificate of Origin sign-off:

```bash
git commit -s
git commit -s -am "Your commit message"
```

CI catches missing sign-offs.

## PR Checklist

- PR targets `master` of `tlaplus/tlaplus`.
- Scope and issue/context are clear.
- Tests are included or a test gap is explicitly justified.
- Targeted local tests are reported.
- Risk and affected components are stated.
- Generated parser/build artifacts are included only when required.
- DCO trailers are present.
- Unrelated formatting and refactors are absent.

PR CI includes multi-OS tools build/test, grammar sync, Toolbox build, and integration jobs. You can open a PR in your fork to exercise CI earlier.

## Java Style

For modifications, copy local style. For new Java code:

- Include useful Javadoc for public classes and methods.
- Do not mix tabs and spaces.
- Put `{` on the same line as the declaration or statement.
- Use braces for single-statement `if` and `while` bodies.
- Avoid lines over 120 characters.
- Keep UTF-8; mathematical symbols are acceptable.

## After Merge

- Consider performance workflow for large TLC changes.
- Watch follow-up CI, issue, or user reports.
- Check quality metrics only as supporting signal, not source of repo requirements.
