require './lexical_analyser'

class SyntaticAnalyser
  def initialize file
    @file = file
    @lexical = LexicalAnalyser.new(file)
    @panic = false
    @errors = []
    @tokens = []
    get_token
    programa
    puts "\nprocess completed with #{@errors.length} errors"
  end

  private

  def current_token_kind
    @current_token.nil? ? nil : @current_token[:token_kind]
  end

  def bg_red text
    "\e[31m#{text}\e[0m"
  end

  def dont_panic_and_carry_a_towel sync_tokens
    # 42
    while not sync_tokens.include? current_token_kind and not current_token_kind.nil?
      get_token
    end
    @panic = false
  end

  def raise_syntatic_error_message expected
    @panic = true
    where = @current_token.nil? ? '' : "on `#{File.expand_path(@file.path)}:#{@current_token[:line] + 1}:#{@current_token[:column] + 1}`"
    got = current_token_kind.nil? ? 'but file ended' : "got `#{current_token_kind}`"
    error = "syntax error: expected token `#{expected},` #{got} #{where}"
    @errors << error
    puts bg_red error
  end

  def raise_lexical_error
    @panic = true
    where = "on `#{File.expand_path(@file.path)}:#{@current_token[:line] + 1}:#{@current_token[:column] + 1}`"
    error = "lexical error: #{@current_token[:error]} `#{current_token_kind}` #{where}"
    @errors << error
    puts bg_red error
  end

  def get_token
    @current_token = @lexical.get_token
    @tokens << @current_token
    # get_token if not @current_token.nil? and @current_token[:description] == :error
    if not @current_token.nil? and @current_token[:description] == :error
      raise_lexical_error
      get_token
    end
  end

  # expects

  def expect *token_kinds
    unless token_kinds.include? current_token_kind and not @current_token.nil?
      raise_syntatic_error_message token_kinds.join(' | ')
      dont_panic_and_carry_a_towel token_kinds if @panic
    end
    get_token
  end

  def match_with_token? *token_kinds
    token_kinds.include? current_token_kind
  end

  # syntatic tree

  # <programa> ::= program identifier ; <corpo> .
  def programa
    expect 'program'
    expect :identifier
    expect ';'
    corpo
    expect '.'
  end

  # <corpo> ::= <dc> begin <comandos> end
  def corpo
    dc
    expect 'begin'
    comandos
    expect 'end'
  end

  # <dc> ::= <dc_v> <dc_p>
  def dc
    dc_v
    dc_p
  end

  # <dc_v> ::= var <variaveis> : <tipo_var> ; <dc_v> | λ
  def dc_v
    return unless current_token_kind == 'var'

    expect 'var'
    variaveis
    expect ':'
    tipo_var
    expect ';'
    dc_v
  end

  # <tipo_var> ::= real | integer
  def tipo_var
    expect 'real', 'integer'
  end

  # <variaveis> ::= identifier <mais_var>
  def variaveis
    expect :identifier
    mais_var
  end

  # <mais_var> ::= , <variaveis> | λ
  def mais_var
    return unless match_with_token? ','

    expect ','
    variaveis
  end

  # <dc_p> ::= procedure identifier <parametros> ; <corpo_p> <dc_p> | λ
  def dc_p
    return unless match_with_token? 'procedure'

    expect 'procedure'
    expect :identifier
    parametros
    expect ';'
    corpo_p
    dc_p
  end

  # <parametros> ::= ( <lista_par> ) | λ
  def parametros
    return unless match_with_token? '('

    expect '('
    lista_par
    expect ')'
  end

  # <lista_par> ::= <variaveis> : <tipo_var> <mais_par>
  def lista_par
    variaveis
    expect ':'
    tipo_var
    mais_par
  end

  # <mais_par> ::= ; <lista_par> | λ
  def mais_par
    return unless match_with_token? ';'

    expect ';'
    lista_par
  end

  # <corpo_p> ::= <dc_loc> begin <comandos> end ;
  def corpo_p
    dc_loc
    expect 'begin'
    comandos
    expect 'end'
    expect ';'
  end

  # <dc_loc> ::= <dc_v>
  def dc_loc
    dc_v
  end

  # <lista_arg> ::= ( <argumentos> ) | λ
  def lista_arg
    return unless match_with_token? '('

    expect '('
    argumentos
    expect ')'
  end

  # <argumentos> ::= identifier <mais_ident>
  def argumentos
  
    expect :identifier
    mais_ident
  end

  # <mais_ident> ::= ; <argumentos> | λ
  def mais_ident
    return unless match_with_token? ';'

    expect ';'
    argumentos
  end

  # <pfalsa> ::= else <cmd> | λ
  def pfalsa
    return unless match_with_token? 'else'

    expect 'else'
    cmd
  end

  # <comandos> ::= <cmd> ; <comandos> | λ
  def comandos
    return unless match_with_token? 'read', 'write', 'while', 'if', 'begin', 'if', :identifier

    cmd
    expect ';'
    comandos
  end

  # <cmd> ::= read ( <variaveis> ) |
  #           write ( <variaveis> ) |
  #           while <condicao> do <cmd> |
  #           if <condicao> then <cmd> <pfalsa> |
  #           identifier := <expressao> |
  #           identifier <lista_arg> |
  #           begin <comandos> end
  def cmd
    if match_with_token? 'read'
      expect 'read'
      expect '('
      variaveis
      expect ')'
    elsif match_with_token? 'write'
      expect 'write'
      expect '('
      variaveis
      expect ')'
    elsif match_with_token? 'while'
      expect 'while'
      condicao
      expect 'do'
      cmd
    elsif match_with_token? 'if'
      expect 'if'
      condicao
      expect 'then'
      cmd
      pfalsa
    elsif match_with_token? 'begin'
      expect 'begin'
      comandos
      expect 'end'
    elsif match_with_token? :identifier
      expect :identifier
      if match_with_token? ':='
        expect ':='
        expressao
      elsif match_with_token? '('
        lista_arg
      end
    end
  end

  # <condicao> ::= <expressao> <relacao> <expressao>
  def condicao
    expressao
    relacao
    expressao
  end

  # <relacao> ::= = | <> | >= | <= | > | <
  def relacao
    expect '=', '<>', '>=', '<=', '>', '<'
  end

  # <expressao> ::= <termo> <outros_termos>
  def expressao
    termo
    outros_termos
  end

  # <op_un> ::= + | - | λ
  def op_un
    return unless match_with_token? '+', '-'

    expect '+', '-'
  end

  # <outros_termos> ::= <op_ad> <termo> <outros_termos> | λ
  def outros_termos
    return unless match_with_token? '+', '-'

    op_ad
    termo
    outros_termos
  end

  # <op_ad> ::= + | -
  def op_ad
    expect '+', '-'
  end

  # <termo> ::= <op_un> <fator> <mais_fatores>
  def termo
    op_un
    fator
    mais_fatores
  end

  # <mais_fatores> ::= <op_mul> <fator> <mais_fatores> | λ
  def mais_fatores
    return unless match_with_token? '*', '/'

    op_mul
    fator
    mais_fatores
  end

  # <op_mul> ::= * | /
  def op_mul
    expect '*', '/'
  end

  # <fator> ::= identifier | numero_int | numero_real | ( <expressao> )
  def fator
    return unless match_with_token? :identifier, :integer, '('
    
    if current_token_kind == :identifier
      expect :identifier
    elsif current_token_kind == :integer
      expect :integer
    elsif current_token_kind == :real
      expect :real
    elsif current_token_kind == '('
      expect '('
      expressao
      expect ')'
    end
  end
end