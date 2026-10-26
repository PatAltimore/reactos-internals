# Build and boot

Summarized from the repo's `README.md` and `INSTALL`. Full guide: [Building ReactOS](https://reactos.org/wiki/Building_ReactOS).

## Toolchain options

- **RosBE** (ReactOS Build Environment), strongly recommended. Versions for Windows and Unix/Linux: [Build Environment](https://reactos.org/wiki/Build_Environment).
- **MSVC 2019+**, covered on the [CMake wiki page](https://reactos.org/wiki/CMake#Visual_Studio_or_Microsoft_Visual_C.2B.2B).

## Steps (from the repo docs)

1. Create an empty build directory **outside** the source tree.
2. Run the configure script from it: `configure.cmd` on Windows, `configure.sh` on Unix.
3. Build everything with `ninja`, or one module with `ninja <modulename>` (for example `ninja ntoskrnl` or `ninja kernel32`).
4. Make a bootable ISO with `ninja bootcd`.
5. Boot the ISO in a VM (QEMU, VirtualBox, VMware). A VM is the normal development target.

> **Include the tests**
>
> Pass `-DENABLE_ROSTESTS=1` to the configure script to build `modules/rostests`. See [Tests](#/guide/tests).
>

## Debugging

The project has a [Debugging guide](https://reactos.org/wiki/Debugging) (serial/KDBG/WinDbg). the tour's last exercise, breaking on `NtCreateFile`, is a good first debug session once you can boot.

## Status of this page

I (Claude) have not run the build in this environment; the steps come from the repo's own documents. Treat the wiki as the source of truth if anything differs.
