---
title: "create.c"
program: "ReactOS Internals"
program_slug: "reactos"
file_path: "dll/win32/kernel32/client/file/create.c"
language: "C"
github_url: "https://github.com/PatAltimore/reactos/blob/e46f4bb1/dll/win32/kernel32/client/file/create.c"
year: since 1998
author: "Ariadne, KJK::Hyperion and ReactOS contributors"
slug: "create-c"
order: 1
description: "CreateFileW: how the Win32 file API is translated into the NT native call NtCreateFile"

summary:
  - point: "Win32 flags and dispositions are translated into NT options"
    link: "https://en.wikipedia.org/wiki/Windows_API"
    link_label: "Windows API"
  - point: "DOS paths become NT paths before the native call"
    link: "https://en.wikipedia.org/wiki/Native_API"
    link_label: "Native API"
  - point: "NT status codes are mapped back to GetLastError values"
    link: "https://en.wikipedia.org/wiki/Windows_NT"
    link_label: "Windows NT"
  - point: "Special cases: console device names and POSIX semantics"

enhancements:
  - id: "createfilew-entry"
    line_start: 57
    line_end: 83
    title: "The Win32 Face of NT"
    wikipedia_url: "https://en.wikipedia.org/wiki/Windows_API"
    image_url: ""
    image_caption: ""
    content: "CreateFileW is the function nearly every Windows program uses to open a file, a device or a pipe. The comment above it marks it as implemented. Right away it rejects an empty name with ERROR_PATH_NOT_FOUND, which shows the pattern of the whole file: validate in Win32 terms, report failures through SetLastError. For a contributor, kernel32 is usually the friendliest place to start because the behaviour you must match is Win32-visible and testable from a normal program."
  - id: "disposition-translation"
    line_start: 87
    line_end: 113
    title: "Five Win32 Verbs, Five NT Dispositions"
    wikipedia_url: ""
    image_url: ""
    image_caption: ""
    content: "Win32 describes what to do with an existing or missing file using CREATE_NEW, CREATE_ALWAYS, OPEN_EXISTING, OPEN_ALWAYS and TRUNCATE_EXISTING. NT uses a different vocabulary: FILE_CREATE, FILE_OVERWRITE_IF, FILE_OPEN, FILE_OPEN_IF and FILE_OVERWRITE. This switch is a pure translation table, and anything else is rejected with ERROR_INVALID_PARAMETER. Later, the code reuses the translated value to decide which last-error to report, so the translation also affects behaviour you can see from outside."
  - id: "console-special-case"
    line_start: 115
    line_end: 123
    title: "Device Names Handled Before NT Sees Them"
    wikipedia_url: ""
    image_url: ""
    image_caption: ""
    content: "Before any NT call, the code checks whether the name refers to a console, such as CONIN$ or CONOUT$, and if so hands off to OpenConsoleW. Console handles are served by the Win32 subsystem process rather than the file system, so they cannot go through NtCreateFile. This is a good example of Win32-only behaviour that lives in kernel32 and has no NT equivalent."
  - id: "flag-translation"
    line_start: 125
    line_end: 180
    title: "Translating Flags and Access Rights"
    wikipedia_url: ""
    image_url: ""
    image_caption: ""
    content: "Here the Win32 flags in dwFlagsAndAttributes become NT create options. The comment at lines 130 to 131 explains a subtle choice: handles opened without FILE_FLAG_OVERLAPPED get FILE_SYNCHRONOUS_IO_NONALERT, meaning the I/O manager makes calls synchronous but does not let APCs interrupt the wait. At line 178 every handle also gets SYNCHRONIZE and FILE_READ_ATTRIBUTES so it can always be waited on and queried. A mistake in a mapping like this shows up as an application that hangs or an unexpected access-denied error, which is why these lines are covered by tests."
  - id: "path-conversion"
    line_start: 182
    line_end: 193
    title: "From C:\hello.txt to \??\C:\hello.txt"
    wikipedia_url: ""
    image_url: ""
    image_caption: ""
    content: "RtlDosPathNameToNtPathName_U converts a DOS-style path into the NT path form that the object manager understands, for example turning C:\hello.txt into \??\C:\hello.txt. A failure here is reported as ERROR_FILE_NOT_FOUND. The function lives in ntdll's runtime library, not here, and the output buffer is allocated from the process heap, which is why the code frees NtPathU.Buffer after the call. Path normalisation is a classic source of subtle Windows compatibility bugs."
  - id: "trailing-backslash-check"
    line_start: 195
    line_end: 200
    title: "A Line Worth Checking"
    wikipedia_url: ""
    image_url: ""
    image_caption: ""
    content: "This sets TrailingBackslash from the last character of the NT path, but the condition only tests that the character is non-zero, with no comparison to a backslash. Read literally, that is true for any non-empty path. The flag is used at lines 331 to 335 to choose ERROR_PATH_NOT_FOUND over the generic mapping when the target turns out to be a directory. This is an observation, not a verified bug: before touching it, compare against upstream history and write an apitest showing what Windows returns. Small, test-backed corrections like this are exactly what the project asks newcomers for."
  - id: "nt-call"
    line_start: 293
    line_end: 316
    title: "The Real Work: One Call to NtCreateFile"
    wikipedia_url: "https://en.wikipedia.org/wiki/Native_API"
    image_url: ""
    image_caption: ""
    content: "After all the translation, the actual work is a single call to NtCreateFile, the native API function that exists in ntdll and, behind it, in the kernel. All eleven arguments are NT-native: an object-attributes structure naming the file, an I/O status block for results, the translated disposition and options, and an optional extended-attributes buffer. After the call the path buffer and any EA buffer are freed regardless of the outcome. From here the story continues in dispatch.S and the kernel."
  - id: "error-mapping"
    line_start: 318
    line_end: 342
    title: "Mapping NT Status Back to GetLastError"
    wikipedia_url: ""
    image_url: ""
    image_caption: ""
    content: "NtCreateFile returns an NTSTATUS, but Win32 programs call GetLastError. BaseSetLastNTError performs the general mapping, and two cases are special-cased because the generic mapping gives the wrong Win32 code. The comment at lines 321 to 325 explains that CREATE_NEW on an existing file must produce ERROR_FILE_EXISTS, not ERROR_ALREADY_EXISTS. Error-code compatibility matters because real programs branch on these exact values."
  - id: "success-last-error"
    line_start: 344
    line_end: 361
    title: "Success That Still Sets an Error"
    wikipedia_url: ""
    image_url: ""
    image_caption: ""
    content: "A surprising Win32 rule lives here: when CREATE_ALWAYS overwrites a file or OPEN_ALWAYS opens an existing one, the call succeeds but GetLastError returns ERROR_ALREADY_EXISTS. NT reports what happened through IoStatusBlock.Information (FILE_OPENED, FILE_CREATED, FILE_OVERWRITTEN), and this code converts it. Programs that use this to detect whether a file pre-existed depend on exactly this behaviour."

