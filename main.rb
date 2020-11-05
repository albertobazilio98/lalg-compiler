require './lexical_analyser'
a = LexicalAnalyser.new('test.txt')
a.start_analysis

a.tokens.each do |token|
    puts "#{token[:token]} - #{token[:description]}"
end
a.errors.each do |error|
    puts "#{error[:description]} \"#{error[:token]}\" at line #{error[:line] + 1}"
end
