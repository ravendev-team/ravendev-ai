[ GuidUIdevcpp ]

1. 개발환경 : Embarcadero Dev-Cpp 6.3

https://sourceforge.net/projects/embarcadero-devcpp/

Embarcadero_Dev-Cpp_6.3_TDM-GCC_9.2_Setup.exe 파일 다운받아서 설치.

libgdiplus.a 라이브러리 위치 지정 :  

예시) D:\Embarcadero\Dev-Cpp\TDM-GCC-64\x86_64-w64-mingw32\lib\libgdiplus.a

<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/GuideUIdevcpp/GideUIdevcpp_sc02.png' width=480 height=480 />


* C# 소스코드를 Dev-cpp 버전으로 컨버팅 했습니다.

2. 사용된 이미지파일들

Step01, Step02, Step03, Step04, Step05 의 각 스텝별 input, output 이미지들을

images 폴더에 위치시키고 각 Step 별 상황에 맞게 노드 베이스를 배치 (C# 버전과 images 폴더 위치는 같습니다.)

<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/GuideUIdevcpp/GideUIdevcpp_sc01.png' />

( Step 노드에 한글문자 깨짐증상, gif 이미지 로딩 미지원,  각 노드들 Output 위치 경로 수정 등의 문제가 남아있음 )

이미지 처리 워크플로우 시스템

사용법:

1&#41; 노드를 드래그하여 이동
   
2&#41; 출력 포트에서 입력 포트로 연결

3&#41; 연결선을 우클릭하여 제거

4&#41; 마우스 휠로 확대/축소 

5&#41; 가운데 버튼으로 캔버스 이동 

* 각 단계별로 이미지가 자동 처리됩니다.

