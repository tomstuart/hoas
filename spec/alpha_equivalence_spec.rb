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
