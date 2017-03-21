module HOAS
  module AST
    Abs = Struct.new(:proc)
    App = Struct.new(:left, :right)
    Hole = Struct.new(:value)
  end
end
