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
    pyimport :cv2

    #args = fc.arg_parser()
    args = OpenStruct.new
    args.yaml_file = "config/make_up.yaml"
    args.video = 1
    fc_main(args.yaml_file, args.video)
  end

  def fc_main(yaml_file, cam_idx)
    config = fc.Config.(yaml_file)	# Config処理
    detector = fc.Detector.()	# 検知器定義
    cam = fc.Camera.(cam_idx, config, detector)	# カメル
    #cam.capture()	# 画像を取得し、フィルターを適用する。
    cam_capture(cam)
  end

  def cam_capture(cam)
    puts "Catpuring images from video input... (press 'q' to exit.)"
    loop {
      #result = cam.capture_oneframe
      result = cam_capture_oneframe(cam)
      break if ! result
    }
  end

  def cam_capture_oneframe(cam)
    success, frame = cam.cap.read()
    if ! success
      print("Ignoring empty camera frame.")
      return true
    end

    frame.flags.writeable = false
    frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    cam.detector.detect_faces(frame)

    frame.flags.writeable = true
    frame, mask = cam.detector.post_processing(cam.mask, cam.config.yaml_cfg)
    mask = cv2.flip(mask, 1)

    cam.v_cam._send(frame)	# 結果を送信する。

    mask = cv2.resize(mask, dsize=[400, 320])	# マスクを表示する。
    cv2.imshow("mask", cv2.cvtColor(mask, cv2.COLOR_BGR2RGB))

    key = cv2.waitKey(1)
    key &= 0xFF
    return false if key == 113 || key == 27
    return true
  end
end
