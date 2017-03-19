module HOAS
  module AST
    Abs = Struct.new(:proc) do
      def fold(abs:, app:)
        abs.(-> value { proc.(Hole.new(value)).fold(abs: abs, app: app) })
      end
    end

    App = Struct.new(:left, :right) do
      def fold(abs:, app:)
        app.(left.fold(abs: abs, app: app), right.fold(abs: abs, app: app))
      end
    end

    Hole = Struct.new(:value) do
      def fold(abs:, app:)
        value
      end
    end
  end
end
