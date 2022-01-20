#!/usr/bin/env ruby
# coding: utf-8
# Copyright (C) 2022 Koichiro Eto, All rights reserved.
# License: BSD 3-Clause License

# for https://www.powerlanguage.co.uk/wordle/

require "pathname"
require "qp"

MATCH_CHARACTERS = "*o***"
USE_CHARACTERS = "orb"
NOTUSE_CHARACTERS = "eynmcalugh"
NOTUSE_PLACES = "mcb _ nru eag ylh"

class Main
  def initialize
    #@wordsfile = Pathname.new "/usr/share/dict/words"
    @outfile = Pathname.new "words.txt"
    @words = []
    @match_characters = MATCH_CHARACTERS.split(//)
    @use_characters = USE_CHARACTERS.split(//)
    @notuse_characters = NOTUSE_CHARACTERS.split(//)
    @notuse_places = NOTUSE_PLACES.split(/ /)
    #@allwords = get_five_letters_words(@wordsfile)
    @allwords = get_five_letters_words
  end

  def main(argv)
    words = []
    @allwords.each {|word|
      next unless check_match_characters(word)
      #qp word
      next if check_notuse_characters(word)
      next unless check_use_characters(word)
      if check_notuse_places(word)
        #p word
        words << word
      else
        #p ["bad", word]
      end
    }
    output_words(words, @outfile)
    words_with_freq = calculate_words(words)
    outfile = Pathname.new "words_with_freq2.txt"
    output_words_with_frequency(words_with_freq, outfile)
  end

  def check_match_characters(word)
    @match_characters.each_with_index {|char, index|
      next if char == "*"	# unknown
      wordchar = word[index]
      #qp char, index, wordchar
      return false if char != wordchar
    }
    return true
  end

  def check_notuse_characters(word)
    @notuse_characters.each {|char|
      return true if word.include?(char)
    }
    return false
  end

  def check_use_characters(word)
    @use_characters.each {|char|
      return false unless word.include?(char)
    }
    return true
  end

  def check_notuse_places(word)
    @notuse_places.each_with_index {|notuseword, index|
      char = word[index]
      #qp notuseword, index, char
      return false if notuseword.include?(char)
    }
    return true
  end

  def get_five_letters_words
    wordsfile = Pathname.new "five-letters-words.txt"
    str = wordsfile.open {|f| f.read }
    words = []
    str.each_line {|line|
      words << line.chomp
    }
    return words
  end

  def get_five_letters_words_from_unix(wordsfile)
    str = wordsfile.open {|f| f.read }
    words = []
    str.each_line {|line|
      #p line
      line.chomp!
      next if line.length != 5
      word = line.downcase
      #p word
      words << word
    }
    return words
  end

  def output_words(words, outfile)
    outfile.open("wb") {|out|
      words.each {|word|
        out.puts word
      }
    }
  end

  def calculate_frequent_words	# 頻出単語を計算する
    words_with_freq = calculate_words(@allwords)
    outfile = Pathname.new "words_with_freq.txt"
    output_words_with_frequency(words_with_freq, outfile)
  end

  def output_words_with_frequency(words_with_freq, outfile)
    outfile.open("wb") {|out|
      words_with_freq.each {|freq_of_the_word, word|
        out.printf("%0.1f	#{word}\n", freq_of_the_word*100.0)
      }
    }
  end

  def calculate_words(words)
    freq = calculate_all_frequency(words)
    words_with_freq = []
    words.each {|word|
      chars = word.split(//)
      freq_of_the_word = 0.0
      chars.each_with_index {|char, index|
        f = freq[index][char]
        freq_of_the_word += f
      }
      #qp word, freq_of_the_word
      words_with_freq << [freq_of_the_word, word]
    }
    words_with_freq = words_with_freq.sort.reverse
    return words_with_freq
  end

  def calculate_all_frequency(words)
    freq = []
    #qp @words.length
    words.each {|word|
      chars = word.split(//)
      #qp chars
      chars.each_with_index {|char, index|
        freq[index] = {} if freq[index].nil?
        freq[index][char] = 0 if freq[index][char].nil?
        freq[index][char] += 1
      }
    }
    #qp freq
    freq.each_with_index {|columns, index|
      #qp index, columns
      columns.each {|char, num|
        #qp column
        columns[char] = columns[char].to_f / words.length.to_f
        #print "#{index}_#{char}_#{columns[char]};"
        #printf("#{index}_#{char}_%0.1f;", columns[char]*100.0)
        #ruby print 桁
        #column.each {|char, num|
        #}
      }
      #puts
    }
    return freq
  end
end
