#!/usr/bin/env ruby
# coding: utf-8
# Copyright (C) 2004-2021 Koichiro Eto, All rights reserved.
# License: BSD 3-Clause License

require 'fmod'

class FMODSystem
  def initialize
    FMOD.load_library
    @system = FMOD::System.create
  end

  def load_sound(file)
    sound = @system.create_sound("pi.wav")
    fmodsound = FMODSound.new(sound)
    return fmodsound
  end
end

class FMODSound
  def initialize(sound)
    @sound = sound
    @channel = nil
    @freq = nil
  end
  attr_reader :freq

  def play(freq = nil)
    @channel = @sound.play
    @freq = @channel.frequency	# default: 44100.0
    if freq
      @freq = freq
      @channel.frequency = @freq
    end
  end

  def length; @sound.length; end
end

class App
  def main
    system = FMODSystem.new
    sound = system.load_sound("pi.wav")
    p sound.length
    base = 44100.0
    (1..30).each {|i|
      sound.play(base / i)
      p sound.freq
      sleep 0.04 * Math.sqrt(i.to_f)
    }
    sleep 2
  end
end

App.new.main
