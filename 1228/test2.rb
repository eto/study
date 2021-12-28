#!/usr/bin/env ruby
require 'sdl2'
SDL2::init(SDL2::INIT_AUDIO)
SDL2::Mixer.init(SDL2::Mixer::INIT_FLAC|SDL2::Mixer::INIT_MP3|SDL2::Mixer::INIT_OGG)
SDL2::Mixer.open(22050, SDL2::Mixer::DEFAULT_FORMAT, 2, 512)
p SDL2::Mixer::Chunk.decoders
p SDL2::Mixer::Music.decoders
wave = SDL2::Mixer::Chunk.load(ARGV[0])
(0..100).each {|i|
  #SDL2::Mixer::Channels.fade_in(0, wave, 0, 600)
  SDL2::Mixer::Channels.fade_in(i%8, wave, 0, 600)
  sleep 0.05
}
while SDL2::Mixer::Channels.play?(0)
  sleep 1
end
