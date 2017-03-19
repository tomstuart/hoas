require 'parser'
require 'hoas/ast'
require 'hoas/builder'

module HOAS
  include AST

  def self.parse(string)
    Parser.new(Builder.new).parse(string).({})
  end

  NoRuleApplies = Class.new(StandardError)

  def self.eval_once(term)
    raise NoRuleApplies unless term.is_a?(App) && term.left.is_a?(Abs)
    left, right = term.left, term.right

    if right.is_a?(Abs)
      left.proc.(right)
    else
      App.new(left, eval_once(right))
    end
  end
end
