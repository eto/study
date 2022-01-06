#!/usr/bin/env ruby
# coding: utf-8
# Copyright (C) 2022 Koichiro Eto, All rights reserved.
# License: BSD 3-Clause License

#pyimport 'facecamera'
fc = PyCall.import_module('facecamera')

class MediaPipeFace
  def initialize
    @running = true
    @cap = nil
    @face_mesh = nil
  end

  def main(argv)
    #pyimport 'facecamera', as: 'fc'
  end
end
