#!/usr/bin/env ruby
# coding: utf-8
# Copyright (C) 2022 Koichiro Eto, All rights reserved.
# License: BSD 3-Clause License

#pyimport 'facecamera'
#PyCall.sys.path.append(__dir__)
#fc = PyCall.import_module('facecamera')

def int(n)
  n.to_i
end

class MediaPipeFace
  def initialize
  end

  def main(argv)
    pyimport "facecamera", as: :fc
    pyimport "cv2"
    pyimport "numpy", as: :np

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
    #frame, mask = cam.detector.post_processing(cam.mask, cam.config.yaml_cfg)
    frame, mask = detector_post_processing(cam.detector, cam.mask, cam.config.yaml_cfg)
    mask = cv2.flip(mask, 1)

    cam.v_cam._send(frame)	# 結果を送信する。

    mask = cv2.resize(mask, dsize=[400, 320])	# マスクを表示する。
    cv2.imshow("mask", cv2.cvtColor(mask, cv2.COLOR_BGR2RGB))

    key = cv2.waitKey(1)
    key &= 0xFF
    return false if key == 113 || key == 27
    return true
  end

  def detector_post_processing(s, mask, cfg)
    face_dict = {}
    if s.results.multi_face_landmarks
      for face_landmarks in s.results.multi_face_landmarks
        mask_lip = []
        mask_face = []
        mask_l_eyes = []
        mask_r_eyes = []
        mask_l_eyebrow = []
        mask_r_eyebrow = []
        #qp s.face_mesh.FACEMESH_NUM_LANDMARKS
        #for i in range(s.face_mesh.FACEMESH_NUM_LANDMARKS)
        #for i in s.face_mesh.FACEMESH_NUM_LANDMARKS
        #qp landmarks_num
        for i in 0..s.face_mesh.FACEMESH_NUM_LANDMARKS
          #qp s.lips
          #qp s.lips.class
          #qp lips
          #qp lips.class
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

      face_dict["mask_lip"] = np.array(mask_lip)
      face_dict["mask_face"] = np.array(mask_face)
      face_dict["mask_l_eyes"] = np.array(mask_l_eyes)
      face_dict["mask_r_eyes"] = np.array(mask_r_eyes)
      face_dict["mask_l_eyebrow"] = np.array(mask_l_eyebrow)
      face_dict["mask_r_eyebrow"] = np.array(mask_r_eyebrow)

      full_mask = mask.copy()

      #for part, v in face_dict.items()
      face_dict.each {|part, v|
        base = mask.copy()
        #qp part
        #next if part == "mask_lip"
        convexhull = cv2.convexHull(v)
        if part == "mask_l_eyes" || part == "mask_r_eyes"
          color = cfg["eyes"]["color"]
          weight = cfg["eyes"]["weight"]
        elsif part == "mask_l_eyebrow" || part == "mask_r_eyebrow"
          color = cfg["eyebrow"]["color"]
          weight = cfg["eyebrow"]["weight"]
        elsif part == "mask_face"
          color = cfg["face"]["color"]
          weight = cfg["face"]["weight"]
        elsif part == "mask_lip"
          color = cfg["lip"]["color"]
          weight = cfg["lip"]["weight"]
        else
          color = [0, 0, 0]
        end
        base = cv2.fillConvexPoly(base, convexhull, [color[2], color[1], color[0]])
        #full_mask = cv2.addWeighted(full_mask, 1, base, weight, 1)
        full_mask = cv2.addWeighted(full_mask, 1, base, weight*5, 1)
      }
      #full_mask = cv2.GaussianBlur(full_mask, [7, 7], 20)
      full_mask = cv2.GaussianBlur(full_mask, [39, 9], 10)
      tmp = cv2.addWeighted(s.img, 1, full_mask, 1, 1)

      return tmp, full_mask
    end
    #logger.warning("Face not detected.")
    return s.img, mask
  end
end
