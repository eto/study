#!/usr/bin/env ruby
# coding: utf-8
# Copyright (C) 2022 Koichiro Eto, All rights reserved.
# License: BSD 3-Clause License

require "pathname"
require "qp"

class Main
  def initialize
    @wordsfile = Pathname.new "/usr/share/dict/words"
    #@outfile = Pathname.new "five-letters-words.txt"
    @outfile = Pathname.new "words.txt"
    @words = []
  end

  def main(argv)
    @words = get_five_letters_words(@wordsfile)
    words = []
    @words.each {|word|
      next unless word.include?("s")
      next unless word.include?("e")
      next unless word.include?("r")
    }
    output_words(words, @outfile)
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
end
