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

main
