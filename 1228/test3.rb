#!/usr/bin/env ruby
# coding: utf-8
# Copyright (C) 2004-2021 Koichiro Eto, All rights reserved.
# License: BSD 3-Clause License

require 'fmod'

FMOD.load_library

system = FMOD::System.create
sound = system.create_sound("pi.wav")
p sound.length	# 40
(1..10).each {|i|
  channel = sound.play
  #channel.frequency = 4000/i
  channel.frequency = 4000-i*100
  #sound.frequency = 4000/i
  sleep 0.1
}
sleep 1