---

```cpp
/*
 * COPYRIGHT:       See COPYING in the top level directory
 * PROJECT:         ReactOS system libraries
 * FILE:            dll/win32/kernel32/client/file/create.c
 * PURPOSE:         Directory functions
 * PROGRAMMER:      Ariadne ( ariadne@xs4all.nl)
 * UPDATE HISTORY:
 *                  Created 01/11/98
 *                  Removed use of SearchPath (not used by Windows)
 *                  18/08/2002: CreateFileW mess cleaned up (KJK::Hyperion)
 *                  24/08/2002: removed superfluous DPRINTs (KJK::Hyperion)
 */

/* INCLUDES *****************************************************************/

#include <k32.h>
#define NDEBUG
#include <debug.h>

#if DBG
DEBUG_CHANNEL(kernel32file);
#endif

/* FUNCTIONS ****************************************************************/

/*
 * @implemented
 */
HANDLE WINAPI CreateFileA (LPCSTR			lpFileName,
			    DWORD			dwDesiredAccess,
			    DWORD			dwShareMode,
			    LPSECURITY_ATTRIBUTES	lpSecurityAttributes,
			    DWORD			dwCreationDisposition,
			    DWORD			dwFlagsAndAttributes,
			    HANDLE			hTemplateFile)
{
   PWCHAR FileNameW;
   HANDLE FileHandle;

   TRACE("CreateFileA(lpFileName %s)\n",lpFileName);

   if (!(FileNameW = FilenameA2W(lpFileName, FALSE)))
      return INVALID_HANDLE_VALUE;

   FileHandle = CreateFileW (FileNameW,
			     dwDesiredAccess,
			     dwShareMode,
			     lpSecurityAttributes,
			     dwCreationDisposition,
			     dwFlagsAndAttributes,
			     hTemplateFile);

   return FileHandle;
}


/*
 * @implemented
 */
HANDLE WINAPI CreateFileW (LPCWSTR			lpFileName,
			    DWORD			dwDesiredAccess,
			    DWORD			dwShareMode,
			    LPSECURITY_ATTRIBUTES	lpSecurityAttributes,
			    DWORD			dwCreationDisposition,
			    DWORD			dwFlagsAndAttributes,
			    HANDLE			hTemplateFile)
{
   OBJECT_ATTRIBUTES ObjectAttributes;
   IO_STATUS_BLOCK IoStatusBlock;
   UNICODE_STRING NtPathU;
   LPCWSTR pszConsoleFileName;
   HANDLE FileHandle;
   NTSTATUS Status;
   ULONG FileAttributes, Flags = 0;
   PVOID EaBuffer = NULL;
   ULONG EaLength = 0;
   BOOLEAN TrailingBackslash;

   if (!lpFileName || !lpFileName[0])
   {
       SetLastError( ERROR_PATH_NOT_FOUND );
       return INVALID_HANDLE_VALUE;
   }

   TRACE("CreateFileW(lpFileName %S)\n",lpFileName);

   /* validate & translate the creation disposition */
   switch (dwCreationDisposition)
     {
      case CREATE_NEW:
	dwCreationDisposition = FILE_CREATE;
	break;

      case CREATE_ALWAYS:
	dwCreationDisposition = FILE_OVERWRITE_IF;
	break;

      case OPEN_EXISTING:
	dwCreationDisposition = FILE_OPEN;
	break;

      case OPEN_ALWAYS:
	dwCreationDisposition = FILE_OPEN_IF;
	break;

      case TRUNCATE_EXISTING:
	dwCreationDisposition = FILE_OVERWRITE;
        break;

      default:
        SetLastError(ERROR_INVALID_PARAMETER);
        return (INVALID_HANDLE_VALUE);
     }

   /* check for console input/output */
   pszConsoleFileName = IntCheckForConsoleFileName(lpFileName, dwDesiredAccess);
   if (pszConsoleFileName)
   {
      return OpenConsoleW(pszConsoleFileName,
                          dwDesiredAccess,
                          lpSecurityAttributes ? lpSecurityAttributes->bInheritHandle : FALSE,
                          FILE_SHARE_READ | FILE_SHARE_WRITE);
   }

  /* validate & translate the flags */

   /* translate the flags that need no validation */
   if (!(dwFlagsAndAttributes & FILE_FLAG_OVERLAPPED))
   {
      /* yes, nonalert is correct! apc's are not delivered
      while waiting for file io to complete */
      Flags |= FILE_SYNCHRONOUS_IO_NONALERT;
   }

   if(dwFlagsAndAttributes & FILE_FLAG_WRITE_THROUGH)
      Flags |= FILE_WRITE_THROUGH;

   if(dwFlagsAndAttributes & FILE_FLAG_NO_BUFFERING)
      Flags |= FILE_NO_INTERMEDIATE_BUFFERING;

   if(dwFlagsAndAttributes & FILE_FLAG_RANDOM_ACCESS)
      Flags |= FILE_RANDOM_ACCESS;

   if(dwFlagsAndAttributes & FILE_FLAG_SEQUENTIAL_SCAN)
      Flags |= FILE_SEQUENTIAL_ONLY;

   if(dwFlagsAndAttributes & FILE_FLAG_DELETE_ON_CLOSE)
   {
      Flags |= FILE_DELETE_ON_CLOSE;
      dwDesiredAccess |= DELETE;
   }

   if(dwFlagsAndAttributes & FILE_FLAG_BACKUP_SEMANTICS)
   {
      if(dwDesiredAccess & GENERIC_ALL)
         Flags |= FILE_OPEN_FOR_BACKUP_INTENT | FILE_OPEN_REMOTE_INSTANCE;
      else
      {
         if(dwDesiredAccess & GENERIC_READ)
            Flags |= FILE_OPEN_FOR_BACKUP_INTENT;

         if(dwDesiredAccess & GENERIC_WRITE)
            Flags |= FILE_OPEN_REMOTE_INSTANCE;
      }
   }
   else
      Flags |= FILE_NON_DIRECTORY_FILE;

   if(dwFlagsAndAttributes & FILE_FLAG_OPEN_REPARSE_POINT)
      Flags |= FILE_OPEN_REPARSE_POINT;

   if(dwFlagsAndAttributes & FILE_FLAG_OPEN_NO_RECALL)
      Flags |= FILE_OPEN_NO_RECALL;

   FileAttributes = (dwFlagsAndAttributes & (FILE_ATTRIBUTE_VALID_FLAGS & ~FILE_ATTRIBUTE_DIRECTORY));

   /* handle may always be waited on and querying attributes are always allowed */
   dwDesiredAccess |= SYNCHRONIZE | FILE_READ_ATTRIBUTES;

   /* FILE_FLAG_POSIX_SEMANTICS is handled later */

   /* validate & translate the filename */
   if (!RtlDosPathNameToNtPathName_U (lpFileName,
				      &NtPathU,
				      NULL,
				      NULL))
   {
     WARN("Invalid path\n");
     SetLastError(ERROR_FILE_NOT_FOUND);
     return INVALID_HANDLE_VALUE;
   }

   TRACE("NtPathU \'%wZ\'\n", &NtPathU);

   TrailingBackslash = FALSE;
   if (NtPathU.Length >= sizeof(WCHAR) &&
       NtPathU.Buffer[NtPathU.Length / sizeof(WCHAR) - 1])
   {
      TrailingBackslash = TRUE;
   }

   if (hTemplateFile != NULL)
   {
      FILE_EA_INFORMATION EaInformation;

      for (;;)
      {
         /* try to get the size of the extended attributes, if we fail just continue
            creating the file without copying the attributes! */
         Status = NtQueryInformationFile(hTemplateFile,
                                         &IoStatusBlock,
                                         &EaInformation,
                                         sizeof(FILE_EA_INFORMATION),
                                         FileEaInformation);
         if (NT_SUCCESS(Status) && (EaInformation.EaSize != 0))
         {
            /* there's extended attributes to read, let's give it a try */
            EaBuffer = RtlAllocateHeap(RtlGetProcessHeap(),
                                       0,
                                       EaInformation.EaSize);
            if (EaBuffer == NULL)
            {
               RtlFreeHeap(RtlGetProcessHeap(),
                           0,
                           NtPathU.Buffer);

               /* the template file handle is valid and has extended attributes,
                  however we seem to lack some memory here. We should fail here! */
               SetLastError(ERROR_NOT_ENOUGH_MEMORY);
               return INVALID_HANDLE_VALUE;
            }

            Status = NtQueryEaFile(hTemplateFile,
                                   &IoStatusBlock,
                                   EaBuffer,
                                   EaInformation.EaSize,
                                   FALSE,
                                   NULL,
                                   0,
                                   NULL,
                                   TRUE);

            if (NT_SUCCESS(Status))
            {
               /* we successfully read the extended attributes, break the loop
                  and continue */
               EaLength = EaInformation.EaSize;
               break;
            }
            else
            {
               RtlFreeHeap(RtlGetProcessHeap(),
                           0,
                           EaBuffer);
               EaBuffer = NULL;

               if (Status != STATUS_BUFFER_TOO_SMALL)
               {
                  /* unless we just allocated not enough memory, break the loop
                     and just continue without copying extended attributes */
                  break;
               }
            }
         }
         else
         {
            /* we either failed to get the size of the extended attributes or
               they're empty, just continue as there's no need to copy
               attributes */
            break;
         }
      }
   }

   /* build the object attributes */
   InitializeObjectAttributes(&ObjectAttributes,
                              &NtPathU,
                              0,
                              NULL,
                              NULL);

   if (lpSecurityAttributes)
   {
      if(lpSecurityAttributes->bInheritHandle)
         ObjectAttributes.Attributes |= OBJ_INHERIT;

      ObjectAttributes.SecurityDescriptor = lpSecurityAttributes->lpSecurityDescriptor;
   }

   if(!(dwFlagsAndAttributes & FILE_FLAG_POSIX_SEMANTICS))
    ObjectAttributes.Attributes |= OBJ_CASE_INSENSITIVE;

   /* perform the call */
   Status = NtCreateFile (&FileHandle,
			  dwDesiredAccess,
			  &ObjectAttributes,
			  &IoStatusBlock,
			  NULL,
			  FileAttributes,
			  dwShareMode,
			  dwCreationDisposition,
			  Flags,
			  EaBuffer,
			  EaLength);

   RtlFreeHeap(RtlGetProcessHeap(),
               0,
               NtPathU.Buffer);

   /* free the extended attributes buffer if allocated */
   if (EaBuffer != NULL)
   {
      RtlFreeHeap(RtlGetProcessHeap(),
                  0,
                  EaBuffer);
   }

   /* error */
   if (!NT_SUCCESS(Status))
   {
      /* In the case file creation was rejected due to CREATE_NEW flag
       * was specified and file with that name already exists, correct
       * last error is ERROR_FILE_EXISTS and not ERROR_ALREADY_EXISTS.
       * Note: RtlNtStatusToDosError is not the subject to blame here.
       */
      if (Status == STATUS_OBJECT_NAME_COLLISION &&
          dwCreationDisposition == FILE_CREATE)
      {
         SetLastError( ERROR_FILE_EXISTS );
      }
      else if (Status == STATUS_FILE_IS_A_DIRECTORY &&
               TrailingBackslash)
      {
         SetLastError(ERROR_PATH_NOT_FOUND);
      }
      else
      {
         BaseSetLastNTError (Status);
      }

      return INVALID_HANDLE_VALUE;
   }

  /*
  create with OPEN_ALWAYS (FILE_OPEN_IF) returns info = FILE_OPENED or FILE_CREATED
  create with CREATE_ALWAYS (FILE_OVERWRITE_IF) returns info = FILE_OVERWRITTEN or FILE_CREATED
  */
  if (dwCreationDisposition == FILE_OPEN_IF)
  {
    SetLastError(IoStatusBlock.Information == FILE_OPENED ? ERROR_ALREADY_EXISTS : ERROR_SUCCESS);
  }
  else if (dwCreationDisposition == FILE_OVERWRITE_IF)
  {
    SetLastError(IoStatusBlock.Information == FILE_OVERWRITTEN ? ERROR_ALREADY_EXISTS : ERROR_SUCCESS);
  }
  else
  {
    SetLastError(ERROR_SUCCESS);
  }

  return FileHandle;
}

/*
 * @implemented
 */
HFILE WINAPI
OpenFile(LPCSTR lpFileName,
	 LPOFSTRUCT lpReOpenBuff,
	 UINT uStyle)
{
	OBJECT_ATTRIBUTES ObjectAttributes;
	IO_STATUS_BLOCK IoStatusBlock;
	UNICODE_STRING FileNameString;
	UNICODE_STRING FileNameU;
	ANSI_STRING FileName;
	WCHAR PathNameW[MAX_PATH];
	HANDLE FileHandle = NULL;
	NTSTATUS errCode;
	PWCHAR FilePart;
	ULONG Len;

	TRACE("OpenFile('%s', lpReOpenBuff %p, uStyle %x)\n", lpFileName, lpReOpenBuff, uStyle);

	if (lpReOpenBuff == NULL)
	{
		return HFILE_ERROR;
	}

    lpReOpenBuff->nErrCode = 0;

	if (uStyle & OF_REOPEN) lpFileName = lpReOpenBuff->szPathName;

	if (!lpFileName)
	{
		return HFILE_ERROR;
	}

	if (!GetFullPathNameA(lpFileName,
						  sizeof(lpReOpenBuff->szPathName),
						  lpReOpenBuff->szPathName,
						  NULL))
	{
	    lpReOpenBuff->nErrCode = (WORD)GetLastError();
		return HFILE_ERROR;
	}

    if (uStyle & OF_PARSE)
    {
        lpReOpenBuff->fFixedDisk = (GetDriveTypeA(lpReOpenBuff->szPathName) != DRIVE_REMOVABLE);
        TRACE("(%s): OF_PARSE, res = '%s'\n", lpFileName, lpReOpenBuff->szPathName);
        return 0;
    }

    if ((uStyle & OF_EXIST) && !(uStyle & OF_CREATE))
    {
        DWORD dwAttributes = GetFileAttributesA(lpReOpenBuff->szPathName);

        switch (dwAttributes)
        {
            case INVALID_FILE_ATTRIBUTES: /* File does not exist */
                SetLastError(ERROR_FILE_NOT_FOUND);
                lpReOpenBuff->nErrCode = (WORD) ERROR_FILE_NOT_FOUND;
                return -1;

            case FILE_ATTRIBUTE_DIRECTORY:
                SetLastError(ERROR_ACCESS_DENIED);
                lpReOpenBuff->nErrCode = (WORD) ERROR_ACCESS_DENIED;
                return -1;

            default:
                lpReOpenBuff->cBytes = sizeof(OFSTRUCT);
                return 1;
        }
    }
    lpReOpenBuff->cBytes = sizeof(OFSTRUCT);
	if ((uStyle & OF_CREATE) == OF_CREATE)
	{
		DWORD Sharing;
		switch (uStyle & 0x70)
		{
			case OF_SHARE_EXCLUSIVE: Sharing = 0; break;
			case OF_SHARE_DENY_WRITE: Sharing = FILE_SHARE_READ; break;
			case OF_SHARE_DENY_READ: Sharing = FILE_SHARE_WRITE; break;
			case OF_SHARE_DENY_NONE:
			case OF_SHARE_COMPAT:
			default:
				Sharing = FILE_SHARE_READ | FILE_SHARE_WRITE;
		}
		return (HFILE)(ULONG_PTR) CreateFileA (lpFileName,
		                            GENERIC_READ | GENERIC_WRITE,
		                            Sharing,
		                            NULL,
		                            CREATE_ALWAYS,
		                            FILE_ATTRIBUTE_NORMAL,
		                            0);
	}

	RtlInitAnsiString (&FileName, (LPSTR)lpFileName);

	/* convert ansi (or oem) string to unicode */
	if (bIsFileApiAnsi)
		RtlAnsiStringToUnicodeString (&FileNameU, &FileName, TRUE);
	else
		RtlOemStringToUnicodeString (&FileNameU, &FileName, TRUE);

	Len = SearchPathW (NULL,
	                   FileNameU.Buffer,
        	           NULL,
	                   OFS_MAXPATHNAME,
	                   PathNameW,
        	           &FilePart);

	RtlFreeUnicodeString(&FileNameU);

	if (Len == 0 || Len > OFS_MAXPATHNAME)
	{
		lpReOpenBuff->nErrCode = (WORD)GetLastError();
		return HFILE_ERROR;
	}

    if (uStyle & OF_DELETE)
    {
        if (!DeleteFileW(PathNameW))
		{
			lpReOpenBuff->nErrCode = (WORD)GetLastError();
			return HFILE_ERROR;
		}
        TRACE("(%s): OF_DELETE return = OK\n", lpFileName);
        return TRUE;
    }

	FileName.Buffer = lpReOpenBuff->szPathName;
	FileName.Length = 0;
	FileName.MaximumLength = OFS_MAXPATHNAME;

	RtlInitUnicodeString(&FileNameU, PathNameW);

	/* convert unicode string to ansi (or oem) */
	if (bIsFileApiAnsi)
		RtlUnicodeStringToAnsiString (&FileName, &FileNameU, FALSE);
	else
		RtlUnicodeStringToOemString (&FileName, &FileNameU, FALSE);

	if (!RtlDosPathNameToNtPathName_U (PathNameW,
					   &FileNameString,
					   NULL,
					   NULL))
	{
		return HFILE_ERROR;
	}

	// FILE_SHARE_READ
	// FILE_NO_INTERMEDIATE_BUFFERING

    InitializeObjectAttributes(&ObjectAttributes,
                               &FileNameString,
                               OBJ_CASE_INSENSITIVE | OBJ_INHERIT,
                               NULL,
                               NULL);

	errCode = NtOpenFile (&FileHandle,
	                      GENERIC_READ | SYNCHRONIZE,
	                      &ObjectAttributes,
	                      &IoStatusBlock,
	                      FILE_SHARE_READ,
	                      FILE_NON_DIRECTORY_FILE | FILE_SYNCHRONOUS_IO_NONALERT);

	RtlFreeHeap(RtlGetProcessHeap(), 0, FileNameString.Buffer);

	lpReOpenBuff->nErrCode = (WORD)RtlNtStatusToDosError(errCode);

	if (!NT_SUCCESS(errCode))
	{
		BaseSetLastNTError (errCode);
		return HFILE_ERROR;
	}

	if (uStyle & OF_EXIST)
	{
		NtClose(FileHandle);
		return (HFILE)1;
	}

	return (HFILE)(ULONG_PTR)FileHandle;
}

/*
 * @unimplemented
 */
BOOL
WINAPI
OpenDataFile(HANDLE hFile, DWORD dwUnused)
{
    STUB;
    return FALSE;
}

/*
 * @unimplemented
 */
HANDLE
WINAPI
ReOpenFile(IN HANDLE hOriginalFile,
           IN DWORD dwDesiredAccess,
           IN DWORD dwShareMode,
           IN DWORD dwFlags)
{
   STUB;
   return INVALID_HANDLE_VALUE;
}

/* EOF */
```
