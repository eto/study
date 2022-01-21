#!/usr/bin/env ruby
# coding: utf-8
# Copyright (C) 2022 Koichiro Eto, All rights reserved.
# License: BSD 3-Clause License

require "pp"
require "qp"
require "ostruct"
require "pathname"
require "autoreload"

require 'pycall/import'
include PyCall::Import
PyCall.sys.path.append(__dir__)
require 'numpy'

$LOAD_PATH << "."
$LOAD_PATH << "../../sgl/lib"
#require 'sgl'

autoreload(:interval=>1, :verbose=>true, :reprime=>true) {
  require "test22"
}

if ARGV[0] == "--test"
  ARGV.shift
  require "test/unit"
  class TestIt < Test::Unit::TestCase
    def test_it
      assert_equal(2, 1+1)
    end
  end
else
  MediaPipeFace.new.main(ARGV)
end
