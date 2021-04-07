require 'byebug'

token_enum = {
  integer: 0,
  real: 1,
  reserved_word: 2,
  identifier: 3,
  special_character: 4,
  error: 5,
}

error_enum = {

}

class LexicalAnalyser

  def initialize file_name
    @lines = File.open(file_name).readlines

    @tokens = []
    @errors = []
    @commentary = false
    @line = 0
    @column = 0
  end

  def get_token
    puts @lines[@line]
    return nil if characters_ended?
    skip_blanks
    @token_complete = false
    @token_guess = {
      token: '',
      description: nil,
      completed: false,
      error: nil,
      line: @line,
      column: @column,
    }

    while not is_blank? and not @token_guess[:completed]
      if not is_allowed_character? or is_special_character? or is_identifier? or is_number?
        go_to_next_char
      end
      # puts 'youre not suposed to be here'
      # puts current_character
      next
    end

    return @token_guess
  end

  private

  # character methods

  def current_character
    @lines[@line][@column] unless characters_ended?
  end

  def next_char
    return @lines[@line][@column + 1] unless @lines[@line][@column].nil?

    @lines[@line + 1][0]
  end

  def go_to_next_char
    return if characters_ended?
    @column += 1
    go_to_next_line if line_ended?
  end

  def go_to_next_line
    @line += 1
    @column = 0
  end

  # skippable methods

  def characters_ended?
    @lines[@line].nil?
  end

  def skip_blanks
    go_to_next_char while not characters_ended? and is_blank?
  end

  def is_blank?
    return characters_ended? || is_commentary? || is_spacer?
  end

  def line_ended?
    current_character.nil?
  end

  def is_spacer?
    current_character.is_blank_space?
  end

  def is_commentary?
    return @commentary = true if current_character == '{'
    if current_character == '}'
      go_to_next_char
      return @commentary = false
    end

    @commentary
  end

  # helper methods

  def lookup_token
    (@token_guess[:token] + next_char)
  end

  # token checking methods
  
  def is_allowed_character?
    return true if not current_character.is_not_allowed_character? and current_character.ord < 127

    @token_guess[:token] = current_character
    @token_guess[:description] = :error
    @token_guess[:error] = :character_not_allowed
    @token_guess[:completed] = true

    false
  end

  def is_special_character?
    return false unless current_character.is_special_character?
    @token_guess[:token] << current_character
    
    if @token_guess[:description] == :special_character
      @token_guess[:completed] = true

      return true
    end

    @token_guess[:description] = :special_character # if @token_guess[:description].nil? # talvez nn precise desse cara
    
    @token_guess[:completed] = true unless lookup_token.is_compound_special_character? # next_char.is_special_character?
    
    true
  end

  def is_identifier?
    return false unless (@token_guess[:description].nil? and current_character.is_letter?) or @token_guess[:token].is_identifier?
    @token_guess[:token] << current_character

    unless lookup_token.is_identifier?
      @token_guess[:completed] = true
      @token_guess[:description] = :reserved_word if @token_guess[:token].is_reserved_word?
    else
      @token_guess[:description] = :identifier if @token_guess[:description].nil?
    end

    true
  end

  def is_number?
    return false unless current_character.is_numeric? or (current_character == '.' and not @token_guess.description.nil?)

    @token_guess[:token] << current_character
    
    if lookup_token.is_numeric?
      @token_guess[:description] = :integer
    end

    if next_char == '.' and @token_guess[:description] != :integer
      @token_guess[:description] = :error
      @token_guess[:error] = :malformated_real
    end

    if lookup_token.is_real_number?
      @token_guess[:description] = :real
    end

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

  def is_blank_space?
    not (self =~ /\A\s\z/).nil?
  end

  def has_letter?
    not (self =~ /[A-Za-z]/).nil?
  end

  def is_not_allowed_character?
    not (self =~ /[\!\"\#\$\%\&\'\?\@\[\]\\\^\_\`\|]/).nil?
  end

  def is_special_character?
    not (self =~ /[\;\(\)\,\:\=\>\<\+\-\*\/\.]/).nil?
  end

  def is_compound_special_character?
    not (self =~ /\A(\<\>|\>\=|\<\=|\:\=)\z/).nil?
  end

  def is_reserved_word?
    not (self =~ /\A(read|write|if|then|else|while|do|begin|end|procedure|program|real|integer|var)\z/).nil?
  end

end
