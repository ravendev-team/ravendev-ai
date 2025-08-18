[ GuidUIfor ]

1. 개발환경 : g95 0.93

https://g95.sourceforge.net/
( 현재 이 사이트에서 다운받는거는 무리가 있어 보입니다. )

2. 컴파일 방법

g95 openglw.f03 -S

compile_opengl.bat node_gui03

(예시)

<img src = 'https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/GuideUIfor/GuideUIfor_sc01.png' />

2. 사용된 이미지파일들 <- 현재 jpg, png 이미지 와 gif 파일 보이는 기능은 아직 지원되지 않습니다.

Step01, Step02, Step03, Step04, Step05 의 각 스텝별 input, output 이미지들을

images 폴더에 위치시키고 각 Step 별 상황에 맞게 노드 베이스를 배치 (C# 버전과 images 폴더 위치는 같습니다.)

* png 파일들은 bmp 로 변환해서 저장, gif 파일들은 제외 

<img src = 'https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/GuideUIfor/GuideUIfor_sc02.gif' />


( Step 노드에 문자표시 안됨, 이미지 와 gif 이미지 로딩 미지원, input output 라인 연결기능 제거기능 안됨, 메뉴기능 지원안됨 등의 문제가 남아있음 )

이미지 처리 워크플로우 시스템

사용법:

1&#41; 노드를 드래그하여 이동
   
<s>2&#41; 출력 포트에서 입력 포트로 연결</s>

<s>3&#41; 연결선을 우클릭하여 제거</s>

4&#41; 마우스 휠로 확대/축소 

5&#41; 가운데 버튼으로 캔버스 이동 

* 각 단계별로 이미지가 자동 처리됩니다.
 
