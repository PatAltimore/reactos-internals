# Workflow: from change to pull request

From `CONTRIBUTING.md`, `.gitmessage`, `.github/PULL_REQUEST_TEMPLATE.md` and `PULL_REQUEST_MANAGEMENT.md`.

## 1. Set up git

```bash
git config user.name "Your Real Name"
git config user.email "your-real@email"
git config commit.template .gitmessage
```

Use a real name and real email, and in GitHub email settings uncheck "Keep my email addresses private" (or pick a suitable public address). See the [Git for Dummies](https://reactos.org/wiki/ReactOS_Git_For_Dummies) page if you need to amend commits.

## 2. Branch

Fork `reactos/reactos` (your fork is `PatAltimore/reactos`), branch from up-to-date `master`, and keep one topic per branch. Pull requests are the preferred way to submit; patches by email are also accepted ([Submitting Patches](https://reactos.org/wiki/Submitting_Patches)).

## 3. Commit message format

From `.gitmessage`:

```text
[MODULE] Short imperative summary (#pr-num)

Why you made the change. Wrap at ~72 chars.

CORE-XXXX
```

- `[MODULE]` is usually the CMake module name in caps. Look at recent upstream history for the area you touch to copy its prefix convention.
- Imperative mood, no trailing period.
- Blank lines between summary, description and bug IDs.
- JIRA and Coverity references go on the last line.

## 4. Open the pull request

The template asks for: purpose, JIRA issue link, proposed changes, a TODO list for work in progress, and testbot results (filled in by developers).

## 5. Review

`CODEOWNERS` lists maintainers per area, and `PULL_REQUEST_MANAGEMENT.md` explains how PRs are handled. Expect review comments, push follow-up commits, and ask in chat if you are stuck. CI runs from `.github/workflows/build.yml`.

## Checklist before you push

- [ ] I have not seen Microsoft Windows source ([rule](#/guide/start))
- [ ] Real name and email on every commit
- [ ] One topic, small diff, no drive-by reformatting
- [ ] Commit message follows the template and explains why
- [ ] Style check passes ([Style](#/guide/style))
- [ ] Tests added or run ([Tests](#/guide/tests))
