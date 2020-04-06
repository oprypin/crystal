require "./stddef"

@[Link("legacy_stdio_definitions")]
lib LibC
  fun printf(format : Char*, ...) : Int
  fun rename(old : Char*, new : Char*) : Int
  fun snprintf(buffer : Char*, count : SizeT, format : Char*, ...) : Int

  P_WAIT    = 0
  P_NOWAIT  = 1
  P_OVERLAY = 2
  P_NOWAITO = 3
  P_DETACH  = 4

  fun _wspawnvp(mode : Int, cmdname : WCHAR*, argv : WCHAR**) : HANDLE
end
