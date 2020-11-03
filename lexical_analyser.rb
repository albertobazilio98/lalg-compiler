class LexicalAnalyser

  def initialize file_name
    @lines = File.open(file_name).readlines

    @blank_spaces = [' ', '\n', '\t']
    @not_allowed_characters = ['!', '"', '#', '$', '%', '&', '\'', '?', '@', '[', ']', '\\', '^', '_', '`']
    @special_characters = [';', '(', ')', ',', ':', '=', '>', '<', '+', '-', '*', '/']
    @compound_special_characters = ['<>', '>=', '<=', ':=']
    @reserved_words = ['read', 'write', 'if', 'then', 'else', 'while', 'do', 'begin', 'end', 'procedure', 'program', 'real', 'integer', 'var']
  end
  
  def start_analysis
    @token_guess = {
      line: nil,
      token: '',
      description: nil
    }
    @accumulator = ''
    @current_character = nil
    @tokens = []
    @commentary = false
    @errors = []

    @lines.each do |line, line_index|
      @line = line
      @line_index = line_index
      line.each_char do |character, character_index|
        puts @token_guess
        @accumulator = @token_guess[:token] + character
        @character = character
        @character_index = character_index

        @current_character = character
        next if is_commentary?
        next if is_not_allowed_character?
        next if (character.is_numeric? or character == '.') && is_number?
        next if is_identifier?

        add_token @token_guess[:token], @token_guess[:description] if is_spacer?
      end
    end
  end

  def tokens
    @tokens
  end

  def errors
    @errors
  end

  private

  def is_commentary?
    return @commentary = true if @current_character == '{'
    return @commentary = false if @current_character == '}'

    @commentary
  end

  def is_not_allowed_character?
    return false unless @not_allowed_characters.include? @character

    add_token @token_guess[:token], @token_guess[:description]
    add_error @character, 'error: character not allowed'

    true
  end

  def is_special_character?
    return false unless @special_characters.include? @character
    return check_special_character_token if @token_guess[:description] == 'special_character'

    add_token @token_guess[:token], @token_guess[:description]
    @token_guess[:description] = 'special_character'
    @token_guess[:token] = @character
    @token_guess[:line] = @line

    true
  end

  def check_special_character_token
    compound_token = @token_guess[:token] + @character
    return add_token compound_token, 'special_character' if @compound_special_characters.include? compound_token
    add_token @token_guess[:token], 'special_character'
    add_token @character, 'special_character'
  end

  # def is_integer? # problably deprecated
  #   return false unless @character.is_numeric?
  #   if token_guess == 'integer'
  #     @token_guess[:token] << @character
  #     return true
  #   end
  #   if token_guess.nil? 
  #     @token_guess[:token] = @character
  #     @token_guess[:description] = 'integer'
  #     @token_guess[:line] = @line
  #     return true
  #   end

  #   false
  # end

  def is_number?
    return true if is_integer?
    if (@token_guess[:token] + @character).is_real_number?
      @token_guess[:token] << @character
      @token_guess[:description] = 'real_number'
      @token_guess[:line] = line
      return true
    end
    @token_guess[:token] << @character
    @token_guess[:description] = 'malformatted_real'
    @token_guess[:line] = line

    return true if (@token_guess[:token] + '0').is_real_number?

    false
  end

  def is_real_number?
    if (@token_guess[:token] + @character).is_real_number?
      @token_guess[:token] << @character
      @token_guess[:description] = 'real_number'
      @token_guess[:line] = line
      return true
    end
    #if (@token_guess[:token] + '0').is_real_number?
    @token_guess[:token] << @character
    @token_guess[:description] = 'error: malformatted_real'
    @token_guess[:line] = line
    true
    #end
  end

  def is_integer?
    return false unless (@token_guess[:token] + @character).is_numeric?

    @token_guess[:token] << @character
    @token_guess[:description] = 'integer'
    @token_guess[:line] = line

    true
  end

  def is_identifier?
    byebug
    return false unless (@token_guess[:token] + @character).is_identifier?
    return true if is_reserved_word?
    
    @token_guess[:token] << @character
    @token_guess[:description] = 'identifier'
    @token_guess[:line] = @line
    true
  end

  def is_reserved_word?
    return false unless @reserved_words.include? (@token_guess[:token] + @character)

    @token_guess[:token] << @character
    @token_guess[:description] = @token_guess[:token]
    @token_guess[:line] = @line

    true
  end

  def is_spacer?
    return false unless @blank_spaces.include? @current_character
    add_token @token_guess[:token], @token_guess[:description] unless @token_guess[:description].nil?
    true
  end

  def clear_token_accumulator
    @token_guess = {
      line: nil,
      accumulator: '',
      token: nil
    }
  end

  def add_token token, description
    return add_error token, description if description.start_with?('error: ')
    @tokens << { token: token, description: description == 'special_character' ? token : description }
    clear_token_accumulator

    true
  end

  def add_error token, description
    @errors << { token: token, description: description, line: @token_guess[:line] }

    true
  end
end

class String
  def is_numeric?
    not (self =~ /\a\d+\z/).nil?
  end
 
  def is_letter?
    not (self =~ /\a[A-Za-z]\z/).nil?
  end

  def is_real_number?
    not (self =~ /\a\d+.\d+\z/).nil?
  end

  def is_identifier?
    not (self =~ /\a[a-zA-Z]+[0-9a-zA-Z]*\z/).nil?
  end
end