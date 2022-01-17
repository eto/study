#!/usr/bin/env ruby
# coding: utf-8
# Copyright (C) 2022 Koichiro Eto, All rights reserved.
# License: BSD 3-Clause License

require "pathname"
require "qp"

class Main
  def main(argv)
    file = Pathname.new "/usr/share/dict/words"
    outfile = Pathname.new "five-letters-words.txt"
    outfile.open("wb") {|out|
      file.open {|f|
        while line = f.read
          line.chomp!
          next if line.length != 5
          out.puts word
        end
      }
    }
  end
end
