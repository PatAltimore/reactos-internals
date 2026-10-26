# ReactOS Internals Museum

A guided tour of the [ReactOS](https://github.com/PatAltimore/reactos) source, built as a set of *exhibits*.
Each exhibit follows one thing (a call, a boot, a click) through the code, with links to the exact lines.

- Source snapshot: fork `master` @ `e46f4bb1` (links pin to this commit, so line numbers stay valid).
- Local copy: `git clone --depth 1 https://github.com/PatAltimore/reactos.git reactos` (git-ignored).

## Floor plan

| Directory | What lives there |
|---|---|
| `ntoskrnl/` | Kernel executive: `ke` scheduler/traps, `mm` memory, `ob` objects, `io`, `ps` processes, `cm` registry, `se` security |
| `hal/` | Hardware abstraction layer |
| `dll/ntdll/` | User/kernel boundary: syscall stubs, loader, heap |
| `dll/win32/` | `kernel32`, `advapi32`, ... the APIs apps call |
| `win32ss/` | Win32 subsystem: `user/` windows and messages, `gdi/`, `csrss` |
| `base/system/` | `smss`, `winlogon`, services; `base/shell/explorer` is the desktop |
| `boot/freeldr/` | Bootloader |
| `drivers/` | Storage, filesystems, network, USB, ... |
| `sdk/` | Headers and shared libraries |

## Exhibits

| # | Exhibit | Status |
|---|---|---|
| 1 | [A syscall's journey: `CreateFileW` to the file system driver](exhibits/01-syscall-journey.md) | ready |
| 2 | Boot to desktop (FreeLoader, ntoskrnl, smss, winlogon, explorer) | planned |
| 3 | Objects and handles (`ob`) | planned |
| 4 | Memory: sections, VADs, page faults | planned |
| 5 | A mouse click's journey (driver, win32k, user32) | planned |
| 6 | Drivers and IRPs | planned |
| 7 | The registry (`cm`) and the PE/DLL loader | planned |

Start with Exhibit 1: it crosses every layer, so it gives you the map for everything else.
