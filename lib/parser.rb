class Parser
  def initialize(builder)
    self.builder = builder
  end

  def parse(string)
    self.string = string
    parse_everything
  end

  private

  attr_accessor :builder
  attr_reader :string

  def string=(string)
    @string = string.strip
  end

  def parse_everything
    expression = parse_expression
    read %r{\z}

    expression
  end

  def parse_expression
    parse_applications
  end

  def parse_applications
    expression = parse_term

    until can_read? %r{\)|\z} do
      expression = builder.build_application(expression, parse_term)
    end

    expression
  end

  def parse_term
    if can_read? %r{\(}
      parse_brackets
    elsif can_read? %r{[λ^\\]}
      parse_abstraction
    elsif can_read? %r{[a-z]+}
      parse_variable
    else
      complain
    end
  end

  def parse_brackets
    read %r{\(}
    expression = parse_expression
    read %r{\)}

    expression
  end

  def parse_abstraction
    read %r{[λ^\\]}
    parameter = read_name
    read %r{\.}
    body = parse_expression

    builder.build_abstraction(parameter, body)
  end

  def parse_variable
    name = read_name

    builder.build_variable(name)
  end

  def read_name
    read %r{[a-z]+}
  end

  def can_read?(pattern)
    !try_match(pattern).nil?
  end

  def read(pattern)
    match = try_match(pattern) || complain(pattern)
    self.string = match.post_match
    match.to_s
  end

  def try_match(pattern)
    /\A#{pattern}/.match(string)
  end

  def complain(expected = nil)
    complaint = "unexpected #{string.slice(0)}"
    complaint << ", expected #{expected.inspect}" if expected

    raise complaint
  end
end
