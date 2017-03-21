require 'parser'
require 'hoas/ast'
require 'hoas/builder'

module HOAS
  include AST

  def self.parse(string)
    Parser.new(Builder.new).parse(string).({})
  end

  def self.all_names
    0.step.lazy.map { |n| n.times.inject('a') { |s| s.succ } }
  end

  def self.stringify(term, names = all_names)
    case term
    when Abs
      name = names.next
      "(λ#{name}.#{stringify(term.proc.call(Hole.new(name)), names)})"
    when App
      "(#{stringify(term.left, names)} #{stringify(term.right, names)})"
    when Hole
      term.value
    end
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
