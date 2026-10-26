# Find your first task

From `CONTRIBUTING.md` ("What to do?" and "Where to start?").

## Ways to contribute

| Kind | What it means | Good for learning? |
|---|---|---|
| Fix failing tests | Make a failing test pass on ReactOS, matching Windows behavior | **Best start.** Small, concrete, self-verifying |
| Fix bugs | Pick from [JIRA](https://jira.reactos.org/) | Good, but harder to scope |
| Test and report | Reproduce, narrow down, file or enrich JIRA reports | Gentle on-ramp |
| Fix Coverity defects | Static-analysis findings (request access) | Teaches code reading |
| Implement missing features | See [Missing functionality](https://reactos.org/wiki/Missing_ReactOS_Functionality). Check nobody else owns it first | Later |
| Documentation | Clean-room-safe docs; also this museum | Anytime |

## Concrete places to look

- Failing tests: <https://reactos.org/testman/>
- Beginner issues in JIRA: label [`starter-project`](https://jira.reactos.org/issues/?jql=labels%20%3D%20starter-project)
- Crashing or hanging tests (harder): <https://jira.reactos.org/browse/ROSTESTS-125>
- Ask in the chat if nothing fits.

## A learning loop that works

1. Pick a failing test or a starter issue.
2. Find the Win32 or NT API involved. Use the [tour](#/reactos) to trace it from `kernel32` down to the kernel.
3. Read the existing test in `modules/rostests/` ([Tests](#/guide/tests)) to see what Windows does.
4. Reproduce in a VM, then make the smallest fix.
5. Rerun the test, then open a PR ([Workflow](#/guide/workflow)).

> **Claim work before you do it**
>
> CONTRIBUTING notes that people often start an implementation and move on. Comment on the JIRA issue (or ask in chat) so you do not duplicate work, and finish what you claim.
>
