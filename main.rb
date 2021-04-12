require 'byebug'
require './syntatic_analyser'
require './lexical_analyser'

file = File.open(ARGV[0])

# lex = LexicalAnalyser.new(file)
# a = lex.get_token
# while not a.nil?
#   puts a
#   a = lex.get_token
# end

syntatic = SyntaticAnalyser.new(file)
