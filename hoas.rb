require 'rspec/expectations'
include RSpec::Matchers

Abs = Struct.new(:proc) do
  def fold(abs:, app:)
    abs.(-> result { proc.(Hole.new(result)).fold(abs: abs, app: app) })
  end
end

App = Struct.new(:left, :right) do
  def fold(abs:, app:)
    app.(left.fold(abs: abs, app: app), right.fold(abs: abs, app: app))
  end
end

Hole = Struct.new(:value) do
  def fold(abs:, app:)
    value
  end
end

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

def stringify(term)
  names = all_names

  term.fold \
    abs: -> f { x = names.next; "(λ#{x}.#{f.(x)})" },
    app: -> l, r { "#{l} #{r}" }
end

RSpec::Matchers.define :look_like do |expected|
  match do |actual|
    stringify(actual) == expected
  end
end

omega = app(abs(-> x { app(x, x) }), abs(-> x { app(x, x) }))
expect(omega).to look_like '(λa.a a) (λb.b b)'
