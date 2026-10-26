# Tests

ReactOS tests compare its API behavior to Windows. They live in `modules/rostests/`.

## Layout (top level)

| Directory | Purpose |
|---|---|
| `apitests/` | User-mode API tests, one folder per DLL (`ntdll`, `kernel32`, `advapi32`, ...) |
| `kmtests/` | Kernel-mode tests (a test driver plus runner) |
| `winetests/` | Tests synced from Wine |
| `rosautotest/` | The runner used for automated runs |
| `drivers/`, `dibtests/`, `dxtest/`, `unittests/`, `tests/`, `regtests/` | Other suites |

## Enable them

Configure with `-DENABLE_ROSTESTS=1` (`configure.cmd` or `./configure.sh`), as described in `modules/rostests/readme.txt`.

## Example tied to the tour

The syscall in the [CreateFileW tour](#/reactos/create-c) has a test: `modules/rostests/apitests/ntdll/NtCreateFile.c`. Related file tests live under `apitests/kernel32/` (for example `ReadFile.c`, `WriteFile.c`, `FindFiles.c`). Reading these shows what edge cases the project already pins down, and a missing case is a good first contribution.

## Results

Automated results and failing tests are tracked in [Testman](https://reactos.org/testman/).

## Rule of thumb

If you fix a bug, add or extend a test that fails before and passes after, expressed as the behavior Windows documents or shows.
