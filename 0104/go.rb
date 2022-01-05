#!/usr/bin/env ruby
# coding: utf-8
# Copyright (C) 2022 Koichiro Eto, All rights reserved.
# License: BSD 3-Clause License

require "pp"
require "qp"
require "autoreload"

$LOAD_PATH << "."
autoreload(:interval=>1, :verbose=>true, :reprime=>true) do
  require "test6"
end

if ARGV[0] == "--test"
  ARGV.shift
  require "test/unit"
  class TestIt < Test::Unit::TestCase
    def test_it
      assert_equal(2, 1+1)
      #it = Studies.new
    end
  end
else
  MediaPipeTest.new.main(ARGV)
end
