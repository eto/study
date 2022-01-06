#!/usr/bin/env python

# https://qiita.com/YomamaBanana/items/cb2c72ffd4bdce374f32
# $ pip3 install numpy opencv-python mediapipe
# $ pip3 install pyyaml

# ①必要なモジュールをimportする
import cv2
import yaml
import numpy as np
import mediapipe as mp
import matplotlib.pyplot as plt

# ②画像データを読み込む
img_path = "face.jpg"	# This image come from https://thispersondoesnotexist.com/

src = cv2.imread(img_path)
#src = cv2.cvtColor(src, cv2.COLOR_BGR2RGB)
img = src.copy()
#plt.imshow(img)
cv2.imwrite("take0.jpg", img)

# ③パラメータを定義し、読み込む
def read_yaml(path):
    """yamlファイルを読み込むための関数
    入力：yamlファイルのパス
    出力：dict形式のデータ
    """
    with open(path, "r") as f:
        cfg = yaml.safe_load(f)
    return cfg

cfg = read_yaml("config/make_up.yaml")

# パーツの数に合わせてプロットを初期化する
# 偶数と奇数に注意！
fig, axs = plt.subplots(len(cfg.keys())//2, 2)
axs = np.ravel(axs)

# パーツをループし、色を描画する
for idx, (part, param) in enumerate(cfg.items()):
    tmp = []
    for _ in range(100):
        tmp.append(param["color"])
    axs[idx].set_title(part)
    axs[idx].imshow(np.reshape(tmp, (10, 10, 3)))

# ④Mediapipeを用いて顔認識を行う
# 検知器のインスタンス化
drawing = mp.solutions.drawing_utils
drawing_spec = drawing.DrawingSpec(thickness=1, circle_radius=1, color=(0, 255, 0))

drawing_styles = mp.solutions.drawing_styles

face_mesh = mp.solutions.face_mesh
face_detector = face_mesh.FaceMesh(min_detection_confidence=0.5, min_tracking_confidence=0.5)

# 検知処理
results = face_detector.process(img)

# 可視化
if results.multi_face_landmarks:
    for face_landmarks in results.multi_face_landmarks:
        drawing.draw_landmarks(
            image=img,
            landmark_list=face_landmarks,
            connections=face_mesh.FACEMESH_TESSELATION,
            connection_drawing_spec=drawing_styles.get_default_face_mesh_tesselation_style()
            )
plt.imshow(img)
cv2.imwrite("take1.jpg", img)

# ⑤パーツを抽出し、マスクを作成する
# マスクの初期化
gray = np.zeros((src.shape[0], src.shape[1], 3), dtype=np.uint8)

# 唇のINDEX
lips = list(face_mesh.FACEMESH_LIPS)
lips = np.ravel(lips)

# 目（左）のINDEX
l_eyes = list(face_mesh.FACEMESH_LEFT_EYE)
l_eyes = np.ravel(l_eyes)

# 目（右）のINDEX
r_eyes = list(face_mesh.FACEMESH_RIGHT_EYE)
r_eyes = np.ravel(r_eyes)

# 眉毛（左）のINDEX
l_eyebrow = list(face_mesh.FACEMESH_LEFT_EYEBROW)
l_eyebrow = np.ravel(l_eyebrow)

# 眉毛（右）のINDEX
r_eyebrow = list(face_mesh.FACEMESH_RIGHT_EYEBROW)
r_eyebrow = np.ravel(r_eyebrow)

# 抽出したパーツをdict形式で保存する
face_dict = {}
if results.multi_face_landmarks:
    for face_landmarks in results.multi_face_landmarks:
        mask_lip = []
        mask_face = []
        mask_l_eyes = []
        mask_r_eyes = []
        mask_l_eyebrow = []
        mask_r_eyebrow = []
        for i in range(face_mesh.FACEMESH_NUM_LANDMARKS):

             # 唇
            if i in lips:
                pt1 = face_landmarks.landmark[i]
                x = int(pt1.x * img.shape[1])
                y = int(pt1.y * img.shape[0])
                mask_lip.append((x, y))

            # 目（左）
            elif i in l_eyes:
                pt1 = face_landmarks.landmark[i]
                x = int(pt1.x * img.shape[1])
                y = int(pt1.y * img.shape[0])
                mask_l_eyes.append((x, y))

            # 目（右）
            elif i in r_eyes:
                pt1 = face_landmarks.landmark[i]
                x = int(pt1.x * img.shape[1])
                y = int(pt1.y * img.shape[0])
                mask_r_eyes.append((x, y))

            # 眉毛（左）  
            elif i in l_eyebrow:
                pt1 = face_landmarks.landmark[i]
                x = int(pt1.x * img.shape[1])
                y = int(pt1.y * img.shape[0])
                mask_l_eyebrow.append((x, y))

            # 眉毛（右）
            elif i in r_eyebrow:
                pt1 = face_landmarks.landmark[i]
                x = int(pt1.x * img.shape[1])
                y = int(pt1.y * img.shape[0])
                mask_r_eyebrow.append((x, y))

            # それ以外の部分
            else:
                pt1 = face_landmarks.landmark[i]
                x = int(pt1.x * img.shape[1])
                y = int(pt1.y * img.shape[0])
                mask_face.append((x, y))

# 描画のためnumpy配列へ変換する
face_dict["mask_lip"] = np.array(mask_lip)
face_dict["mask_face"] = np.array(mask_face)
face_dict["mask_l_eyes"] = np.array(mask_l_eyes)
face_dict["mask_r_eyes"] = np.array(mask_r_eyes)
face_dict["mask_l_eyebrow"] = np.array(mask_l_eyebrow)
face_dict["mask_r_eyebrow"] = np.array(mask_r_eyebrow)

# ⑥抽出したパーツに対して色と重みをつける
# パーツの数に合わせてプロットを初期化する
fig, axs = plt.subplots(2, len(face_dict.keys())//2)
axs = np.ravel(axs)

# パーツの融合のベースマスク
full_mask = gray.copy()

# パーツをループし処理を行う
for idx, (part, v) in enumerate(face_dict.items()):
    # マスクをコピーし初期化する
    mask = gray.copy()

    # パーツの範囲を定義する
    convexhull = cv2.convexHull(v)

    # 色と重みを定義する
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

    # 色を塗る
    mask = cv2.fillConvexPoly(mask, convexhull, color)
    mask = cv2.GaussianBlur(mask, (7, 7), 20)

    # パーツのマスクを全体のマスクに追加していく
    full_mask = cv2.addWeighted(full_mask, 1, mask, weight, 1)

    # 描画する
    axs[idx].set_title(part)
    axs[idx].imshow(mask)

# ⑦融合する
# 入力画像にマスクをかける
result = cv2.addWeighted(full_mask, 1, src, 1, 1)

# 描画する
fig, (ax0, ax1) = plt.subplots(1,2)
ax0.set_title("Before")
ax0.imshow(src)
cv2.imwrite("take2.jpg", src)

ax1.set_title("After")
ax1.imshow(result)
cv2.imwrite("take3.jpg", result)
