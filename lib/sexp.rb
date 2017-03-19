require 'parser'
require 'sexp/builder'

module SExp
  def self.parse(string)
    Parser.new(Builder.new).parse(string)
  end
end
