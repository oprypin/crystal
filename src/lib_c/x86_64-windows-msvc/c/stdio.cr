require "./stddef"

@[Link("legacy_stdio_definitions")]
lib LibC
  fun printf(format : Char*, ...) : Int
  fun rename(old : Char*, new : Char*) : Int
  fun snprintf(buffer : Char*, count : SizeT, format : Char*, ...) : Int
  fun vfprintf(stream : Void*, format : Char*, ap : VaList) : Int
  fun dprintf = __crystal_dprintf(fd : Int, format : Char*, ...) : Int
  fun _fdopen(fd : Int, mode : Char*) : Void*
  fun fflush(stream : Void*) : Int
end

fun __crystal_dprintf(fd : LibC::Int, format : LibC::Char*, ...) : LibC::Int
  f = LibC._fdopen(fd, "w")
  if f.nil?
    return -1
  end
  res : LibC::Int = 0
  VaList.open do |varargs|
    res = LibC.vfprintf(f, format, varargs)
  end
  LibC.fflush(f)
  res
end
