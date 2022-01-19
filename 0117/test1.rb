#!/usr/bin/env ruby
# coding: utf-8
# Copyright (C) 2022 Koichiro Eto, All rights reserved.
# License: BSD 3-Clause License

require "pathname"
require "qp"

MATCH_CHARACTERS = "S*IRE"
USE_CHARACTERS = "serh"
NOTUSE_CHARACTERS = "wtyoadl"
NOTUSE_PLACES = "r e rse es rh"

class Main
  def initialize
    @wordsfile = Pathname.new "/usr/share/dict/words"
    @outfile = Pathname.new "words.txt"
    @words = []
    @use_characters = USE_CHARACTERS.split(//)
    @notuse_characters = NOTUSE_CHARACTERS.split(//)
    @notuse_places = NOTUSE_PLACES.split(/ /)
    @words = get_five_letters_words(@wordsfile)
  end

  def main(argv)
    words = []
    @words.each {|word|
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

  def get_five_letters_words(wordsfile)
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
  end
end
