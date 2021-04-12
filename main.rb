require 'byebug'
require './syntatic_analyser'
require './lexical_analyser'

path  = ARGV[0]

raise 'no file provided' if path.nil?
raise 'file does not exists' unless File.exists?(path)

file = File.open(path)

syntatic = SyntaticAnalyser.new(file)
