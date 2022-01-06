#!/usr/bin/env python
# from https://qiita.com/YomamaBanana/items/4197c4f9ec26a05416ed

#class Config():
# Config処理クラス

#class Detector():
# 検知器クラス

#class Camera():
# カメラクラス

#def arg_parser():
# 引数管理

#def main():
# メイン関数
#------------------------------------------------------------
#------------------------------------------------------------
#------------------------------------------------------------
#------------------------------------------------------------
#------------------------------------------------------------
#------------------------------------------------------------

# ②モジュールをimportする
# src/face_filter.py
import yaml

import sys
import argparse
from loguru import logger

import cv2
import numpy as np
import mediapipe as mp

# ③Configクラス
# src/face_filter.py
class Config():
    def __init__(self, yaml_file) -> None:
        logger.info(f"Reading config file: {yaml_file}")
        with open(yaml_file, "r") as f:
            self.yaml_cfg = yaml.safe_load(f)

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
    def __call__(self, image):
        self.img = image
        self.results = self.face_detector.process(image)

# 検知した顔に対して色と重みをつけ、後処理を行う。
    def post_processing(self, mask, cfg):
        face_dict = {}
        if self.results.multi_face_landmarks:
            for face_landmarks in self.results.multi_face_landmarks:

                mask_lip = []
                mask_face = []
                mask_l_eyes = []
                mask_r_eyes = []
                mask_l_eyebrow = []
                mask_r_eyebrow = []
                for i in range(self.face_mesh.FACEMESH_NUM_LANDMARKS):

                    if i in self.lips:
                        pt1 = face_landmarks.landmark[i]
                        x = int(pt1.x * self.img.shape[1])
                        y = int(pt1.y * self.img.shape[0])
                        mask_lip.append((x, y))

                    elif i in self.l_eyes:
                        pt1 = face_landmarks.landmark[i]
                        x = int(pt1.x * self.img.shape[1])
                        y = int(pt1.y * self.img.shape[0])

                        mask_l_eyes.append((x, y))

                    elif i in self.r_eyes:
                        pt1 = face_landmarks.landmark[i]
                        x = int(pt1.x * self.img.shape[1])
                        y = int(pt1.y * self.img.shape[0])
                        mask_r_eyes.append((x, y))

                    elif i in self.r_eyebrow:
                        pt1 = face_landmarks.landmark[i]
                        x = int(pt1.x * self.img.shape[1])
                        y = int(pt1.y * self.img.shape[0])
                        mask_r_eyebrow.append((x, y))

                    elif i in self.l_eyebrow:
                        pt1 = face_landmarks.landmark[i]
                        x = int(pt1.x * self.img.shape[1])
                        y = int(pt1.y * self.img.shape[0])
                        mask_l_eyebrow.append((x, y))

                    else:
                        pt1 = face_landmarks.landmark[i]
                        x = int(pt1.x * self.img.shape[1])
                        y = int(pt1.y * self.img.shape[0])
                        mask_face.append((x, y))

            face_dict["mask_lip"] = np.array(mask_lip)
            face_dict["mask_face"] = np.array(mask_face)
            face_dict["mask_l_eyes"] = np.array(mask_l_eyes)
            face_dict["mask_r_eyes"] = np.array(mask_r_eyes)
            face_dict["mask_l_eyebrow"] = np.array(mask_l_eyebrow)
            face_dict["mask_r_eyebrow"] = np.array(mask_r_eyebrow)

            full_mask = mask.copy()

            for part, v in face_dict.items():
                base = mask.copy()
                convexhull = cv2.convexHull(v)
                if "eyes" in part:
                    color = cfg["eyes"]["color"]
                    weight = cfg["eyes"]["weight"]
                elif "eyebrow" in part:
                    color = cfg["eyebrow"]["color"]
                    weight = cfg["eyebrow"]["weight"]

                elif "face" in part:
                    color = cfg["face"]["color"]
                    weight = cfg["face"]["weight"]

                elif "lip" in part:
                    color = cfg["lip"]["color"]
                    weight = cfg["lip"]["weight"]
                else:
                    color = (0, 0, 0)

                base = cv2.fillConvexPoly(base, convexhull, (color[2], color[1], color[0]))

                full_mask = cv2.addWeighted(full_mask, 1, base, weight, 1)
            full_mask = cv2.GaussianBlur(full_mask, (7, 7), 20)
            tmp = cv2.addWeighted(self.img, 1, full_mask, 1, 1)

            return tmp, full_mask
        logger.warning("Face not detected.")
        return self.img, mask

# ⑤画像取得クラス

# カメルを稼働させ、yamlファイルと検知器を読み込む
# src/face_filter.py
class Camera():
    def __init__(self, index, config, detector) -> None:
        self.start(index)
        self.config = config
        self.detector = detector

# 指定したカメルを起動する
    def start(self, index) -> None:
        self.cap = cv2.VideoCapture(index)
        success, frame = self.cap.read()
        if not success:
            logger.error(f"Camera not successful: video input: {index}")
            sys.exit()
        self.mask = np.zeros((frame.shape[0], frame.shape[1], 3), dtype=np.uint8)

    def capture(self) -> None:
        logger.info("Catpuring images from video input... (press 'q' to exit.)")
        while True:
            _, frame = self.cap.read()    
            frame.flags.writeable = False
            # frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

            # 顔検知 
            self.detector(frame)
            frame.flags.writeable = True

            # 後処理を行う。
            frame, mask = self.detector.post_processing(self.mask, self.config.yaml_cfg)

            # 分かりやすくするため、 左右反転を行う。
            frame = cv2.flip(frame, 1)

            # 表示する。
            cv2.imshow("demo", frame)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

        self.cap.release()
        cv2.destroyAllWindows()
        logger.info("Process terminated.")

# ⑥引数管理(argparse)
def arg_parser() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("yaml_file") #yamlファイルの指定
    parser.add_argument("--video", required=True, type=int) #利用するカメル（ビデオ入力）の番号
    args = parser.parse_args()
    return args

# ⑦メイン関数
def main(yaml_file, cam_idx):
    # Config処理
    config = Config(yaml_file)

    # 検知器定義
    detector = Detector()

    # カメル
    CAM = Camera(cam_idx, config, detector)

    # 画像を取得し、フィルターを適用する。
    CAM.capture()

# ⑧実行
# src/face_filter.py
if __name__ == "__main__":
    args = arg_parser()
    main(args.yaml_file, args.video)

