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
#qp operators
operatorslist = []
operators.each {|operator|
  op = []
  op[0] = operator
  operators.each {|operator|
    op[1] = operator
    operators.each {|operator|
      op[2] = operator
      operatorslist << op.dup
    }
  }
}

#expressions = {}
expressions = []
operatorslist.each {|op|
  formula = []
  formula << nums[0].to_s+".0"
  formula << op[0]
  formula << nums[1].to_s+".0"
  formula << op[1]
  formula << nums[2].to_s+".0"
  formula << op[2]
  formula << nums[3].to_s+".0"
  formulastr = formula.join("")
  result = eval formulastr
  expressions << [formulastr, result]
  #qp formulastr, result
  if result == 10
    p [formulastr, result]
  end
}
