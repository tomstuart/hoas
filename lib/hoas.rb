require 'parser'
require 'hoas/builder'

module HOAS
  def self.parse(string)
    Parser.new(Builder.new).parse(string).({})
  end
end
