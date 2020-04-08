# Libloaderapi.h
require "c/win_def"

lib LibC
  alias HMODULE = Void*

  fun GetModuleFileNameW(
    hModule : HMODULE,
    lpFilename : LPWSTR,
    nSize : DWORD
  ) : DWORD
end
