lib LibC
  {% if flag?(:bits64) %}
    alias ULONG_PTR = UInt64
    alias LONG_PTR = Int64
    alias UINT_PTR = UInt64
  {% else %}
    alias ULONG_PTR = ULong
    alias LONG_PTR = Long
    alias UINT_PTR = UInt
  {% end %}
end
