require 'byebug'
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
    @current_character = nil
    @tokens = []
    @commentary = false
    @errors = []
    @accumulator = ''

    @lines.each_with_index do |line, line_index|
      @line = line
      @line_index = line_index
      line.each_char do |character|
        @accumulator = @token_guess[:token] + character
        @character = character

        @current_character = character
        next if is_commentary?
        next if is_not_allowed_character?
        next if (character.is_numeric? or character == '.') && is_number?
        next if is_special_character?
        next if is_identifier?
        next if is_spacer?

        add_token @token_guess[:token], @token_guess[:description] unless @token_guess[:description].nil? 
      end
    end
    add_token @token_guess[:token], @token_guess[:description] unless @token_guess[:description].nil?
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
    return false if not @not_allowed_characters.include? @character and @character.ord < 127

    add_token @token_guess[:token], @token_guess[:description] unless @token_guess[:description].nil?
    add_error @character, 'error: character not allowed'

    true
  end

  def is_special_character?
    return false unless @special_characters.include? @character
    return check_special_character_token if @token_guess[:description] == 'special_character'

    add_token @token_guess[:token], @token_guess[:description] unless @token_guess[:description].nil?
    @token_guess[:description] = 'special_character'
    @token_guess[:token] = @character
    @token_guess[:line] = @line_index

    true
  end

  def check_special_character_token
    compound_token = @accumulator
    return add_token compound_token, 'special_character' if @compound_special_characters.include? compound_token
    add_token @token_guess[:token], 'special_character'
    add_token @character, 'special_character'
  end

  def is_number?
    return true if is_integer?
    is_real_number?
  end

  def is_real_number?
    if @accumulator.is_real_number?
      @token_guess[:token] << @character
      @token_guess[:description] = 'real_number'
      @token_guess[:line] = @line_index
      return true
    end
    if @accumulator.has_letter?
      add_token @token_guess[:token], @token_guess[:description]
      add_token @character, @character
      return false
    end
    @token_guess[:token] << @character
    @token_guess[:description] = 'error: malformatted_real'
    @token_guess[:line] = @line_index
    true
  end

  def is_integer?
    return false unless @accumulator.is_numeric?

    @token_guess[:token] << @character
    @token_guess[:description] = 'integer'
    @token_guess[:line] = @line_index

    true
  end

  def is_identifier?
    return false unless @accumulator.is_identifier?
    return true if is_reserved_word?
    
    @token_guess[:token] << @character
    @token_guess[:description] = 'identifier'
    @token_guess[:line] = @line_index
    true
  end

  def is_reserved_word?
    return false unless @reserved_words.include? @accumulator

    @token_guess[:token] << @character
    @token_guess[:description] = @token_guess[:token]
    @token_guess[:line] = @line_index

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
      token: '',
      description: nil
    }
  end

  def add_token token, description
    return add_error token, description if description.start_with?('error: ')
    @tokens << { token: token, description: description == 'special_character' ? token : description }
    clear_token_accumulator

    true
  end

  def add_error token, description
    @errors << { token: token, description: description, line: @line_index }
    clear_token_accumulator
    
    true
  end
end

class String
  def is_numeric?
    not (self =~ /\A\d+\z/).nil?
  end
 
  def is_letter?
    not (self =~ /\A[A-Za-z]\z/).nil?
  end

  def is_real_number?
    not (self =~ /\A\d+.\d+\z/).nil?
  end

  def is_identifier?
    not (self =~ /\A[a-zA-Z]+[0-9a-zA-Z]*\z/).nil?
  end

  def has_letter?
    not (self =~ /[A-Za-z]/).nil?
  end
end
