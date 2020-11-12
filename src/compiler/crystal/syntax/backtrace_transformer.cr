require "compiler/crystal/syntax/transformer"

module Crystal
  class BacktraceTransformer < Transformer
    private SRC_ROOT = File.dirname(File.dirname(File.dirname(File.dirname(__FILE__))))

    def transform(node : Def)
      return node if (body = node.body).is_a?(Nop)
      return node unless (location = node.location)
      return node if node.name == "initialize"
      return node if location.filename.to_s.starts_with?(SRC_ROOT)
      body = Expressions.new([body] of ASTNode) unless body.is_a?(Expressions)
      return node if node.receiver && body.expressions.size == 1

      frame = "#{location} in '#{node.name}'"
      fib = Call.new(Path.global("Fiber"), "current")
      body.expressions.unshift(Call.new(fib, "push_backtrace", [StringLiteral.new(frame)] of ASTNode))
      node.body = ExceptionHandler.new(body, ensure: Call.new(fib.clone, "pop_backtrace")).at(location)
      node
    end
  end
end
