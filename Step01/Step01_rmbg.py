## Made by : ravendev ( dwfree74@naver.com / elca6659@gmail.com)
##           https://github.com/ravendev-team/ravendev-ai 
from rembg import remove
from PIL import Image
import numpy as np
import cv2
from ultralytics import YOLO
import os

# 입력 이미지 로드
input_path = './input/input.png'
output_dir = 'output'
background_path = 'output/background.png'
mask_dir = 'output/masks'

# 디렉토리 생성
os.makedirs(output_dir, exist_ok=True)
os.makedirs(mask_dir, exist_ok=True)

# 이미지 열기 및 리사이즈
input_img = Image.open(input_path).convert('RGBA')
input_img_resized = input_img.resize(
    (int(input_img.width * 0.5), int(input_img.height * 0.5)),
    Image.LANCZOS
)
input_array = np.array(input_img_resized)

# 객체 제거 (rembg)
try:
    output_img = remove(input_img_resized, alpha_matting=False)
except MemoryError:
    print("MemoryError occurred. Using minimal settings.")
    output_img = remove(input_img_resized, alpha_matting=False)

output_array = np.array(output_img)

# 전체 투명 배경 이미지 저장
output_img.save(f"{output_dir}/output_no_bg.png")

# YOLOv8로 객체 감지
model = YOLO("./models/yolov8n.pt")
results = model(input_img_resized)

# rembg 전체 마스크 생성 (알파 채널 기준)
alpha_channel = output_array[:, :, 3]
full_mask = (alpha_channel > 20).astype(np.uint8)

# 배경 추출 (객체 제거)
background_array = input_array.copy()
background_array[full_mask == 1] = [0, 0, 0, 0]
background_img = Image.fromarray(background_array)
background_img.save(background_path)

# 디버깅 출력
cv2.imwrite(f"{output_dir}/debug_input_array.png", cv2.cvtColor(input_array, cv2.COLOR_RGBA2BGRA))
cv2.imwrite(f"{mask_dir}/debug_full_mask.png", full_mask * 255)

