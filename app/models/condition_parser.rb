class ConditionParser
  def initialize(expression)
    @tokens = expression.split(" ")
    @position = 0
  end

  def current_token
    @tokens[@position]
  end

  def move_next
    @position += 1
  end

  def parse_token_value(&block)
    if(current_token == '(')
      move_next
      parse(&block)
    else
      block_given? ? block.call(current_token) : current_token
    end
  end

  def parse(&block)
    token_value = parse_token_value(&block)
    move_next
    if(current_token == 'and' || current_token == 'or')
      logic_type = current_token
      move_next
      token_value = { "#{logic_type}" => [token_value, parse(&block) ] }
    end
    token_value
  end
end
