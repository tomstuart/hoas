require 'rspec/expectations'
include RSpec::Matchers

class Parser
  def initialize(builder)
    self.builder = builder
  end

  def parse(string)
    self.string = string
    parse_everything
  end

  private

  attr_accessor :builder
  attr_reader :string

  def string=(string)
    @string = string.strip
  end

  def parse_everything
    expression = parse_expression
    read %r{\z}

    expression
  end

  def parse_expression
    parse_applications
  end

  def parse_applications
    expression = parse_term

    until can_read? %r{\)|\z} do
      expression = builder.build_application(expression, parse_term)
    end

    expression
  end

  def parse_term
    if can_read? %r{\(}
      parse_brackets
    elsif can_read? %r{[λ^\\]}
      parse_abstraction
    elsif can_read? %r{[a-z]+}
      parse_variable
    else
      complain
    end
  end

  def parse_brackets
    read %r{\(}
    expression = parse_expression
    read %r{\)}

    expression
  end

  def parse_abstraction
    read %r{[λ^\\]}
    parameter = read_name
    read %r{\.}
    body = parse_expression

    builder.build_abstraction(parameter, body)
  end

  def parse_variable
    name = read_name

    builder.build_variable(name)
  end

  def read_name
    read %r{[a-z]+}
  end

  def can_read?(pattern)
    !try_match(pattern).nil?
  end

  def read(pattern)
    match = try_match(pattern) || complain(pattern)
    self.string = match.post_match
    match.to_s
  end

  def try_match(pattern)
    /\A#{pattern}/.match(string)
  end

  def complain(expected = nil)
    complaint = "unexpected #{string.slice(0)}"
    complaint << ", expected #{expected.inspect}" if expected

    raise complaint
  end
end

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

class Builder
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

term = parse '(λx.x) ((λx.x) λz.(λx.x) z)'
expect(term).to look_like '((λa.a) ((λb.b) (λc.((λd.d) c))))'
expect(eval_once(term)).to look_like '((λa.a) (λb.((λc.c) b)))'
expect(eval_once(eval_once(term))).to look_like '(λa.((λb.b) a))'
expect{eval_once(eval_once(eval_once(term)))}.to raise_error NoRuleApplies
