require 'hoas'
require 'sexp'

RSpec.describe 'pretty-printing' do
  RSpec::Matchers.define :look_like do |expected|
    match do |actual|
      HOAS.stringify(actual) == expected
    end
  end

  let(:omega) { HOAS.parse '(λx.x x) λx.x x' }

  specify { expect(omega).to look_like '((λa.(a a)) (λb.(b b)))' }
end

RSpec.describe 'evaluation' do
  RSpec::Matchers.define :be_the_term do |expected|
    match do |actual|
      SExp.alpha_equivalent?(SExp.parse(HOAS.stringify(actual)), SExp.parse(expected))
    end
  end

  let(:term) { HOAS.parse '(λx.x) ((λx.x) λz.(λx.x) z)' }

  specify { expect(term).to be_the_term '(λx.x) ((λx.x) λz.(λx.x) z)' }
  specify { expect(HOAS.eval_once(term)).to be_the_term '(λx.x) λz.(λx.x) z' }
  specify { expect(HOAS.eval_once(HOAS.eval_once(term))).to be_the_term 'λz.(λx.x) z' }
  specify { expect{HOAS.eval_once(HOAS.eval_once(HOAS.eval_once(term)))}.to raise_error HOAS::NoRuleApplies }
end
