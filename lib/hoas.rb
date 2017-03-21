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
      "(λ#{name}.#{stringify(term.proc.(Hole.new(name)), names)})"
    when App
      "(#{stringify(term.left, names)} #{stringify(term.right, names)})"
    when Hole
      term.value
    end
  end

  NoRuleApplies = Class.new(StandardError)

  def self.eval(term)
    raise NoRuleApplies unless term.is_a?(App)
    left, right = term.left, term.right

    if left.is_a?(App)
      App.new(eval(left), right)
    elsif right.is_a?(App)
      App.new(left, eval(right))
    else
      left.proc.(right)
    end
  end
end
