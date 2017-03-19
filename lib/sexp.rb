require 'parser'
require 'sexp/builder'

module SExp
  def self.parse(string)
    Parser.new(Builder.new).parse(string)
  end

  def self.alpha_equivalent?(a, b, a_env = {}, b_env = {})
    a_type, *a_args = a
    b_type, *b_args = b
    return false unless a_type == b_type

    case a_type
    when :abs
      a_parameter, a_body = a_args
      b_parameter, b_body = b_args
      variable = Object.new

      alpha_equivalent?(a_body, b_body, a_env.merge(a_parameter => variable), b_env.merge(b_parameter => variable))
    when :app
      a_left, a_right = a_args
      b_left, b_right = b_args

      alpha_equivalent?(a_left, b_left, a_env, b_env) && alpha_equivalent?(a_right, b_right, a_env, b_env)
    when :var
      a_name, = a_args
      b_name, = b_args

      a_env.has_key?(a_name) == b_env.has_key?(b_name) &&
        a_env.fetch(a_name, a_name) == b_env.fetch(b_name, b_name)
    end
  end
end
