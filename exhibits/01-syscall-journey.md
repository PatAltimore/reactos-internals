# Exhibit 1: A syscall's journey

**Question:** when a program calls `CreateFileW("C:\\hello.txt", ...)`, what actually runs?

**Answer in one picture** (x86 flavor; amd64 differs mainly at the trap step):

```
 app.exe
   |  CreateFileW                          kernel32.dll   user mode
   v
 RtlDosPathNameToNtPathName_U              "C:\hello.txt" -> "\??\C:\hello.txt"
   |  NtCreateFile                         ntdll.dll      user mode
   v
 stub: mov eax,<id>; call KiFastSystemCall (sysenter) or int 2E
 ================================================================ privilege boundary
   |  KiFastCallEntry / KiSystemService    ntoskrnl ke    kernel mode
   v
 KiSystemServiceHandler --(table lookup by eax)-->
   |  NtCreateFile                         ntoskrnl io
   v
 IoCreateFile -> IopCreateFile
   |  ObOpenObjectByName -> ObpLookupObjectName   ntoskrnl ob
   v
 \??\C: (symlink) -> \Device\HarddiskVolumeN -> ParseProcedure
   |  IopParseDevice                       ntoskrnl io
   v
 builds IRP_MJ_CREATE, IoCallDriver -> file system driver
```

Links pin to commit `e46f4bb1` of the fork:
<https://github.com/PatAltimore/reactos/blob/e46f4bb1/>

## Stop 1: kernel32, the friendly API

