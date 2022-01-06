#!/usr/bin/env ruby
# coding: utf-8
# Copyright (C) 2022 Koichiro Eto, All rights reserved.
# License: BSD 3-Clause License

class MediaPipeFace
  def initialize
    @running = true
    @cap = nil
    @face_mesh = nil
  end

  def main(argv)
    pyimport 'cv2', as: 'cv2'
    pyimport 'mediapipe', as: 'mp'

    @mp_drawing = mp.solutions.drawing_utils
    @mp_drawing_styles = mp.solutions.drawing_styles
    @mp_face_mesh = mp.solutions.face_mesh

    # For webcam input:
    drawing_spec = @mp_drawing.DrawingSpec.(thickness=1, circle_radius=1)
    @cap = cv2.VideoCapture.(0)

    @face_mesh = @mp_face_mesh.FaceMesh.({max_num_faces: 1,
                                          refine_landmarks: true,
                                          min_detection_confidence: 0.5,
                                          min_tracking_confidence: 0.5})

    loop {
      mainloop
      break unless @running
    }
    @cap.release()
  end

  def mainloop
    unless @cap.isOpened()
      @running = false
      return
    end

    success, image = @cap.read()
    unless success
      print("Ignoring empty camera frame.")
      #@running = false
      return
    end

    # To improve performance, optionally mark the image as not writeable to pass by reference.
    image.flags.writeable = false
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    results = @face_mesh.process(image)

    image = draw_face(image, results)	# Draw the face mesh annotations on the image.

    # Flip the image horizontally for a selfie-view display.
    cv2.imshow('MediaPipe Face Mesh', cv2.flip(image, 1))
    if cv2.waitKey(5) & 0xFF == 27
      @running = false
      return
    end
  end

  def draw_face(image, results)	# Draw the face mesh annotations on the image.
    image.flags.writeable = true
    image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)
    if results.multi_face_landmarks
      for face_landmarks in results.multi_face_landmarks
        #draw_tesselation(image, face_landmarks)
        #draw_contour(image, face_landmarks)
        draw_irises(image, face_landmarks)
      end
    end
    return image
  end
  def draw_tesselation(image, face_landmarks)
    @mp_drawing.draw_landmarks({image: image,
                                landmark_list: face_landmarks,
                                connections: @mp_face_mesh.FACEMESH_TESSELATION,
                                landmark_drawing_spec: nil,
                                connection_drawing_spec: @mp_drawing_styles.get_default_face_mesh_tesselation_style()})
  end
  def draw_contour(image, face_landmarks)
    @mp_drawing.draw_landmarks({image: image,
                                landmark_list: face_landmarks,
                                connections: @mp_face_mesh.FACEMESH_CONTOURS,
                                landmark_drawing_spec: nil,
                                connection_drawing_spec: @mp_drawing_styles.get_default_face_mesh_contours_style()})
  end
  def draw_irises(image, face_landmarks)
    #qp face_landmarks
    # landmark {
    #   x: 0.561671257019043
    #   y: 0.8560786247253418
    #   z: 0.007543095853179693
    # }

    #pp @mp_face_mesh.FACEMESH_IRISES
    # frozenset({(475, 476), (477, 474), (469, 470), (472, 469), (471, 472), (474, 475), (476, 477), (470, 471)})

    #pp @mp_drawing_styles.get_default_face_mesh_iris_connections_style().to_h
    # {(476, 477)=>DrawingSpec(color=(48, 255, 48), thickness=2, circle_radius=2),
    #  (475, 476)=>DrawingSpec(color=(48, 255, 48), thickness=2, circle_radius=2),
    #  (477, 474)=>DrawingSpec(color=(48, 255, 48), thickness=2, circle_radius=2),
    #  (474, 475)=>DrawingSpec(color=(48, 255, 48), thickness=2, circle_radius=2),
    #  (469, 470)=>DrawingSpec(color=(48, 48, 255), thickness=2, circle_radius=2),
    #  (472, 469)=>DrawingSpec(color=(48, 48, 255), thickness=2, circle_radius=2),
    #  (471, 472)=>DrawingSpec(color=(48, 48, 255), thickness=2, circle_radius=2),
    #  (470, 471)=>DrawingSpec(color=(48, 48, 255), thickness=2, circle_radius=2)}

    hash = {image: image,
            landmark_list: face_landmarks,
            connections: @mp_face_mesh.FACEMESH_IRISES,
            landmark_drawing_spec: nil,
            connection_drawing_spec: @mp_drawing_styles.get_default_face_mesh_iris_connections_style()}
    @mp_drawing.draw_landmarks(hash)
  end
end
