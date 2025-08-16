Step02 : 원본 이미지에서 객체가 분리된 배경 이미지와 객체 마스크 이미지를 가지고 배경이미지를 복원(inpainting) 합니다.

1. 개발환경

python 3.10

torch                        2.6.0

opencv-contrib-python 4.11.0.86 (import cv2 사용을 위해)

opencv-python 4.11.0.86 (import cv2 사용을 위해)

opencv-python-headless 4.10.0.84 (import cv2 사용을 위해)

numpy 1.26.4

Pillow 9.5.0 ( from PIL import Image 사용을 위해)

모델 big-lama.pt file ( size = 200,850kb ) download : https://huggingface.co/spaces/aryadytm/remove-photo-object/blob/f00f2d12ada635f5f30f18ed74200ea89dd26631/assets/big-lama.pt

ex) 실행 소스코드 폴더의 하위폴더인 models/ 폴더에 복사

모델 u2net.onnx file ( file size : 172,873 KB ) downlod : https://github.com/danielgatis/rembg/releases/download/v0.0.0/u2net.onnx

ex) C:\Users\사용자명\.u2net\ 폴더에 복사


2. input 이미지

배경 이미지 <img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step02/input/background.png' width=80 height=80 /> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 마스크 이미지 <img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step02/input/debug_full_mask.png' width=80 height=80 />

3. output 이미지

배경 복원된 이미지 <img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step02/lama_output.png' width=80 height=80 />
 




