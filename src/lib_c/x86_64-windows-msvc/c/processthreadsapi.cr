require "./basetsd"
require "./int_safe"

lib LibC
  fun GetCurrentThreadStackLimits(lowLimit : ULONG_PTR*, highLimit : ULONG_PTR*) : Void

  fun GetProcessId(process : HANDLE) : DWORD
  fun GetCurrentProcessId : DWORD
  fun OpenProcess(dwDesiredAccess : DWORD, bInheritHandle : BOOL, dwProcessId : DWORD) : HANDLE
  fun GetExitCodeProcess(hProcess : HANDLE, lpExitCode : DWORD*) : BOOL
  fun CreateProcessW(lpApplicationName : LPWSTR, lpCommandLine : LPWSTR,
                     lpProcessAttributes : Void*, lpThreadAttributes : Void*,
                     bInheritHandles : BOOL, dwCreationFlags : DWORD,
                     lpEnvironment : Void*, lpCurrentDirectory : LPWSTR,
                     lpStartupInfo : STARTUPINFOW*, lpProcessInformation : PROCESS_INFORMATION*) : BOOL

  struct STARTUPINFOW
    cb : DWORD
    lpReserved : LPWSTR
    lpDesktop : LPWSTR
    lpTitle : LPWSTR
    dwX : DWORD
    dwY : DWORD
    dwXSize : DWORD
    dwYSize : DWORD
    dwXCountChars : DWORD
    dwYCountChars : DWORD
    dwFillAttribute : DWORD
    dwFlags : DWORD
    wShowWindow : WORD
    cbReserved2 : WORD
    lpReserved2 : Void*
    hStdInput : HANDLE
    hStdOutput : HANDLE
    hStdError : HANDLE
  end

  struct PROCESS_INFORMATION
    hProcess : HANDLE
    hThread : HANDLE
    dwProcessId : DWORD
    dwThreadId : DWORD
  end

  fun GetCurrentProcess : HANDLE
end
