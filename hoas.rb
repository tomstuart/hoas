require 'rspec/expectations'
include RSpec::Matchers

Abs = Struct.new(:proc) do
  def fold(abs:, app:)
    abs.(-> value { proc.(Result.new(value)).fold(abs: abs, app: app) })
  end
end

App = Struct.new(:left, :right) do
  def fold(abs:, app:)
    app.(left.fold(abs: abs, app: app), right.fold(abs: abs, app: app))
  end
end

Result = Struct.new(:value) do
  def fold(abs:, app:)
    value
  end
end

def abs(*args)
  Abs.new(*args)
end

def app(*args)
  App.new(*args)
end

def all_names
  Enumerator.new do |yielder|
    name = 'a'

    loop do
      yielder.yield name
      name = name.succ
    end
  end
end

def stringify(term)
  names = all_names

  term.fold \
    abs: -> f { x = names.next; "(λ#{x}.#{f.(x)})" },
    app: -> l, r { "#{l} #{r}" }
end

RSpec::Matchers.define :look_like do |expected|
  match do |actual|
    stringify(actual) == expected
  end
end

omega = app(abs(-> x { app(x, x) }), abs(-> x { app(x, x) }))
expect(omega).to look_like '(λa.a a) (λb.b b)'

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

id = abs(-> x { x })
term = app(id, app(id, abs(-> z { app(id, z) })))
expect(term).to look_like '(λa.a) (λb.b) (λc.(λd.d) c)'
expect(eval_once(term)).to look_like '(λa.a) (λb.(λc.c) b)'
expect(eval_once(eval_once(term))).to look_like '(λa.(λb.b) a)'
expect{eval_once(eval_once(eval_once(term)))}.to raise_error NoRuleApplies
