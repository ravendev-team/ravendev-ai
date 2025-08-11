
Step01 : 원본 이미지에서 배경, 객체, 객체 마스크 이렇게 3개 이미지 분리합니다.

1. 개발 환경

python 3.10

ultralytics 8.3.158 (yolov8n.pt 모델 사용을 위해)

rembg 2.0.50

numpy 1.26.4

Pillow 9.5.0 ( from PIL import Image 사용을 위해)

opencv-contrib-python        4.11.0.86 (import cv2 사용을 위해)

opencv-python                4.11.0.86 (import cv2 사용을 위해)

opencv-python-headless       4.10.0.84 (import cv2 사용을 위해)

모델 yolov8n.pt file (size = 6,382kb ) download : https://huggingface.co/Ultralytics/YOLOv8/blob/main/yolov8n.pt

2. input 이미지

<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step01/input/input.png' width=80 height=80/>

3. output 이미지

배경 이미지 <img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step01/output/background.png' width=80 height=80 /> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
객체 이미지 <img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step01/output/output_no_bg.png' width=80 height=80 /> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
마스크 이미지 <img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step01/output/masks/debug_full_mask.png' width=80 height=80 /> 



