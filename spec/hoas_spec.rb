require 'hoas'
require 'sexp'

include HOAS::AST

RSpec.describe 'pretty-printing' do
  RSpec::Matchers.define :look_like do |expected|
    match do |actual|
      HOAS.stringify(actual) == expected
    end
  end

  let(:omega) {
    App.new(
      Abs.new(-> x { App.new(x, x) }),
      Abs.new(-> x { App.new(x, x) })
    )
  }

  specify { expect(omega).to look_like '((λa.(a a)) (λb.(b b)))' }
end

RSpec.describe 'evaluation' do
  RSpec::Matchers.define :be_the_term do |expected|
    match do |actual|
      SExp.alpha_equivalent?(SExp.parse(HOAS.stringify(actual)), SExp.parse(expected))
    end
  end

  describe 'a simple term' do
    let(:term) {
      App.new(
        Abs.new(-> x {
          Abs.new(-> y {
            App.new(x, y)
          })
        }),
        Abs.new(-> z { z })
      )
    }

    specify { expect(term).to be_the_term '(λx.λy.x y) λz.z' }
    specify { expect(HOAS.eval_once(term)).to be_the_term 'λy.(λz.z) y' }
    specify { expect { HOAS.eval_once(HOAS.eval_once(term)) }.to raise_error HOAS::NoRuleApplies }
  end

  describe 'a more complicated term' do
    let(:term) { HOAS.parse '(λx.x) ((λx.x) λz.(λx.x) z)' }

    specify { expect(term).to be_the_term '(λx.x) ((λx.x) λz.(λx.x) z)' }
    specify { expect(HOAS.eval_once(term)).to be_the_term '(λx.x) λz.(λx.x) z' }
    specify { expect(HOAS.eval_once(HOAS.eval_once(term))).to be_the_term 'λz.(λx.x) z' }
    specify { expect { HOAS.eval_once(HOAS.eval_once(HOAS.eval_once(term))) }.to raise_error HOAS::NoRuleApplies }
  end
end
