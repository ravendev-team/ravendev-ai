# ravendev-ai
[ 2D이미지로부터의자유 프로젝트 ]

* 폴더설명

[1] Python 소스폴더 : AI 모델을 각각 활용한 소스코드 폴더

Step01 : 원본 이미지에서 배경, 객체, 객체 마스크 이렇게 3개 이미지 분리합니다.

Step02 : 원본 이미지에서 객체가 분리된 배경 이미지와 객체 마스크 이미지를 가지고 배경이미지를 복원(inpainting) 합니다.

Step03 : 원본이미지에서 영역을 지정하면 그 영역에 emoji 이미지로 모자이크 처리해서 저장합니다.

Step04 : Step01 output중 배경이 분리된 객체이미지 1장 -> zero123plus 모델을 사용해서 MultiView 8장의 이미지와 gif 파일을 생성합니다.

Step05 : MultiView 8장의 이미지들로 3D 객체를 생성합니다.

[2] GuideUI 소스폴더 : AI Python 소스코드들 수행후의 input, output 결과물을 한눈에 파악가능한 UI를 각 개발언어 툴 로 컨버전 한 소스코드 폴더 

GuideUI : C# 소스

GuideUIJava : Java 소스

GuideUILaz : Lazarus 소스

GuideUIdevcpp : dev-cpp 소스

GuideUIfor : fortran(g95)  소스

GuideUIPas : pascal (PascalABC.net) 소스


* GuideUI 부연설명

GPU가 아닌 CPU 베이스로 AI 관련 모델과 알고리즘을 적용하다 보니  각 Step별로 실행후 결과물이 오래 걸리는 Step도 있어서

input 이미지들과 output 이미지들을 취합하여서 GuideUI 에서 한눈에 알아보기 쉽게 적용해 봤습니다.


<img src='https://raw.githubusercontent.com/ravendev-team/ravendev-ai/refs/heads/main/GuideUI/GuideUI_2025-08-13.gif' />



[ 검토 AI 관련기술 사이트 리스트 ]

1. Rembg는 이미지 배경을 제거하는 도구입니다.
   
 https://github.com/danielgatis/rembg

2. [NeurIPS 2024] Depth Anything V2. 단안경 깊이 추정을 위한 더욱 향상된 기반 모델
   
 https://github.com/DepthAnything/Depth-Anything-V2
  
3. LaMa 이미지 인페인팅, 푸리에 합성곱을 이용한 해상도 강건 대형 마스크 인페인팅, WACV 2022

https://github.com/advimman/lama

4. Zero123++의 코드 저장소: 단일 이미지에서 일관된 다중 뷰 확산 기본 모델로.

https://github.com/SUDO-AI-3D/zero123plus

5. 대규모 Hunyuan3D 확산 모델을 사용한 고해상도 3D 자산 생성.

https://github.com/Tencent-Hunyuan/Hunyuan3D-2

...


[ 사용된 개발툴 유틸 정보 ]

1. 개발툴

python 3.10 : https://www.python.org/

SharpDevelopment 5.1 C# : https://sourceforge.net/projects/sharpdevelop/

PascalABC.net 3.11 : https://www.pascalabc.net/en/

Lazarus 4.2 : https://sourceforge.net/projects/lazarus/

OpenJDK 11 : https://jdk.java.net/java-se-ri/11 

Embarcadero Dev-Cpp 6.3 : https://sourceforge.net/projects/embarcadero-devcpp/

g95 0.93 ( Fortran ) : g95-Mingw_201210.exe

2. 그래픽 툴

Paint.net : https://www.getpaint.net/

3. 캡쳐 툴

gifcam : https://gifcam.en.softonic.com/?ex=RAMP-3406.5&rex=true





