#!/usr/bin/env ruby
# coding: utf-8
# Copyright (C) 2022 Koichiro Eto, All rights reserved.
# License: BSD 3-Clause License

require "pathname"
require "qp"

def int(n)
  n.to_i
end

def list(n)
  n.to_a
end

class MediaPipeFace
  def initialize
  end

  def main(argv)
    pyimport "facecamera", as: :fc
    pyimport :cv2
    pyimport "numpy", as: :np
    pyimport :yaml
    pyimport :mediapipe, as: :mp

    args = OpenStruct.new
    args.yaml_file = "config/make_up.yaml"
    args.video = 1
    fc_main(args.yaml_file, args.video)
  end

  def read_config(yaml_file)
    #qp yaml_file
    #logger.info(f"Reading config file: {yaml_file}")
    puts "Reading config file: #{yaml_file}"
    path = Pathname.new(yaml_file)
    str = path.read
    yaml_cfg = yaml.safe_load(str)
    #qp yaml_cfg
    return yaml_cfg
  end

  def fc_main(yaml_file, cam_idx)
    #config = fc.Config.(yaml_file)	# Config処理
    config = read_config(yaml_file)	# Config処理
    detector = fc.Detector.()	# 検知器定義
    #detector = Detector.new	# 検知器定義
    cam = fc.Camera.(cam_idx, config, detector)	# カメル
    #cam.capture()	# 画像を取得し、フィルターを適用する。
    cam_capture(cam)
  end

  def cam_capture(cam)
    puts "Catpuring images from video input... (press 'q' or ESC to exit.)"
    loop {
      #result = cam.capture_oneframe
      result = cam_capture_oneframe(cam)
      break if ! result
      GC.start
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
    #frame, mask = cam.detector.post_processing(cam.mask, cam.config.yaml_cfg)
    #frame, mask = detector_post_processing(cam.detector, cam.mask, cam.config.yaml_cfg)
    frame, mask = detector_post_processing(cam.detector, cam.mask, cam.config)
    mask = cv2.flip(mask, 1)

    cam.v_cam._send(frame)	# 結果を送信する。

    mask = cv2.resize(mask, dsize=[480, 270])	# マスクを表示する。
    cv2.imshow("mask", cv2.cvtColor(mask, cv2.COLOR_BGR2RGB))

    key = cv2.waitKey(1) & 0xFF
    return false if key == 113 || key == 27	# q or ESC
    return true
  end

  def detector_post_processing(s, mask, cfg)
    if ! s.results.multi_face_landmarks	# 顔が認識されていなかった場合。
      #logger.warning("Face not detected.")
      return s.img, mask
    end

    face_dict = detector_create_face_dict(s)

    full_mask = detector_draw_with_face_dict(s, mask, cfg, face_dict)

    full_mask = cv2.GaussianBlur(full_mask, [7, 7], 20)
    tmp = cv2.addWeighted(s.img, 1, full_mask, 1, 1)

    return tmp, full_mask
  end

  def detector_create_face_dict(s)
    for face_landmarks in s.results.multi_face_landmarks
      #qp face_landmarks
      mask_lip = []
      mask_face = []
      mask_l_eyes = []
      mask_r_eyes = []
      mask_l_eyebrow = []
      mask_r_eyebrow = []
      for i in 0..s.face_mesh.FACEMESH_NUM_LANDMARKS
        if PyCall::List.(s.lips).to_a.include? i
          pt1 = face_landmarks.landmark[i]
          x = int(pt1.x * s.img.shape[1])
          y = int(pt1.y * s.img.shape[0])
          mask_lip.append([x, y])
        elsif PyCall::List.(s.l_eyes).to_a.include? i
          pt1 = face_landmarks.landmark[i]
          x = int(pt1.x * s.img.shape[1])
          y = int(pt1.y * s.img.shape[0])
          mask_l_eyes.append([x, y])
        elsif PyCall::List.(s.r_eyes).to_a.include? i
          pt1 = face_landmarks.landmark[i]
          x = int(pt1.x * s.img.shape[1])
          y = int(pt1.y * s.img.shape[0])
          mask_r_eyes.append([x, y])
        elsif PyCall::List.(s.r_eyebrow).to_a.include? i
          pt1 = face_landmarks.landmark[i]
          x = int(pt1.x * s.img.shape[1])
          y = int(pt1.y * s.img.shape[0])
          mask_r_eyebrow.append([x, y])
        elsif PyCall::List.(s.l_eyebrow).to_a.include? i
          pt1 = face_landmarks.landmark[i]
          x = int(pt1.x * s.img.shape[1])
          y = int(pt1.y * s.img.shape[0])
          mask_l_eyebrow.append([x, y])
        else
          pt1 = face_landmarks.landmark[i]
          x = int(pt1.x * s.img.shape[1])
          y = int(pt1.y * s.img.shape[0])
          mask_face.append([x, y])
        end
      end
    end

    face_dict = {}
    face_dict["mask_face"] = np.array(mask_face)
    face_dict["mask_l_eyes"] = np.array(mask_l_eyes)
    face_dict["mask_r_eyes"] = np.array(mask_r_eyes)
    face_dict["mask_lip"] = np.array(mask_lip)
    face_dict["mask_l_eyebrow"] = np.array(mask_l_eyebrow)
    face_dict["mask_r_eyebrow"] = np.array(mask_r_eyebrow)
    return face_dict
  end

  def detector_draw_with_face_dict(s, mask, cfg, face_dict)
    full_mask = mask.copy()
    face_dict.each {|part, v|
      if part == "mask_face"
        full_mask = detector_draw_convex(v, mask, full_mask, [140, 57, 0], 0.1)
      elsif part == "mask_l_eyes"
        full_mask = detector_draw_convex(v, mask, full_mask, [52, 124, 44], 0.15)
      elsif part == "mask_r_eyes"
        full_mask = detector_draw_convex(v, mask, full_mask, [52, 124, 44], 0.15)
      elsif part == "mask_lip"
        full_mask = detector_draw_convex(v, mask, full_mask, [142, 30, 29], 0.92)
      elsif part == "mask_l_eyebrow"
        full_mask = detector_draw_convex(v, mask, full_mask, [200, 200, 200], 0.08)
      elsif part == "mask_r_eyebrow"
        full_mask = detector_draw_convex(v, mask, full_mask, [200, 200, 200], 0.08)
      else
        full_mask = detector_draw_convex(v, mask, full_mask, [0, 0, 0], 0.0)	# ここには来ない
      end
    }
    return full_mask
  end

  def mask_face(v, mask, full_mask, color, weight)
    detector_draw_convex(v, mask, full_mask, color, weight)
  end

  def detector_draw_convex(v, mask, full_mask, color, weight)
    base = mask.copy()
    convexhull = cv2.convexHull(v)
    base = cv2.fillConvexPoly(base, convexhull, [color[0], color[1], color[2]])
    #full_mask = cv2.addWeighted(full_mask, 1, base, weight, 1)
    full_mask = cv2.addWeighted(full_mask, 1, base, weight*0.1, 1)
    return full_mask
  end
end

class Detector	# ④検知器クラス：Mediapipeのインスタンス化
  def initialize(thickness=1, circle_radius=1, color=[255,0,255], min_detection_confidence=0.5, min_tracking_confidence=0.5)
    pyimport :mediapipe, as: :mp

    #logger.info("Mediapipe detector initiated.")
    @drawing = mp.solutions.drawing_utils
    @drawing_spec = @drawing.DrawingSpec.({thickness: thickness, circle_radius: circle_radius, color: color})
    @drawing_styles = mp.solutions.drawing_styles
    @face_mesh = mp.solutions.face_mesh
    @face_detector = @face_mesh.FaceMesh.({static_image_mode: false, refine_landmarks: true,
                                           min_detection_confidence: min_detection_confidence, min_tracking_confidence: min_tracking_confidence})
    #qp @face_mesh.FACEMESH_LIPS
    #qp @face_mesh.FACEMESH_LIPS.to_a
    @lips = list(@face_mesh.FACEMESH_LIPS)
    @lips = np.ravel(@lips)
    @l_eyes = list(@face_mesh.FACEMESH_LEFT_EYE)
    @l_eyes = np.ravel(@l_eyes)
    @r_eyes = list(@face_mesh.FACEMESH_RIGHT_EYE)
    @r_eyes = np.ravel(@r_eyes)
    @l_eyebrow = list(@face_mesh.FACEMESH_LEFT_EYEBROW)
    @l_eyebrow = np.ravel(@l_eyebrow)
    @r_eyebrow = list(@face_mesh.FACEMESH_RIGHT_EYEBROW)
    @r_eyebrow = np.ravel(@r_eyebrow)
  end
  def detect_faces(image)	# 顔検知を行う
    @img = image
    @results = @face_detector.process(image)
  end
end



