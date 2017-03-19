require 'rspec/expectations'
include RSpec::Matchers

require 'parser'
require 'hoas/builder'
require 'hoas/ast'
include HOAS
include HOAS::AST

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

def parse_to_sexp(string)
  Parser.new(SExp::Builder.new).parse(string)
end

def alpha_equivalent?(a, b, a_env = {}, b_env = {})
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

RSpec::Matchers.define :be_alpha_equivalent_to do |expected|
  match do |actual|
    alpha_equivalent?(parse_to_sexp(expected), parse_to_sexp(actual))
  end
end

expect('λx.x').to be_alpha_equivalent_to 'λx.x'
expect('λx.x').not_to be_alpha_equivalent_to 'λy.x'
expect('λx.x').to be_alpha_equivalent_to 'λy.y'
expect('λx.x y').not_to be_alpha_equivalent_to 'λy.y y'
expect('λx.x y').not_to be_alpha_equivalent_to 'λy.y z'
expect('λx.x z').to be_alpha_equivalent_to 'λy.y z'
expect('λx.x z').not_to be_alpha_equivalent_to 'λx.x y'
expect('λx.λy.x y z').to be_alpha_equivalent_to 'λy.λx.y x z'
expect('(λx.x) λy.y').to be_alpha_equivalent_to '(λy.y) λx.x'
expect('(λx.x) λy.y').not_to be_alpha_equivalent_to '(λy.y) λx.y'
expect('λx.λy.λx.x y z').to be_alpha_equivalent_to 'λy.λy.λx.x y z'
expect('λx.λy.λx.x y z').to be_alpha_equivalent_to 'λy.λx.λy.y x z'
expect('λx.λy.λx.x y z').to be_alpha_equivalent_to 'λx.λx.λy.y x z'

def parse(string)
  Parser.new(Builder.new).parse(string).({})
end

def all_names
  0.step.lazy.map { |n| n.times.inject('a') { |s| s.succ } }
end

def stringify(term)
  names = all_names

  term.fold \
    abs: -> f { x = names.next; "(λ#{x}.#{f.(x)})" },
    app: -> l, r { "(#{l} #{r})" }
end

RSpec::Matchers.define :look_like do |expected|
  match do |actual|
    stringify(actual) == expected
  end
end

omega = parse '(λx.x x) λx.x x'
expect(omega).to look_like '((λa.(a a)) (λb.(b b)))'

NoRuleApplies = Class.new(StandardError)

def eval_once(term)
  raise NoRuleApplies unless term.is_a?(App) && term.left.is_a?(Abs)
  left, right = term.left, term.right

  if right.is_a?(Abs)
    left.proc.(right)
  else
    App.new(left, eval_once(right))
  end
end

RSpec::Matchers.define :be_the_term do |expected|
  match do |actual|
    alpha_equivalent?(parse_to_sexp(stringify(actual)), parse_to_sexp(expected))
  end
end

term = parse '(λx.x) ((λx.x) λz.(λx.x) z)'
expect(term).to be_the_term '(λx.x) ((λx.x) λz.(λx.x) z)'
expect(eval_once(term)).to be_the_term '(λx.x) λz.(λx.x) z'
expect(eval_once(eval_once(term))).to be_the_term 'λz.(λx.x) z'
expect{eval_once(eval_once(eval_once(term)))}.to raise_error NoRuleApplies
