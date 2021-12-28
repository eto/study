#!/usr/bin/env ruby
# coding: utf-8
# Copyright (C) 2004-2021 Koichiro Eto, All rights reserved.
# License: BSD 3-Clause License

require 'fmod'

FMOD.load_library

system = FMOD::System.create
sound = system.create_sound("pi.wav")
p sound.length	# 40ms? →0.04sec
(1..30).each {|i|
  channel = sound.play
  freq = channel.frequency	# default: 44100.0
  channel.frequency = freq / i
  p channel.frequency
  sleep 0.04 * i
}
sleep 2