[`dll/win32/kernel32/client/file/create.c`](https://github.com/PatAltimore/reactos/blob/e46f4bb1/dll/win32/kernel32/client/file/create.c)

- `CreateFileW` at line 60. It validates arguments and translates Win32 flags into NT ones (`CREATE_NEW` becomes `FILE_CREATE`, `OPEN_EXISTING` becomes `FILE_OPEN`, and so on, starting near line 87).
- Line 183: `RtlDosPathNameToNtPathName_U` converts the DOS path to an NT path (`\??\C:\hello.txt`).
- Line 294: the real work is one call to `NtCreateFile`.
- Lines 329-358: the NT status is converted back to a Win32 error (`BaseSetLastNTError`, `SetLastError`). This is where `GetLastError()` values come from.

**Notice:** kernel32 is mostly *translation*. Win32 is a personality layered over the NT native API.

## Stop 2: ntdll, the syscall stub

[`ntoskrnl/sysfuncs.lst:40`](https://github.com/PatAltimore/reactos/blob/e46f4bb1/ntoskrnl/sysfuncs.lst#L40) says `NtCreateFile 11`: the name and the number of 4-byte arguments.

There is no hand-written C for the user-mode `NtCreateFile`. [`ntoskrnl/ntdll.S`](https://github.com/PatAltimore/reactos/blob/e46f4bb1/ntoskrnl/ntdll.S) includes the list and expands a `STUB_U name, argcount` macro (defined in `syscalls.inc`) for every entry, generating one tiny function per syscall. The list is built into the `ntdllsys` library that ntdll links against (see [`ntoskrnl/CMakeLists.txt`](https://github.com/PatAltimore/reactos/blob/e46f4bb1/ntoskrnl/CMakeLists.txt) around line 63).

Each stub loads the syscall number into `eax` and goes through a helper in [`dll/ntdll/dispatch/i386/dispatch.S`](https://github.com/PatAltimore/reactos/blob/e46f4bb1/dll/ntdll/dispatch/i386/dispatch.S): `KiIntSystemCall` (line 246, `int 2E`) or `KiFastSystemCall` (line 259, `sysenter`).

The export list [`dll/ntdll/def/ntdll.spec:274`](https://github.com/PatAltimore/reactos/blob/e46f4bb1/dll/ntdll/def/ntdll.spec#L274) declares the user-mode `NtCreateFile` prototype. (The kernel's own is at [`ntoskrnl/ntoskrnl.spec:853`](https://github.com/PatAltimore/reactos/blob/e46f4bb1/ntoskrnl/ntoskrnl.spec#L853).)

## Stop 3: the trap into the kernel

[`ntoskrnl/ke/i386/trap.s`](https://github.com/PatAltimore/reactos/blob/e46f4bb1/ntoskrnl/ke/i386/trap.s)

- Line 69: the IDT entry for `INT 2E` points to `_KiSystemService`, with DPL3 so user mode may invoke it.
- Lines 143 and 152: `_KiSystemService` and `_KiFastCallEntry` build a trap frame (`KiEnterTrap`) and both call the same C handler.

## Stop 4: the dispatcher

[`ntoskrnl/ke/i386/traphdlr.c:1722`](https://github.com/PatAltimore/reactos/blob/e46f4bb1/ntoskrnl/ke/i386/traphdlr.c#L1722), `KiSystemServiceHandler`:

1. Saves the previous mode, chains the trap frame, enables interrupts.
2. Splits the number in `eax`: upper bits pick the **service table** (ntoskrnl or win32k), lower bits are the **index**.
3. Bounds-checks against the table limit. A bad number gives `STATUS_INVALID_SYSTEM_SERVICE`, except a first call into the win32k table, which converts the thread to a GUI thread.
4. Lines 1839-1840: `Handler = DescriptorTable->Base[Id]`, then the call goes through `KiSystemCallTrampoline`, which copies the arguments from the user stack.

**Notice:** a syscall is just an indexed function table. There are two tables, one for the kernel and a second that win32k plugs in (Exhibit 5).

## Stop 5: the I/O manager

[`ntoskrnl/io/iomgr/file.c`](https://github.com/PatAltimore/reactos/blob/e46f4bb1/ntoskrnl/io/iomgr/file.c)

- `NtCreateFile` (line 3757) is a thin wrapper over `IoCreateFile` (line 3009), which calls `IopCreateFile` (line 2553).
- `IopCreateFile` probes user pointers, captures the object attributes, and builds an `OPEN_PACKET`. It then calls `ObOpenObjectByName` (line 2872). A comment just above notes that `IopParseDevice` will create the file object.

## Stop 6: the object manager resolves the name

[`ntoskrnl/ob/obname.c:446`](https://github.com/PatAltimore/reactos/blob/e46f4bb1/ntoskrnl/ob/obname.c#L446), `ObpLookupObjectName`:

- Walks `\??\C:\hello.txt` one component at a time through the object namespace.
- `\??\C:` is a **symbolic link** to something like `\Device\HarddiskVolume1`, and the walk follows it.
- Line 530: when it reaches an object whose type has a `ParseProcedure` (a Device object does), it hands over the *remaining* name (`\hello.txt`).

## Stop 7: IopParseDevice, from a name to an IRP

[`ntoskrnl/io/iomgr/file.c:321`](https://github.com/PatAltimore/reactos/blob/e46f4bb1/ntoskrnl/io/iomgr/file.c#L321)

- Allocates the `FILE_OBJECT` and an `IRP` for `IRP_MJ_CREATE`.
- Lines 985-995: copies the remaining name into the file object, queues the IRP to the thread, and calls `IoCallDriver` into the file system driver.
- If the volume is not yet mounted, the mount path runs first so a file system gets chosen.

The file system driver (see `drivers/filesystems/`) opens the file and completes the IRP. The result travels back up: the object manager inserts the file object into the handle table, `NtCreateFile` returns the **handle**, the trap exits, and `CreateFileW` hands it to the app.

## Takeaways

1. **Layers with one job each:** Win32 API (translate), ntdll (stub), `ke` (trap and dispatch), `io` (I/O semantics), `ob` (names and handles), driver (storage).
2. **Everything is an object:** files, devices, events, processes. Opening a file is a name lookup in a namespace that ends in a parse routine.
3. **Drivers are reached by IRPs,** not direct calls.
4. **The pattern repeats** for registry (`NtOpenKey`), processes (`NtCreateUserProcess`) and the rest.

## Exercises

1. Find `BaseSetLastNTError` and see which Win32 error `STATUS_OBJECT_NAME_NOT_FOUND` becomes.
2. In `sysfuncs.lst`, find another syscall with 11 args. Which Win32 function sits above it?
3. Read `IopParseFile` (file.c:1316) and explain how opening a relative path differs from an absolute one.
4. Boot ReactOS in QEMU, attach a debugger, and break on `NtCreateFile` to watch this stack live.

## Verify me

Every line number was taken from the pinned commit, but I traced this by grepping and reading selected lines, not by running the system. Open the links and read around them.
