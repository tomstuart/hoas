require 'hoas/ast'

module HOAS
  class Builder
    include AST

    def build_abstraction(parameter, body)
      -> env { Abs.new(-> x { body.(env.merge(parameter => x)) }) }
    end

    def build_application(left, right)
      -> env { App.new(left.(env), right.(env)) }
    end

    def build_variable(name)
      -> env { env[name] }
    end
  end
end
