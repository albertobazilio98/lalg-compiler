require './lexical_analyser'
require 'byebug'

class SyntaticAnalyser
  def initialize file
    @file = file
    @lexical = LexicalAnalyser.new(file)
    @errors = []
    @tokens = []
    get_token
    programa
  end

  private

  def current_token_kind
    @current_token[:token_kind]
  end

  def bg_red text
    "\e[31m#{text}\e[0m"
  end

  def dont_panic_and_carry_a_towel
    puts 42
    go_to_safe_point
  end

  def go_to_safe_point
    token = @lexical.get_token
  end

  def raise_error_message expected
    puts @batata
    puts bg_red "syntax error: expected token `#{expected}` got `#{current_token_kind}` on `#{File.expand_path(@file.path)}:#{@current_token[:line] + 1}:#{@current_token[:column] + 1}`"
  end

  def get_token
    @current_token = @lexical.get_token
    get_token if not @current_token.nil? and @current_token[:description] == :error
  end

  # expects

  def expect *token_kinds
    return if @current_token.nil?
    unless token_kinds.include? current_token_kind
      raise_error_message token_kinds.join(' | ')
    end
    get_token
  end

  def match_with_token? *token_kinds
    token_kinds.include? current_token_kind
  end

  # syntatic tree

  # <programa> ::= program identifier ; <corpo> .
  def programa
    @batata = 'programa'
    puts "#{@batata} #{current_token_kind}"
    expect 'program'
    expect :identifier
    expect ';'
    corpo
    expect '.'
  end

  # <corpo> ::= <dc> begin <comandos> end
  def corpo
    @batata = 'corpo'
    puts "#{@batata} #{current_token_kind}"
    dc
    expect 'begin'
    comandos
    expect 'end'
  end

  # <dc> ::= <dc_v> <dc_p>
  def dc
    @batata = 'dc'
    puts "#{@batata} #{current_token_kind}"
    dc_v
    dc_p
  end

  # <dc_v> ::= var <variaveis> : <tipo_var> ; <dc_v> | λ
  def dc_v
    @batata = 'dc_v'
    puts "#{@batata} #{current_token_kind}"
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
    @batata = 'tipo_var'
    puts "#{@batata} #{current_token_kind}"
    expect 'real', 'integer'
  end

  # <variaveis> ::= identifier <mais_var>
  def variaveis
    @batata = 'variaveis'
    puts "#{@batata} #{current_token_kind}"
    expect :identifier
    mais_var
  end

  # <mais_var> ::= , <variaveis> | λ
  def mais_var
    @batata = 'mais_var'
    puts "#{@batata} #{current_token_kind}"
    return unless match_with_token? ','
    expect ','
    variaveis
  end

  # <dc_p> ::= procedure identifier <parametros> ; <corpo_p> <dc_p> | λ
  def dc_p
    @batata = 'dc_p'
    puts "#{@batata} #{current_token_kind}"
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
    @batata = 'parametros'
    puts "#{@batata} #{current_token_kind}"
    return unless match_with_token? '('
    expect '('
    lista_par
    expect ')'
  end

  # <lista_par> ::= <variaveis> : <tipo_var> <mais_par>
  def lista_par
    @batata = 'lista_par'
    puts "#{@batata} #{current_token_kind}"
    variaveis
    expect ':'
    tipo_var
    mais_par
  end

  # <mais_par> ::= ; <lista_par> | λ
  def mais_par
    @batata = 'mais_par'
    puts "#{@batata} #{current_token_kind}"
    return unless match_with_token? ';'
    expect ';'
    lista_par
  end

  # <corpo_p> ::= <dc_loc> begin <comandos> end ;
  def corpo_p
    @batata = 'corpo_p'
    puts "#{@batata} #{current_token_kind}"
    dc_loc
    expect 'begin'
    comandos
    expect 'end'
    expect ';'
  end

  # <dc_loc> ::= <dc_v>
  def dc_loc
    @batata = 'dc_loc'
    puts "#{@batata} #{current_token_kind}"
    dc_v
  end

  # <lista_arg> ::= ( <argumentos> ) | λ
  def lista_arg
    @batata = 'lista_arg'
    puts "#{@batata} #{current_token_kind}"
    return unless match_with_token? '('
    expect '('
    argumentos
    expect ')'
  end

  # <argumentos> ::= identifier <mais_ident>
  def argumentos
    @batata = 'argumentos'
    puts "#{@batata} #{current_token_kind}"
    expect :identifier
    mais_ident
  end

  # <mais_ident> ::= ; <argumentos> | λ
  def mais_ident
    @batata = 'mais_ident'
    puts "#{@batata} #{current_token_kind}"
    return unless match_with_token? ';'
    expect ';'
    argumentos
  end

  # <pfalsa> ::= else <cmd> | λ
  def pfalsa
    @batata = 'pfalsa'
    puts "#{@batata} #{current_token_kind}"
    return unless match_with_token? 'else'
    expect 'else'
    cmd
  end

  # <comandos> ::= <cmd> ; <comandos> | λ
  def comandos
    @batata = 'comandos'
    puts "#{@batata} #{current_token_kind}"
    return unless match_with_token? 'read', 'write', 'while', 'if', 'begin', 'if', :identifier
    cmd
    expect ';'
    comandos
    # |
    :empty
  end

  # <cmd> ::= read ( <variaveis> ) |
  #           write ( <variaveis> ) |
  #           while <condicao> do <cmd> |
  #           if <condicao> then <cmd> <pfalsa> |
  #           identifier := <expressao> |
  #           identifier <lista_arg> |
  #           begin <comandos> end
  def cmd
    @batata = 'cmd'
    puts "#{@batata} #{current_token_kind}"
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
    @batata = 'condicao'
    puts "#{@batata} #{current_token_kind}"
    expressao
    relacao
    expressao
  end

  # <relacao> ::= = | <> | >= | <= | > | <
  def relacao
    @batata = 'relacao'
    puts "#{@batata} #{current_token_kind}"
    expect '=', '<>', '>=', '<=', '>', '<'
  end

  # <expressao> ::= <termo> <outros_termos>
  def expressao
    @batata = 'expressao'
    puts "#{@batata} #{current_token_kind}"
    termo
    outros_termos
  end

  # <op_un> ::= + | - | λ
  def op_un
    @batata = 'op_un'
    puts "#{@batata} #{current_token_kind}"
    return unless match_with_token? '+', '-'
    expect '+', '-'
  end

  # <outros_termos> ::= <op_ad> <termo> <outros_termos> | λ
  def outros_termos
    @batata = 'outros_termos'
    puts "#{@batata} #{current_token_kind}"
    return unless match_with_token? '+', '-'
    op_ad
    termo
    outros_termos
  end

  # <op_ad> ::= + | -
  def op_ad
    @batata = 'op_ad'
    puts "#{@batata} #{current_token_kind}"
    expect '+', '-'
  end

  # <termo> ::= <op_un> <fator> <mais_fatores>
  def termo
    @batata = 'termo'
    puts "#{@batata} #{current_token_kind}"
    op_un
    fator
    mais_fatores
  end

  # <mais_fatores> ::= <op_mul> <fator> <mais_fatores> | λ
  def mais_fatores
    @batata = 'mais_fatores'
    puts "#{@batata} #{current_token_kind}"
    return unless match_with_token? '*', '/'
    op_mul
    fator
    mais_fatores
  end

  # <op_mul> ::= * | /
  def op_mul
    @batata = 'op_mul'
    puts "#{@batata} #{current_token_kind}"
    expect '*', '/'
  end

  # <fator> ::= identifier | numero_int | numero_real | ( <expressao> )
  def fator
    @batata = 'fator'
    puts "#{@batata} #{current_token_kind}"
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