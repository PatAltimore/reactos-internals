---
title: "NtCreateFile.c"
program: "ReactOS Internals"
program_slug: "reactos"
file_path: "modules/rostests/apitests/ntdll/NtCreateFile.c"
language: "C"
github_url: "https://github.com/PatAltimore/reactos/blob/e46f4bb1/modules/rostests/apitests/ntdll/NtCreateFile.c"
year: 2026 snapshot
author: "Aleksandar Andrejevic"
slug: "ntcreatefile-c"
order: 8
description: "A 43-line apitest: the quickest way to see how ReactOS proves it matches Windows"

summary:
  - point: "Each test is a program that checks documented or observed Windows results"
    link: "https://en.wikipedia.org/wiki/Unit_testing"
    link_label: "Unit testing"
  - point: "This test passes deliberately bad pointers to NtCreateFile"
  - point: "Writing a test like this is a typical first contribution"

enhancements:
  - id: "start-test"
    line_start: 8
    line_end: 14
    title: "The Anatomy of an Apitest"
    wikipedia_url: "https://en.wikipedia.org/wiki/Unit_testing"
    image_url: ""
    image_caption: ""
    content: "Every apitest is a small program built from the same pieces. The file includes precomp.h, which brings in the test framework, and wraps its body in START_TEST with the name of the thing being tested. Tests live next to the others for the same DLL (here modules/rostests/apitests/ntdll) and are listed in that directory's CMakeLists.txt. They are built when ReactOS is configured with ENABLE_ROSTESTS. The project describes its tests as checking ReactOS against how Windows behaves, which is what makes them a precise yardstick."
  - id: "bad-pointer-test"
    line_start: 16
    line_end: 28
    title: "Passing a Pointer That Cannot Be Read"
    wikipedia_url: ""
    image_url: ""
    image_caption: ""
    content: "The object-attributes argument is a deliberately invalid kernel-range pointer (0xCCCC...C8). From user mode, the kernel must not crash or read it: it must probe the pointer and return STATUS_ACCESS_VIOLATION. ok_hex compares the actual status with the expected one and reports a failure with both values. The kernel has to validate such pointers before using them; the validation of the other parameters is visible in file.c."
  - id: "misaligned-test"
    line_start: 30
    line_end: 42
    title: "The Same Pointer, Misaligned"
    wikipedia_url: ""
    image_url: ""
    image_caption: ""
    content: "Changing the last nibble from 8 to F makes the pointer misaligned, and Windows answers with STATUS_DATATYPE_MISALIGNMENT instead. A short test pair like this pins down two distinct error paths. Adding the missing cases, such as other invalid arguments or flag combinations, is a very approachable way to start contributing: find the Windows behaviour from documentation or by experiment, write the test, then fix ReactOS if it fails."

---

```cpp
/*
 * PROJECT:         ReactOS api tests
 * LICENSE:         See COPYING in the top level directory
 * PURPOSE:         Test for NtCreateFile
 * PROGRAMMER:      Aleksandar Andrejevic <theflash AT sdf DOT lonestar DOT org>
 */

#include "precomp.h"

START_TEST(NtCreateFile)
{
    NTSTATUS Status;
    HANDLE FileHandle;
    IO_STATUS_BLOCK StatusBlock;

    Status = NtCreateFile(&FileHandle,
                          FILE_READ_DATA,
                          (POBJECT_ATTRIBUTES)(ULONG_PTR)0xCCCCCCCCCCCCCCC8ULL,
                          &StatusBlock,
                          NULL,
                          FILE_ATTRIBUTE_NORMAL,
                          FILE_SHARE_READ,
                          FILE_OPEN_IF,
                          FILE_NON_DIRECTORY_FILE,
                          NULL,
                          0);

    ok_hex(Status, STATUS_ACCESS_VIOLATION);

    Status = NtCreateFile(&FileHandle,
                          FILE_READ_DATA,
                          (POBJECT_ATTRIBUTES)(ULONG_PTR)0xCCCCCCCCCCCCCCCFULL,
                          &StatusBlock,
                          NULL,
                          FILE_ATTRIBUTE_NORMAL,
                          FILE_SHARE_READ,
                          FILE_OPEN_IF,
                          FILE_NON_DIRECTORY_FILE,
                          NULL,
                          0);

    ok_hex(Status, STATUS_DATATYPE_MISALIGNMENT);
}
```
