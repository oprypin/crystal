require "spec"
require "llvm"

LLVM.init_x86

private def abi
  triple = LLVM.default_target_triple
  target = LLVM::Target.from_triple(triple)
  machine = target.create_target_machine(triple)
  LLVM::ABI::X86_64.new(machine)
end

class LLVM::ABI
  describe X86_64 do
    describe "align" do
      it "for integer" do
        assert abi.align(LLVM::Int1).is_a?(::Int32)
        assert abi.align(LLVM::Int1) == 1
        assert abi.align(LLVM::Int8) == 1
        assert abi.align(LLVM::Int16) == 2
        assert abi.align(LLVM::Int32) == 4
        assert abi.align(LLVM::Int64) == 8
      end

      it "for pointer" do
        assert abi.align(LLVM::Int8.pointer) == 8
      end

      it "for float" do
        assert abi.align(LLVM::Float) == 4
      end

      it "for double" do
        assert abi.align(LLVM::Double) == 8
      end

      it "for struct" do
        assert abi.align(LLVM::Type.struct([LLVM::Int32, LLVM::Int64])) == 8
        assert abi.align(LLVM::Type.struct([LLVM::Int8, LLVM::Int16])) == 2
      end

      it "for packed struct" do
        assert abi.align(LLVM::Type.struct([LLVM::Int32, LLVM::Int64], packed: true)) == 1
      end

      it "for array" do
        assert abi.align(LLVM::Int16.array(10)) == 2
      end
    end

    describe "size" do
      it "for integer" do
        assert abi.size(LLVM::Int1).is_a?(::Int32)
        assert abi.size(LLVM::Int1) == 1
        assert abi.size(LLVM::Int8) == 1
        assert abi.size(LLVM::Int16) == 2
        assert abi.size(LLVM::Int32) == 4
        assert abi.size(LLVM::Int64) == 8
      end

      it "for pointer" do
        assert abi.size(LLVM::Int8.pointer) == 8
      end

      it "for float" do
        assert abi.size(LLVM::Float) == 4
      end

      it "for double" do
        assert abi.size(LLVM::Double) == 8
      end

      it "for struct" do
        assert abi.size(LLVM::Type.struct([LLVM::Int32, LLVM::Int64])) == 16
        assert abi.size(LLVM::Type.struct([LLVM::Int16, LLVM::Int8])) == 4
        assert abi.size(LLVM::Type.struct([LLVM::Int32, LLVM::Int8, LLVM::Int8])) == 8
      end

      it "for packed struct" do
        assert abi.size(LLVM::Type.struct([LLVM::Int32, LLVM::Int64], packed: true)) == 12
      end

      it "for array" do
        assert abi.size(LLVM::Int16.array(10)) == 20
      end
    end

    describe "abi_info" do
      it "does with primitives" do
        arg_types = [LLVM::Int32, LLVM::Int64]
        return_type = LLVM::Int8
        info = abi.abi_info(arg_types, return_type, true)
        assert info.arg_types.size == 2

        assert info.arg_types[0] == ArgType.direct(LLVM::Int32)
        assert info.arg_types[1] == ArgType.direct(LLVM::Int64)
        assert info.return_type == ArgType.direct(LLVM::Int8)
      end

      it "does with structs less than 64 bits" do
        str = LLVM::Type.struct([LLVM::Int8, LLVM::Int16])
        arg_types = [str]
        return_type = str

        info = abi.abi_info(arg_types, return_type, true)
        assert info.arg_types.size == 1

        assert info.arg_types[0] == ArgType.direct(str, cast: LLVM::Type.struct([LLVM::Int64]))
        assert info.return_type == ArgType.direct(str, cast: LLVM::Type.struct([LLVM::Int64]))
      end

      it "does with structs between 64 and 128 bits" do
        str = LLVM::Type.struct([LLVM::Int64, LLVM::Int16])
        arg_types = [str]
        return_type = str

        info = abi.abi_info(arg_types, return_type, true)
        assert info.arg_types.size == 1

        assert info.arg_types[0] == ArgType.direct(str, cast: LLVM::Type.struct([LLVM::Int64, LLVM::Int64]))
        assert info.return_type == ArgType.direct(str, cast: LLVM::Type.struct([LLVM::Int64, LLVM::Int64]))
      end

      it "does with structs between 64 and 128 bits" do
        str = LLVM::Type.struct([LLVM::Int64, LLVM::Int64, LLVM::Int8])
        arg_types = [str]
        return_type = str

        info = abi.abi_info(arg_types, return_type, true)
        assert info.arg_types.size == 1

        assert info.arg_types[0] == ArgType.indirect(str, Attribute::ByVal)
        assert info.return_type == ArgType.indirect(str, Attribute::StructRet)
      end
    end
  end
end
