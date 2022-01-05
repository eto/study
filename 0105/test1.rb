#!/usr/bin/env ruby
# coding: utf-8

require 'pycall'
math = PyCall.import_module("math")
p math.sin(math.pi / 4) - Math.sin(Math::PI / 4)   # => 0.0
