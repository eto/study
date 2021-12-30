#!/usr/bin/env ruby -w
# coding: utf-8
# Copyright (C) 2004-2021 Koichiro Eto, All rights reserved.
# License: BSD 3-Clause License

require "cutep"

given = "6459"
chars = given.split(//)
nums = []
chars.each {|char|
  nums << char.to_i
}

operators = %w{+ - * /}
operatorslist = []
op = []
operators.each {|operator|
  op << operator
  operators.each {|operator|
    op << operator
    operators.each {|operator|
      op << operator
    }
  }
  operatorslist = op
}

#expressions = {}
expressions = []
loop {
  operatorslist.each {|operator|
    formula << nums[0]
    formula << op[0]
    formula << nums[1]
    formula << op[1]
    formula << nums[2]
    formula << op[2]
    formula << nums[3]
    formulastr = formula.join("")
    result = eval formulastr
    expressions << [formulastr, result]
    p formulastr, result
    if result == 10
      p formulastr
    end
  }
}
