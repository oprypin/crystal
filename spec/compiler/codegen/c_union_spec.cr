require "../../spec_helper"

CodeGenUnionString = "lib LibFoo; union Bar; x : Int32; y : Int64; z : Float32; end; end"

describe "Code gen: c union" do
  it "codegens union property default value" do
    assert run("#{CodeGenUnionString}; bar = Pointer(LibFoo::Bar).malloc(1_u64); bar.value.x").to_i == 0
  end

  it "codegens union property default value 2" do
    assert run("#{CodeGenUnionString}; bar = Pointer(LibFoo::Bar).malloc(1_u64); bar.value.z").to_f32 == 0
  end

  it "codegens union property setter 1" do
    assert run("#{CodeGenUnionString}; bar = LibFoo::Bar.new; bar.x = 42; bar.x").to_i == 42
  end

  it "codegens union property setter 2" do
    assert run("#{CodeGenUnionString}; bar = LibFoo::Bar.new; bar.z = 42.0_f32; bar.z").to_f32 == 42.0
  end

  it "codegens union property setter 1 via pointer" do
    assert run("#{CodeGenUnionString}; bar = Pointer(LibFoo::Bar).malloc(1_u64); bar.value.x = 42; bar.value.x").to_i == 42
  end

  it "codegens union property setter 2 via pointer" do
    assert run("#{CodeGenUnionString}; bar = Pointer(LibFoo::Bar).malloc(1_u64); bar.value.z = 42.0_f32; bar.value.z").to_f32 == 42.0
  end

  it "codegens struct inside union" do
    assert run("
      lib LibFoo
        struct Baz
          lele : Int64
          lala : Int32
        end

        union Bar
          x : Int32
          y : Int64
          z : Baz
        end
      end

      a = Pointer(LibFoo::Bar).malloc(1_u64)
      a.value.z = LibFoo::Baz.new
      a.value.z.lala = 10
      a.value.z.lala
      ").to_i == 10
  end

  it "codegens assign c union to union" do
    assert run("
      lib LibFoo
        union Bar
          x : Int32
        end
      end

      bar = LibFoo::Bar.new
      bar.x = 10
      x = bar || nil
      if x
        x.x
      else
        1
      end
      ").to_i == 10
  end

  it "builds union setter with fun type" do
    codegen(%(
      require "prelude"

      lib LibC
        union Foo
          x : ->
        end
      end

      foo = LibC::Foo.new
      foo.x = -> { }
      ))
  end

  it "does to_s" do
    assert run(%(
      require "prelude"

      lib LibNVG
        union Color
          array: Int32
        end
      end

      color = LibNVG::Color.new
      color.to_s
      )).to_string == "LibNVG::Color(@array=0)"
  end

  it "automatically converts numeric type in field assignment" do
    assert run(%(
      lib LibFoo
        union Foo
          x : Int8
        end
      end

      a = 12345

      foo = LibFoo::Foo.new
      foo.x = a
      foo.x
      )).to_i == 57
  end

  it "automatically converts numeric union type in field assignment" do
    assert run(%(
      lib LibFoo
        union Foo
          x : Int8
        end
      end

      a = 12345 || 12346_u16

      foo = LibFoo::Foo.new
      foo.x = a
      foo.x
      )).to_i == 57
  end

  it "automatically converts by invoking to_unsafe" do
    assert run(%(
      lib LibFoo
        union Foo
          x : Int32
        end
      end

      class Foo
        def to_unsafe
          123
        end
      end

      foo = LibFoo::Foo.new
      foo.x = Foo.new
      foo.x
      )).to_i == 123
  end

  it "aligns to the member with biggest align requirements" do
    assert run(%(
      lib LibFoo
        union Foo
          bytes : UInt8[4]
          short : UInt16
        end

        struct Bar
          a : Int8
          b : Foo
        end
      end

      class String
        def to_unsafe
          pointerof(@c)
        end
      end

      str = "00XX0"
      foo = str.to_unsafe.as(LibFoo::Bar*)
      foo.value.b.short.to_i
      )).to_i == 0x5858
  end

  it "fills union type to the max size" do
    assert run(%(
      lib LibFoo
        union Foo
          bytes : UInt8[4]
          short : UInt16
        end

        struct Bar
          a : Int8
          b : Foo
        end
      end

      sizeof(LibFoo::Bar)
      )).to_i == 6
  end

  it "reads union instance var" do
    assert run(%(
      lib LibFoo
        union Foo
          char : Char
          int : Int32
        end
      end

      struct LibFoo::Foo
        def read_int
          @int
        end
      end

      foo = LibFoo::Foo.new
      foo.int = 42
      foo.read_int
      )).to_i == 42
  end
end
