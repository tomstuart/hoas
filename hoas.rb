require 'rspec/expectations'
include RSpec::Matchers

Abs = Struct.new(:proc)
App = Struct.new(:left, :right)
Hole = Struct.new(:value)

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

def stringify(term, names = all_names)
  case term
  when App
    "#{stringify(term.left, names)} #{stringify(term.right, names)}"
  when Abs
    name = names.next
    "(λ#{name}.#{stringify(term.proc.call(Hole.new(name)), names)})"
  when Hole
    term.value
  end
end

RSpec::Matchers.define :look_like do |expected|
  match do |actual|
    stringify(actual) == expected
  end
end

omega = app(abs(-> x { app(x, x) }), abs(-> x { app(x, x) }))
expect(omega).to look_like '(λa.a a) (λb.b b)'
