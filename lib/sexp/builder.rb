module SExp
  class Builder
    def build_abstraction(parameter, body)
      [:abs, parameter, body]
    end

    def build_application(left, right)
      [:app, left, right]
    end

    def build_variable(name)
      [:var, name]
    end
  end
end
