#!/usr/bin/env ruby -w
# coding: utf-8
# Copyright (C) 2004-2021 Koichiro Eto, All rights reserved.
# License: BSD 3-Clause License

given = "6459"
chars = given.split(//)
nums = []
chars.each {|char|
  nums << char.to_i
}

operators = %w{+ - * /}

expressions = []
loop {
  formula = []
  formula << nums[0]
  operators.each {|operator|
    formula << operator
    formula << nums[1]
    operators.each {|operator|
      formula << operator
      formula << nums[2]
      operators.each {|operator|
        formula << operator
        formula << nums[3]
      }
    }
  }
  formulastr = formula.join("")
  result = eval formulastr
  expressions[formulastr] = result
  if result == 10
    p formulastr
  end
  }
}
