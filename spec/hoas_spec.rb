require 'hoas'
require 'sexp'

RSpec.describe 'alpha equivalence' do
  RSpec::Matchers.define :be_alpha_equivalent_to do |expected|
    match do |actual|
      SExp.alpha_equivalent?(SExp.parse(expected), SExp.parse(actual))
    end
  end

  specify { expect('λx.x').to be_alpha_equivalent_to 'λx.x' }
  specify { expect('λx.x').not_to be_alpha_equivalent_to 'λy.x' }
  specify { expect('λx.x').to be_alpha_equivalent_to 'λy.y' }
  specify { expect('λx.x y').not_to be_alpha_equivalent_to 'λy.y y' }
  specify { expect('λx.x y').not_to be_alpha_equivalent_to 'λy.y z' }
  specify { expect('λx.x z').to be_alpha_equivalent_to 'λy.y z' }
  specify { expect('λx.x z').not_to be_alpha_equivalent_to 'λx.x y' }
  specify { expect('λx.λy.x y z').to be_alpha_equivalent_to 'λy.λx.y x z' }
  specify { expect('(λx.x) λy.y').to be_alpha_equivalent_to '(λy.y) λx.x' }
  specify { expect('(λx.x) λy.y').not_to be_alpha_equivalent_to '(λy.y) λx.y' }
  specify { expect('λx.λy.λx.x y z').to be_alpha_equivalent_to 'λy.λy.λx.x y z' }
  specify { expect('λx.λy.λx.x y z').to be_alpha_equivalent_to 'λy.λx.λy.y x z' }
  specify { expect('λx.λy.λx.x y z').to be_alpha_equivalent_to 'λx.λx.λy.y x z' }
end

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
