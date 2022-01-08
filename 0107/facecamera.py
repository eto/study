#!/usr/bin/env python
# from https://qiita.com/YomamaBanana/items/4197c4f9ec26a05416ed

# ②モジュールをimportする
#import yaml

import sys
import argparse
from loguru import logger

import cv2
import numpy as np
import mediapipe as mp

import pyvirtualcam

# VirtualCameraクラス
class VirtualCamera():
    def __init__(self, width, height, fps) -> None:
        self.v_cam = pyvirtualcam.Camera(width=width, height=height, fps=fps)

    def _send(self, image):
        self.v_cam.send(image)
        self.v_cam.sleep_until_next_frame()

# ④検知器クラス
# Mediapipeのインスタンス化
# src/face_filter.py
class Detector():
    def __init__(self, thickness=1, circle_radius=1, color=(255,0,255), min_detection_confidence=0.5, min_tracking_confidence=0.5) -> None:
        # Mediapipeのインスタンス化
        logger.info("Mediapipe detector initiated.")
        self.drawing = mp.solutions.drawing_utils
        self.drawing_spec = self.drawing.DrawingSpec(
            thickness=thickness, 
            circle_radius=circle_radius, 
            color=color)

        self.drawing_styles = mp.solutions.drawing_styles
        self.face_mesh = mp.solutions.face_mesh

        self.face_detector = self.face_mesh.FaceMesh(
            static_image_mode=False,
            refine_landmarks=True,
            min_detection_confidence=min_detection_confidence,
            min_tracking_confidence=min_tracking_confidence)

        self._parts_init()

# 顔のバーツの指定
    def _parts_init(self) -> None:
        self.lips = list(self.face_mesh.FACEMESH_LIPS)
        self.lips = np.ravel(self.lips)

        self.l_eyes = list(self.face_mesh.FACEMESH_LEFT_EYE)
        self.l_eyes = np.ravel(self.l_eyes)

        self.r_eyes = list(self.face_mesh.FACEMESH_RIGHT_EYE)
        self.r_eyes = np.ravel(self.r_eyes)

        self.l_eyebrow = list(self.face_mesh.FACEMESH_LEFT_EYEBROW)
        self.l_eyebrow = np.ravel(self.l_eyebrow)

        self.r_eyebrow = list(self.face_mesh.FACEMESH_RIGHT_EYEBROW)
        self.r_eyebrow = np.ravel(self.r_eyebrow)

# 顔検知を行う
#   def nu__call__(self, image):
    def detect_faces(self, image):
        self.img = image
        self.results = self.face_detector.process(image)

class Camera():
    # 画像サイズを同調させるため、予め横軸を定義する。
    def __init__(self, index, config, detector, width:int=1280, height:int=720, fps:int=30) -> None:
        self.config = config
        self.detector = detector

        self.width = width
        self.height = height
        self.fps = fps

        self.start(index)

    def start(self, index) -> None:
        self.cap = cv2.VideoCapture(index)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
        success, frame = self.cap.read()
        if not success:
            logger.error(f"Camera not successful: video input: {index}")
            sys.exit()
        self.mask = np.zeros((frame.shape[0], frame.shape[1], 3), dtype=np.uint8)

        #　仮想カメラを始動する。
        self.v_cam = VirtualCamera(width=self.width, height=self.height, fps=self.fps)

