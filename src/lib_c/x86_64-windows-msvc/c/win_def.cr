require "c/basetsd"

lib LibC
  alias WORD = UInt16
  alias BOOL = Int32
  alias BYTE = UChar

  alias HWND = Void*

  alias WPARAM = UINT_PTR
  alias LPARAM = LONG_PTR
end
