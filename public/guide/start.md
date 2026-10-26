# Before you start

This guide summarizes the project's own `CONTRIBUTING.md`, `CODING_STYLE.md` and `README.md`. Those files are the authority; this site is a reading guide. Read them in the repo too.

> **Clean-room rule**
>
> ReactOS cannot accept contributions from anyone who has seen Microsoft Windows source code or related Microsoft products' source, including the leaked Windows 2000 source and the Windows Research Kernel. The project asks contributors to affirm they have not. If that is not true for you, do not contribute code.
>
> Learn from **documented behavior, public docs, your own black-box experiments, tests, and the ReactOS and Wine sources**, never from leaked or decompiled Microsoft code.
>

## Other ground rules

- **Real name and real email.** No anonymous code contributions. Commits need your full name and a real `user.email`. (Art and out-of-code docs may use an alias.)
- **Small, focused changes.** One topic per pull request. If you spot an unrelated issue, leave a note or file it instead of fixing it in the same PR.
- **Third-party code goes upstream.** Wine, BtrFS and similar code should be fixed in those projects. See `media/doc/3rd_Party_Files.txt` and `README.WINE`.
- **Ask questions.** The project's [chat](https://reactos.org/wiki/Mattermost) exists for this. There is also a `CODE_OF_CONDUCT.md`.

## The path

| Step | Page |
|---|---|
| 1. Build and boot it | [Build](#/guide/build) |
| 2. Pick a first task | [Find work](#/guide/find-work) |
| 3. Understand the code | [The tour](#/reactos) |
| 4. Prove your change | [Tests](#/guide/tests) |
| 5. Match the style | [Style](#/guide/style) |
| 6. Submit it | [Workflow](#/guide/workflow) |

## Where to get help

- Website: <https://reactos.org/> · Wiki: <https://reactos.org/wiki/>
- Bugs: <https://jira.reactos.org/>
- Test results: <https://reactos.org/testman/>
- Git help: <https://reactos.org/wiki/ReactOS_Git_For_Dummies>
