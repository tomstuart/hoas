require 'rspec/expectations'
include RSpec::Matchers

require 'hoas'
require 'sexp'

RSpec::Matchers.define :be_alpha_equivalent_to do |expected|
  match do |actual|
    SExp.alpha_equivalent?(SExp.parse(expected), SExp.parse(actual))
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

omega = HOAS.parse '(λx.x x) λx.x x'
expect(omega).to look_like '((λa.(a a)) (λb.(b b)))'

RSpec::Matchers.define :be_the_term do |expected|
  match do |actual|
    SExp.alpha_equivalent?(SExp.parse(stringify(actual)), SExp.parse(expected))
  end
end

term = HOAS.parse '(λx.x) ((λx.x) λz.(λx.x) z)'
expect(term).to be_the_term '(λx.x) ((λx.x) λz.(λx.x) z)'
expect(HOAS.eval_once(term)).to be_the_term '(λx.x) λz.(λx.x) z'
expect(HOAS.eval_once(HOAS.eval_once(term))).to be_the_term 'λz.(λx.x) z'
expect{HOAS.eval_once(HOAS.eval_once(HOAS.eval_once(term)))}.to raise_error HOAS::NoRuleApplies
