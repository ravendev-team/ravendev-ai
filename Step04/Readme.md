Step04 : 원본 이미지 1장에서 zero123plus 모델을 사용해서 MultiView 8장의 이미지와 gif 파일을 생성합니다.

1. 개발환경

python 3.10

torch 2.6.0

Pillow 9.5.0 ( from PIL import Image 사용을 위해)

diffusers 0.34.0

requests 2.32.4

pathlib 기본제공

----------------------
[모델 다운로드 방법]

* Hugging Face CLI 설치: pip install huggingface_hub

( huggingface-hub 0.34.1 )

* 모델 다운로드

huggingface-cli download sudo-ai/zero123plus-v1.2 --local-dir ./models/zero123plus-v1.2

( ./models/zero123plus-v1.2 폴더 사이즈 : 5.19 GB )   

huggingface-cli download sudo-ai/zero123plus-pipeline --local-dir ./models/zero123plus-pipeline

( ./models/zero123plus-pipeline 폴더 사이즈 : 20 KB )

* 오류 날때 해결방법

pip install huggingface-hub==0.25.2

pip install "diffusers>=0.29.0"

2. input 이미지

<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step04/input/output_no_bg.png' weight=80 height=80 />

3. output 이미지

multiview <img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step04/360_views/360_view_001_000deg_from_000deg.png' weight=80 height=80 /> 
&nbsp;&nbsp;&nbsp; <img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step04/360_views/360_view_002_045deg_from_060deg.png' weight=80 height=80 />
&nbsp;&nbsp;&nbsp;<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step04/360_views/360_view_003_090deg_from_090deg.png' weight=80 height=80 />
&nbsp;&nbsp;&nbsp;<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step04/360_views/360_view_004_135deg_from_090deg.png' weight=80 height=80 />
&nbsp;&nbsp;&nbsp;<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step04/360_views/360_view_005_180deg_from_180deg.png' weight=80 height=80 />
&nbsp;&nbsp;&nbsp;<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step04/360_views/360_view_006_225deg_from_240deg.png' weight=80 height=80 />
&nbsp;&nbsp;&nbsp;<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step04/360_views/360_view_007_270deg_from_270deg.png' weight=80 height=80 />
&nbsp;&nbsp;&nbsp;<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step04/360_views/360_view_008_315deg_from_000deg.png' weight=80 height=80 />

gif &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; <img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step04/ultrafast_360.gif' weight=80 height=80 />

