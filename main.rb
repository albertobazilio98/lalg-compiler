require 'byebug'
require './lexical_analyser'

file = ('test.lalg') # you can change the file you want to read here

# lexical_analyser = LexicalAnalyser.new(file)
# lexical_analyser.start_analysis do |lexical, token|
#   byebug
# end

# lexical_analyser.tokens.each do |token|
#   # puts "#{token[:token]} - #{token[:description]}"
# end
# lexical_analyser.errors.each do |error|
#   # puts "#{error[:description]} \"#{error[:token]}\" at line #{error[:line] + 1}"
# end
