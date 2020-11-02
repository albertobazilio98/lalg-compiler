class LexicalAnalyser

  def initialize file_name
    @lines = File.open('test.txt').readlines
  end

  @blank_spaces = [' ', '\n', '\t']
  @not_allowed_characters = ['!', '"', '#', '$', '%', '&', '\'', '?', '@', '[', ']', '\\', '^', '_', '`']
  @special_characters = [';', '(', ')', ',', ':', '=', '>', '<', '+', '-', '*', '/']
  @compound_special_characters = ['<>', '>=', '<=', ':=']

  def start_analysis
    @token_accumulator = ''
    @token_guess = nil
    @current_character = nil
    @tokens = []
    @commentary = false

    @lines.each do |line, line_index|
      @line = line
      @line_index = line_index
      line.each_character do |character, character_index|
        @character = character
        @character_index = character_index

        @current_character = character
        next if is_commentary?
        next if is_integer?
        next if is_not_allowed_character?
        add_token @token_accumulator, @token_guess if is_spacer?
      end
    end
  end

  private

  def is_commentary?
    return @commentary = true if @current_character == '{'
    return @commentary = false if @current_character == '}'

    @commentary
  end

  def is_not_allowed_character?
    return false unless @not_allowed_characters.include? @character

    add_token @token_accumulator, @token_guess
    add_error @character, 'character not allowed'
    true
  end

  def is_special_character?
    return false unless @special_characters.include? @character
    return check_special_character_token if @token_guess == 'special_character'

    add_token @token_accumulator, @token_guess
    @token_guess = 'special_character'
    @token_accumulator = @character

    true
  end

  def check_special_character_token
    compound_token = @token_accumulator + @character
    return add_token compound_token, 'special_character' if @compound_special_characters.include? compound_token
    add_token @token_accumulator, 'special_character'
    add_token @character, 'special_character'
  end

  def is_operator?

  end

  def is_identifier

  end

  def is_integer?
    return false unless @character.is_numeric?
    if token_guess == 'integer'
      @token_accumulator << @character
      return true
    end
    if token_guess.nil? 
      @token_accumulator << @character
      @token_guess = 'integer'
      return true
    end

    false
  end

  def is_real_number?
    return false unless @character.is_numeric? or @character == '.'
    if @character == '.'
      if @token_guess == 'integer'
        @token_accumulator << @character
        @token_guess = 'malformatted_real'
        return true
      end
      if @token_guess == 'real' or @token_guess == 'malformatted_real'
        @token_accumulator << @character
        add_error @token_accumulator, 'malformatted_real'
        return true
      end
    end
    true
  end

  def is_spacer?
    return false unless @blank_spaces.include? @current_character
    add_token @token_accumulator, @token_guess unless @token_guess.nil?
    true
  end

  def clear_token_accumulator
    @token_guess = nil
    @token_accumulator = ''
  end

  def add_token token, description
    return add_error token, description if description == 'malformatted_real'
    @tokens << { token: token, description: description == 'special_character' ? token : description }
    clear_token_accumulator

    true
  end

  def add_error token, description
    @error << { token: token, description: description, line: @line_index }
  end
end

class String
  def is_numeric?
    not (self =~ /[0-9]/).nil?
  end
 
  def is_letter?
    not (self =~ /[A-Za-z]/).nil?
  end

end