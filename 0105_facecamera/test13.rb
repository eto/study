#!/usr/bin/env ruby
# coding: utf-8
# Copyright (C) 2022 Koichiro Eto, All rights reserved.
# License: BSD 3-Clause License

#pyimport 'facecamera'
#PyCall.sys.path.append(__dir__)
#fc = PyCall.import_module('facecamera')

class MediaPipeFace
  def initialize
  end

  def main(argv)
    pyimport 'facecamera', as: 'fc'

    #args = fc.arg_parser()
    args = OpenStruct.new
    args.yaml_file = "config/make_up.yaml"
    args.video = 1
    fc.main(args.yaml_file, args.video)
    #fc_main(args.yaml_file, args.video)
  end

  def fc_main(yaml_file, cam_idx)
    config = fc.Config.(yaml_file)	# Config処理
    detector = fc.Detector.()	# 検知器定義
    cam = fc.Camera.(cam_idx, config, detector)	# カメル
    cam.capture()	# 画像を取得し、フィルターを適用する。
  end
end
