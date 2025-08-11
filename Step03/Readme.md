Step03 : 원본이미지에서 영역을 지정하면 그 영역에 emoji 이미지로 모자이크 처리해서 저장합니다.

1. 개발환경

python 3.11

tkinter 기본패키지

Pillow 9.5.0 ( from PIL import Image, ImageDraw, ImageTk 사용을 위해)

numpy 1.26.4

math 기본패키지

os 기본패키지

input.png 와 emoji_dog.png 와 emoji_rabbit.png 는 chatGPT 에서 생성된 이미지

2. input 이미지

<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step03/input/input.png' width=80 height=80 />

3. emoji 이미지

<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step03/emoji_dog.png' width=80 height=80 /> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step03/emoji_rabbit.png' width=80 height=80 />

4. output 이미지

<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/Step03/output.png' width=80 height=80 />
