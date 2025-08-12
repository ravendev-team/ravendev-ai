Step05 :  MultiView 8장의 이미지들로 3D 객체를 생성합니다.

1. 개발환경

python 3.10

numpy 1.26.4

Pillow 9.5.0 ( from PIL import Image 사용을 위해)

open3d 0.19.0

math 기본제공

time 기본제공

sys 기본제공

2. input 이미지

multiview <img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step05/input/360_view_001_000deg_from_000deg.png' weight=80 height=80 /> 
&nbsp;&nbsp;&nbsp; <img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step05/input/360_view_002_045deg_from_060deg.png' weight=80 height=80 />
&nbsp;&nbsp;&nbsp;<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step05/input/360_view_003_090deg_from_090deg.png' weight=80 height=80 />
&nbsp;&nbsp;&nbsp;<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step05/input/360_view_004_135deg_from_090deg.png' weight=80 height=80 />
&nbsp;&nbsp;&nbsp;<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step05/input/360_view_005_180deg_from_180deg.png' weight=80 height=80 />
&nbsp;&nbsp;&nbsp;<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step05/input/360_view_006_225deg_from_240deg.png' weight=80 height=80 />
&nbsp;&nbsp;&nbsp;<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step05/input/360_view_007_270deg_from_270deg.png' weight=80 height=80 />
&nbsp;&nbsp;&nbsp;<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step05/input/360_view_008_315deg_from_000deg.png' weight=80 height=80 />

3. output 이미지
<img src='https://github.com/ravendev-team/ravendev-ai/blob/main/Step05/step05_sc_2025-08-11.gif' weight=140 height=140 />

( multiview_poisson_colored.ply 파일을 gif 로 캡쳐해서 보여주는 이미지입니다. )

