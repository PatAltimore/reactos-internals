# Code style

Authority: `CODING_STYLE.md` in the repo and the wiki's [Coding Style](https://reactos.org/wiki/Coding_Style) and [Programming Guidelines](https://reactos.org/wiki/Programming_Guidelines).

`CODING_STYLE.md` covers: file structure, indentation and line width, spacing, line breaking, braces, control structures, naming, commenting, null/false/0, notes on reformatting existing code, and automatic tools.

## Tools in the repo

- `.clang-format` and `.editorconfig` at the repo root.
- `sdk/tools/check_code_format.sh` checks formatting; `sdk/tools/do_code_format.sh` applies it.

## Habits that matter to reviewers

- **Match the surrounding code.** Do not reformat unrelated lines; reformatting churn hides your real change (`CODING_STYLE.md` has a section on this).
- **Keep changes focused.** One topic per PR.
- **Explain why** in the commit message, not just what.

Read `CODING_STYLE.md` fully once before your first PR.
