require 'rspec/expectations'
include RSpec::Matchers

require 'parser'
require 'hoas/builder'
require 'hoas/ast'
include HOAS
include HOAS::AST

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
