#!/usr/bin/env python3
## Made by : ravendev ( dwfree74@naver.com / elca6659@gmail.com)
##           https://github.com/ravendev-team/ravendev-ai 
##
"""
Zero123++ CPU 기반 예제 - 각 각도별 개별 이미지 저장
사전에 다운로드한 모델 파일을 사용하여 실행

필요한 패키지:
pip install torch diffusers transformers pillow requests rembg

모델 다운로드 방법:
1. Hugging Face CLI 설치: pip install huggingface_hub
2. 모델 다운로드:
   huggingface-cli download sudo-ai/zero123plus-v1.2 --local-dir ./models/zero123plus-v1.2
   huggingface-cli download sudo-ai/zero123plus-pipeline --local-dir ./models/zero123plus-pipeline

오류 날때 해결방법
pip install huggingface-hub==0.25.2
pip install "diffusers>=0.29.0"


또는 git으로 다운로드:
   git lfs install
   git clone https://huggingface.co/sudo-ai/zero123plus-v1.2 ./models/zero123plus-v1.2
   git clone https://huggingface.co/sudo-ai/zero123plus-pipeline ./models/zero123plus-pipeline
"""
# 현재 로서는 이버전이 360 gif 6번 선택이 결과물이 제일 잘나옴.
import torch
import os
import time
from PIL import Image
from diffusers import DiffusionPipeline, EulerAncestralDiscreteScheduler
import requests
from pathlib import Path
import warnings
warnings.filterwarnings("ignore")

def download_sample_image(url, filename):
    """샘플 이미지 다운로드"""
    if not os.path.exists(filename):
        print(f"샘플 이미지 다운로드 중: {filename}")
        response = requests.get(url)
        with open(filename, 'wb') as f:
            f.write(response.content)
        print(f"다운로드 완료: {filename}")
    return filename

def load_pipeline_from_local(model_path, pipeline_path, use_cpu=True):
    """로컬 모델 파일에서 파이프라인 로드"""
    print("파이프라인 로드 중...")
    
    # CPU 사용 설정
    torch_dtype = torch.float32 if use_cpu else torch.float16
    device = "cpu" if use_cpu else "cuda"
    
    try:
        # 로컬 모델 경로에서 파이프라인 로드
        pipeline = DiffusionPipeline.from_pretrained(
            model_path,
            custom_pipeline=pipeline_path,
            torch_dtype=torch_dtype,
            local_files_only=True  # 로컬 파일만 사용
        )
        
        # 스케줄러 설정
        pipeline.scheduler = EulerAncestralDiscreteScheduler.from_config(
            pipeline.scheduler.config,
            timestep_spacing='trailing'
        )
        
        # 디바이스 설정
        pipeline.to(device)
        print(f"파이프라인 로드 완료 (디바이스: {device})")
        return pipeline
        
    except Exception as e:
        print(f"로컬 모델 로드 실패: {e}")
        print("온라인에서 모델을 다운로드합니다...")
        
        # 온라인에서 모델 다운로드
        pipeline = DiffusionPipeline.from_pretrained(
            "sudo-ai/zero123plus-v1.2",
            custom_pipeline="sudo-ai/zero123plus-pipeline",
            torch_dtype=torch_dtype
        )
        
        pipeline.scheduler = EulerAncestralDiscreteScheduler.from_config(
            pipeline.scheduler.config,
            timestep_spacing='trailing'
        )
        
        pipeline.to(device)
        return pipeline

def analyze_multiview_structure(image):
    """멀티뷰 이미지의 구조를 분석하여 정확한 분할 정보 반환"""
    import numpy as np
    
    width, height = image.size
    print(f"전체 이미지 크기: {width} x {height}")
    
    # 이미지를 numpy 배열로 변환
    img_array = np.array(image)
    
    # 그레이스케일로 변환하여 경계 찾기
    if len(img_array.shape) == 3:
        gray = np.mean(img_array, axis=2)
    else:
        gray = img_array
    
    # 수직 분할선 찾기 (열 방향 합계의 변화량 분석)
    col_sums = np.sum(gray, axis=0)
    col_diff = np.abs(np.diff(col_sums))
    
    # 수평 분할선 찾기 (행 방향 합계의 변화량 분석)
    row_sums = np.sum(gray, axis=1)
    row_diff = np.abs(np.diff(row_sums))
    
    # 임계값으로 분할선 후보 찾기
    col_threshold = np.mean(col_diff) + 2 * np.std(col_diff)
    row_threshold = np.mean(row_diff) + 2 * np.std(row_diff)
    
    col_splits = np.where(col_diff > col_threshold)[0]
    row_splits = np.where(row_diff > row_threshold)[0]
    
    print(f"감지된 열 분할선: {len(col_splits)}개")
    print(f"감지된 행 분할선: {len(row_splits)}개")
    
    return col_splits, row_splits

def split_multiview_image_smart(image, rows=2, cols=3):
    """스마트한 멀티뷰 이미지 분할"""
    width, height = image.size
    
    # 구조 분석
    col_splits, row_splits = analyze_multiview_structure(image)
    
    # Zero123++는 보통 정확한 그리드이므로, 균등 분할이 더 안정적
    # 하지만 여백이 있을 수 있으므로 중앙 영역에서 분할
    
    # 여백 추정 (이미지 가장자리의 10% 영역 확인)
    margin_x = int(width * 0.05)  # 좌우 5% 여백
    margin_y = int(height * 0.05)  # 상하 5% 여백
    
    # 실제 콘텐츠 영역
    content_width = width - 2 * margin_x
    content_height = height - 2 * margin_y
    
    # 각 뷰의 크기
    view_width = content_width // cols
    view_height = content_height // rows
    
    print(f"여백 추정: 좌우 {margin_x}px, 상하 {margin_y}px")
    print(f"각 뷰 크기: {view_width} x {view_height}")
    
    views = []
    view_names = [
        "front", "front_right", "right",
        "back", "back_left", "left"
    ]
    
    for row in range(rows):
        for col in range(cols):
            left = margin_x + col * view_width
            top = margin_y + row * view_height
            right = left + view_width
            bottom = top + view_height
            
            # 경계 확인
            left = max(0, left)
            top = max(0, top)
            right = min(width, right)
            bottom = min(height, bottom)
            
            print(f"뷰 {len(views)+1} ({view_names[len(views)]}): ({left}, {top}) to ({right}, {bottom})")
            
            view = image.crop((left, top, right, bottom))
            views.append(view)
    
    return views, view_names

def split_multiview_image_manual(image, grid_info=None):
    """수동으로 그리드 정보를 지정하여 분할"""
    width, height = image.size
    
    if grid_info is None:
        # 기본 Zero123++ 설정
        # 일반적으로 Zero123++는 1024x1024 또는 512x512 크기로 출력
        # 6개 뷰가 2x3 배열로 배치됨
        
        if width == height:  # 정사각형인 경우
            # 정확한 3등분, 2등분
            view_width = width // 3
            view_height = height // 2
            
            grid_info = {
                'view_width': view_width,
                'view_height': view_height,
                'start_x': 0,
                'start_y': 0,
                'cols': 3,
                'rows': 2
            }
        else:
            # 비정사각형인 경우 비율로 계산
            aspect_ratio = width / height
            if aspect_ratio > 1.4:  # 가로가 더 긴 경우 (3:2 비율 추정)
                view_width = width // 3
                view_height = height // 2
            else:  # 세로가 더 긴 경우 (2:3 비율 추정)
                view_width = width // 2
                view_height = height // 3
                grid_info = {
                    'view_width': view_width,
                    'view_height': view_height,
                    'start_x': 0,
                    'start_y': 0,
                    'cols': 2,
                    'rows': 3
                }
            
            if 'cols' not in grid_info:
                grid_info = {
                    'view_width': view_width,
                    'view_height': view_height,
                    'start_x': 0,
                    'start_y': 0,
                    'cols': 3,
                    'rows': 2
                }
    
    print(f"그리드 정보: {grid_info}")
    
    views = []
    view_names = []
    
    # 뷰 이름 설정
    if grid_info['cols'] == 3 and grid_info['rows'] == 2:
        view_names = ["front", "front_right", "right", "back", "back_left", "left"]
    elif grid_info['cols'] == 2 and grid_info['rows'] == 3:
        view_names = ["front", "right", "back", "left", "top", "bottom"]
    else:
        view_names = [f"view_{i+1}" for i in range(grid_info['cols'] * grid_info['rows'])]
    
    for row in range(grid_info['rows']):
        for col in range(grid_info['cols']):
            left = grid_info['start_x'] + col * grid_info['view_width']
            top = grid_info['start_y'] + row * grid_info['view_height']
            right = left + grid_info['view_width']
            bottom = top + grid_info['view_height']
            
            # 경계 확인
            left = max(0, left)
            top = max(0, top)
            right = min(width, right)
            bottom = min(height, bottom)
            
            print(f"뷰 {len(views)+1} ({view_names[len(views)]}): ({left}, {top}) to ({right}, {bottom})")
            
            view = image.crop((left, top, right, bottom))
            views.append(view)
    
    return views, view_names

def save_individual_views(multiview_image, output_prefix="view", output_dir="./outputs", method="auto"):
    """개별 뷰를 각각 저장"""
    # 출력 디렉토리 생성
    os.makedirs(output_dir, exist_ok=True)
    
    print(f"분할 방법: {method}")
    
    # 이미지 크기 출력
    width, height = multiview_image.size
    print(f"입력 이미지 크기: {width} x {height}")
    
    # 분할 방법 선택
    if method == "smart":
        views, view_names = split_multiview_image_smart(multiview_image)
    elif method == "manual":
        views, view_names = split_multiview_image_manual(multiview_image)
    else:  # auto
        # 이미지 크기에 따라 자동 선택
        aspect_ratio = width / height
        print(f"종횡비: {aspect_ratio:.2f}")
        
        if abs(aspect_ratio - 1.5) < 0.1:  # 3:2 비율
            print("3:2 비율 감지 - 2행 3열 그리드로 분할")
            views, view_names = split_multiview_image_manual(multiview_image, {
                'view_width': width // 3,
                'view_height': height // 2,
                'start_x': 0,
                'start_y': 0,
                'cols': 3,
                'rows': 2
            })
        elif abs(aspect_ratio - 0.67) < 0.1:  # 2:3 비율
            print("2:3 비율 감지 - 3행 2열 그리드로 분할")
            views, view_names = split_multiview_image_manual(multiview_image, {
                'view_width': width // 2,
                'view_height': height // 3,
                'start_x': 0,
                'start_y': 0,
                'cols': 2,
                'rows': 3
            })
        elif abs(aspect_ratio - 1.0) < 0.1:  # 정사각형
            print("정사각형 감지 - 스마트 분할 시도")
            views, view_names = split_multiview_image_smart(multiview_image)
        else:
            print("알 수 없는 비율 - 기본 2x3 분할 적용")
            views, view_names = split_multiview_image_manual(multiview_image)
    
    saved_files = []
    print(f"총 {len(views)}개의 뷰를 개별 파일로 저장 중...")
    
    for i, (view, name) in enumerate(zip(views, view_names)):
        filename = f"{output_prefix}_{i+1:02d}_{name}.png"
        filepath = os.path.join(output_dir, filename)
        view.save(filepath)
        saved_files.append(filepath)
        print(f"저장 완료: {filepath} (크기: {view.size})")
    
    return saved_files

def generate_multiview_images(pipeline, input_image_path, output_path="output.png", output_prefix="view", num_steps=28, split_method="auto"):
    """멀티뷰 이미지 생성 및 개별 저장"""
    print(f"입력 이미지 로드: {input_image_path}")
    
    # 이미지 로드 및 전처리
    cond_image = Image.open(input_image_path)
    
    # 정사각형으로 리사이즈 (권장: 320x320 이상)
    size = max(cond_image.size)
    if size < 320:
        size = 320
    
    # 정사각형으로 만들기
    cond_image = cond_image.resize((size, size), Image.Resampling.LANCZOS)
    
    print(f"이미지 크기: {cond_image.size}")
    print(f"추론 단계: {num_steps}")
    print("멀티뷰 이미지 생성 중... (CPU에서는 시간이 오래 걸릴 수 있습니다)")
    
    # 멀티뷰 이미지 생성
    with torch.no_grad():
        result = pipeline(cond_image, num_inference_steps=num_steps).images[0]
    
    # 전체 멀티뷰 이미지 저장
    result.save(output_path)
    print(f"멀티뷰 전체 결과 저장: {output_path}")
    
    # 개별 뷰 저장
    individual_files = save_individual_views(result, output_prefix, method=split_method)
    
    return result, individual_files

def remove_background_from_views(view_files, output_suffix="_no_bg"):
    """각 뷰에서 배경 제거 (옵션)"""
    try:
        import rembg
        print("각 뷰에서 배경 제거 중...")
        
        no_bg_files = []
        for view_file in view_files:
            # 파일명에서 확장자 분리
            base_name = os.path.splitext(view_file)[0]
            no_bg_file = f"{base_name}{output_suffix}.png"
            
            # 이미지 로드
            image = Image.open(view_file)
            
            # 배경 제거
            result = rembg.remove(image)
            result.save(no_bg_file)
            no_bg_files.append(no_bg_file)
            print(f"배경 제거 완료: {no_bg_file}")
        
        return no_bg_files
        
    except ImportError:
        print("rembg가 설치되지 않았습니다. 배경 제거를 건너뜁니다.")
        print("설치 방법: pip install rembg")
        return []

def generate_360_views_optimized(pipeline, input_image_path, num_views=8, num_steps=12, output_dir="./360_views"):
    """최적화된 360도 회전 뷰 생성 (빠른 추론 + 스마트 매핑)"""
    print(f"최적화된 360도 회전 뷰 생성 - {num_views}개 각도 (빠른 추론: {num_steps} 단계)")
    
    # 이미지 로드 및 전처리
    cond_image = Image.open(input_image_path)
    size = max(cond_image.size)
    if size < 320:
        size = 320
    cond_image = cond_image.resize((size, size), Image.Resampling.LANCZOS)
    
    # 출력 디렉토리 생성
    os.makedirs(output_dir, exist_ok=True)
    
    print("기본 6개 뷰 생성 중... (1회 실행)")
    start_time = time.time()
    
    # Zero123++ 한 번만 실행해서 6개 뷰 생성
    with torch.no_grad():
        result = pipeline(cond_image, num_inference_steps=num_steps).images[0]
    
    generation_time = time.time() - start_time
    print(f"생성 완료! 소요 시간: {generation_time:.1f}초")
    
    # 6개 뷰 분할
    views, view_names = split_multiview_image_manual(result)
    zero123_angles = [0, 60, 90, 180, 240, 270]  # Zero123++의 실제 각도들
    
    # 360도를 num_views로 분할하여 각 각도에 가장 가까운 뷰 매핑
    angle_step = 360 / num_views
    generated_views = []
    
    print(f"6개 기본 뷰를 {num_views}개 각도로 매핑 중...")
    
    for i in range(num_views):
        angle = i * angle_step
        
        # 현재 각도와 가장 가까운 뷰 찾기
        closest_idx = min(range(len(zero123_angles)), 
                         key=lambda x: min(abs(zero123_angles[x] - angle), 
                                          abs(zero123_angles[x] - angle + 360),
                                          abs(zero123_angles[x] - angle - 360)))
        
        selected_view = views[closest_idx]
        actual_angle = zero123_angles[closest_idx]
        
        # 파일 저장
        filename = f"360_view_{i+1:03d}_{angle:03.0f}deg_from_{actual_angle:03.0f}deg.png"
        filepath = os.path.join(output_dir, filename)
        selected_view.save(filepath)
        generated_views.append(filepath)
        
        print(f"각도 {angle:03.0f}° -> {actual_angle:03.0f}° 뷰 사용: {filename}")
    
    return generated_views

def generate_smart_360_views(pipeline, input_image_path, num_rotations=2, num_steps=10, output_dir="./smart_360"):
    """스마트 360도 뷰 생성 (여러 번 빠른 실행 + 보간)"""
    print(f"스마트 360도 뷰 생성 - {num_rotations}번 실행, 각 {num_steps} 단계")
    
    # 이미지 로드 및 전처리  
    cond_image = Image.open(input_image_path)
    size = max(cond_image.size)
    if size < 320:
        size = 320
    cond_image = cond_image.resize((size, size), Image.Resampling.LANCZOS)
    
    os.makedirs(output_dir, exist_ok=True)
    
    all_views = {}  # angle -> (view_image, confidence)
    
    print(f"총 {num_rotations}번의 빠른 실행으로 다양한 뷰 수집...")
    
    for rotation in range(num_rotations):
        print(f"\n실행 {rotation + 1}/{num_rotations} (추론 단계: {num_steps})")
        start_time = time.time()
        
        # 빠른 추론으로 실행
        with torch.no_grad():
            result = pipeline(cond_image, num_inference_steps=num_steps).images[0]
        
        exec_time = time.time() - start_time
        print(f"실행 완료: {exec_time:.1f}초")
        
        # 뷰 분할
        views, view_names = split_multiview_image_manual(result)
        zero123_angles = [0, 60, 90, 180, 240, 270]
        
        # 각 뷰를 컬렉션에 추가
        for i, (view, angle) in enumerate(zip(views, zero123_angles)):
            if angle not in all_views:
                all_views[angle] = []
            all_views[angle].append(view)
    
    # 각 각도별로 최고 품질 뷰 선택 (여러 실행 결과 중)
    print(f"\n수집된 뷰: {len(all_views)}개 각도")
    final_views = []
    
    for angle in sorted(all_views.keys()):
        # 여러 실행 결과가 있다면 첫 번째 사용 (품질 평가 로직 추가 가능)
        best_view = all_views[angle][0]
        
        filename = f"smart_360_{angle:03.0f}deg.png" 
        filepath = os.path.join(output_dir, filename)
        best_view.save(filepath)
        final_views.append(filepath)
        
        print(f"저장: {filename} ({len(all_views[angle])}개 후보 중 선택)")
    
    return final_views

def create_interpolated_360(view_files, output_dir="./interpolated_360", frames_between=3):
    """기존 뷰들 사이에 보간 프레임 추가로 더 부드러운 360도"""
    print(f"뷰 보간으로 부드러운 360도 생성 (뷰 사이에 {frames_between}프레임 추가)")
    
    os.makedirs(output_dir, exist_ok=True)
    
    # 이미지 로드
    images = [Image.open(f) for f in view_files]
    
    interpolated_files = []
    
    for i in range(len(images)):
        # 현재 이미지 저장
        current_filename = f"smooth_360_{i*frames_between:03d}.png"
        current_path = os.path.join(output_dir, current_filename)
        images[i].save(current_path)
        interpolated_files.append(current_path)
        
        # 다음 이미지와의 보간 프레임들
        next_i = (i + 1) % len(images)
        
        for frame in range(1, frames_between):
            alpha = frame / frames_between
            blended = Image.blend(images[i], images[next_i], alpha)
            
            frame_filename = f"smooth_360_{i*frames_between + frame:03d}.png"
            frame_path = os.path.join(output_dir, frame_filename)
            blended.save(frame_path)
            interpolated_files.append(frame_path)
    
    print(f"보간 완료: {len(interpolated_files)}개 프레임")
    return interpolated_files

def generate_custom_angle_views(pipeline, input_image_path, custom_angles, num_steps=28, output_dir="./custom_views"):
    """사용자 지정 각도로 뷰 생성"""
    print(f"사용자 지정 각도 뷰 생성: {custom_angles}")
    
    # 이미지 로드 및 전처리
    cond_image = Image.open(input_image_path)
    size = max(cond_image.size)
    if size < 320:
        size = 320
    cond_image = cond_image.resize((size, size), Image.Resampling.LANCZOS)
    
    # 출력 디렉토리 생성
    os.makedirs(output_dir, exist_ok=True)
    
    # Zero123++ 한 번 실행으로 6개 뷰 생성
    print("기본 6개 뷰 생성 중...")
    with torch.no_grad():
        result = pipeline(cond_image, num_inference_steps=num_steps).images[0]
    
    views, view_names = split_multiview_image_manual(result)
    zero123_angles = [0, 60, 90, 180, 240, 270]  # Zero123++의 실제 각도들
    
    generated_views = []
    
    for angle in custom_angles:
        # 현재 각도와 가장 가까운 뷰 찾기
        closest_idx = min(range(len(zero123_angles)), 
                         key=lambda x: min(abs(zero123_angles[x] - angle), 
                                          abs(zero123_angles[x] - angle + 360),
                                          abs(zero123_angles[x] - angle - 360)))
        
        selected_view = views[closest_idx]
        actual_angle = zero123_angles[closest_idx]
        
        # 파일 저장
        filename = f"custom_view_{angle:03.0f}deg_actual_{actual_angle:03.0f}deg.png"
        filepath = os.path.join(output_dir, filename)
        selected_view.save(filepath)
        generated_views.append(filepath)
        
        print(f"각도 {angle}° 요청 -> {actual_angle}° 뷰 사용: {filepath}")
    
    return generated_views

def interpolate_views(view1, view2, num_frames=10, output_dir="./interpolated"):
    """두 뷰 사이를 부드럽게 보간 (간단한 블렌딩)"""
    os.makedirs(output_dir, exist_ok=True)
    
    interpolated_files = []
    
    for i in range(num_frames):
        alpha = i / (num_frames - 1)  # 0.0 to 1.0
        
        # 간단한 알파 블렌딩
        blended = Image.blend(view1, view2, alpha)
        
        filename = f"interpolated_{i+1:03d}_alpha_{alpha:.2f}.png"
        filepath = os.path.join(output_dir, filename)
        blended.save(filepath)
        interpolated_files.append(filepath)
    
    return interpolated_files

def create_360_gif(view_files, output_path="360_rotation.gif", duration=200):
    """360도 뷰들로 GIF 애니메이션 생성"""
    images = [Image.open(f) for f in view_files]
    
    # GIF 생성
    images[0].save(
        output_path,
        save_all=True,
        append_images=images[1:],
        duration=duration,  # milliseconds per frame
        loop=0  # infinite loop
    )
    
    print(f"360도 회전 GIF 생성 완료: {output_path}")
    return output_path
def remove_background(image, output_path="output_no_bg.png"):
    """배경 제거 (전체 멀티뷰 이미지용)"""
    try:
        import rembg
        print("배경 제거 중...")
        result = rembg.remove(image)
        result.save(output_path)
        print(f"배경 제거 결과 저장: {output_path}")
        return result
    except ImportError:
        print("rembg가 설치되지 않았습니다. 배경 제거를 건너뜁니다.")
        print("설치 방법: pip install rembg")
        return image

def demo_360_generation(model_path = "./models/zero123plus-v1.2",pipeline_path = "./models/zero123plus-pipeline", input_image = "input_sample.png"):
    """360도 뷰 생성 데모 - 최적화된 버전"""
    ## 모델 경로 설정
    #model_path = "./models/zero123plus-v1.2"
    #pipeline_path = "./models/zero123plus-pipeline"
    #input_image = "input_sample.png"
    
    # 파이프라인 로드
    print("파이프라인 로드 중...")
    pipeline = load_pipeline_from_local(model_path, pipeline_path, use_cpu=True)
    
    print("\n=== 빠른 360도 회전 뷰 생성 옵션 ===")
    print("1. 기본 6개 뷰 (1회 실행, ~2-3분)")
    print("2. 빠른 8각도 360도 (1회 실행 + 매핑, ~2-3분)")
    print("3. 빠른 12각도 360도 (1회 실행 + 매핑, ~2-3분)")
    print("4. 스마트 360도 (2-3회 빠른 실행, ~5-8분)")
    print("5. 부드러운 360도 GIF (보간 추가, ~2-5분)")
    print("6. 초고속 360도 (8 단계, ~1-2분)")
    
    choice = "6" #input("선택하세요 (1-6): ").strip()
    
    if choice == "1":
        # 기본 6개 뷰 (28단계)
        print("기본 품질로 6개 뷰 생성 중...")
        result, individual_files = generate_multiview_images(
            pipeline, input_image, split_method="auto", num_steps=20
        )
        print("기본 6개 뷰 생성 완료!")
        
    elif choice == "2":
        # 빠른 8각도 (1회 실행)
        print("빠른 8각도 360도 뷰 생성 중...")
        view_files = generate_360_views_optimized(pipeline, input_image, 
                                                 num_views=8, num_steps=12)
        print(f"빠른 8각도 뷰 생성 완료! 파일: {len(view_files)}개")
        
    elif choice == "3":
        # 빠른 12각도 (1회 실행)
        print("빠른 12각도 360도 뷰 생성 중...")
        view_files = generate_360_views_optimized(pipeline, input_image, 
                                                 num_views=12, num_steps=12)
        print(f"빠른 12각도 뷰 생성 완료! 파일: {len(view_files)}개")
        
    elif choice == "4":
        # 스마트 360도 (2-3회 빠른 실행)
        print("스마트 360도 뷰 생성 중...")
        view_files = generate_smart_360_views(pipeline, input_image, 
                                            num_rotations=2, num_steps=10)
        print(f"스마트 360도 뷰 생성 완료! 파일: {len(view_files)}개")
        
    elif choice == "5":
        # 부드러운 GIF
        print("부드러운 360도 GIF 생성 중...")
        base_views = generate_360_views_optimized(pipeline, input_image, 
                                                num_views=6, num_steps=15)
        smooth_views = create_interpolated_360(base_views, frames_between=2)
        gif_path = create_360_gif(smooth_views, "smooth_360_rotation.gif", duration=150)
        print(f"부드러운 360도 GIF 생성 완료: {gif_path}")
        
    elif choice == "6":
        # 초고속 (8단계)
        print("초고속 360도 뷰 생성 중...")
        view_files = generate_360_views_optimized(pipeline, input_image, 
                                                 num_views=8, num_steps=8) # num_views=8 ,추론을 8->28 로 수
        gif_path = create_360_gif(view_files, "ultrafast_360.gif", duration=400)
        print(f"초고속 360도 완료! 뷰: {len(view_files)}개, GIF: {gif_path}")
        
    else:
        print("잘못된 선택입니다.")
        return

def main(model_path = "./models/zero123plus-v1.2", pipeline_path = "./models/zero123plus-pipeline", input_image = "input_sample.png" ):
    """메인 실행 함수"""
    ## 모델 경로 설정
    #model_path = "./models/zero123plus-v1.2"
    #pipeline_path = "./models/zero123plus-pipeline"
    
    # 모델 파일 존재 확인
    if not os.path.exists(model_path):
        print(f"모델 경로가 존재하지 않습니다: {model_path}")
        print("다음 명령어로 모델을 다운로드하세요:")
        print("huggingface-cli download sudo-ai/zero123plus-v1.2 --local-dir ./models/zero123plus-v1.2")
        print("또는 온라인에서 자동 다운로드를 시도합니다...")
    
    # 샘플 이미지 다운로드
    #sample_url = "https://d.skis.ltd/nrp/sample-data/lysol.png"
    #input_image = "input_sample.png" #download_sample_image(sample_url, "input_sample.png")
    
    # 파이프라인 로드
    pipeline = load_pipeline_from_local(model_path, pipeline_path, use_cpu=True)
    
    # 멀티뷰 이미지 생성 및 개별 저장
    # split_method 옵션: "auto", "smart", "manual"
    # "auto": 이미지 크기 비율에 따라 자동 선택
    # "smart": 이미지 분석을 통한 여백 고려 분할
    # "manual": 정확한 그리드 분할
    result, individual_files = generate_multiview_images(
        pipeline, 
        input_image, 
        output_path="multiview_output.png",
        output_prefix="view",
        num_steps=28,  # CPU에서는 적은 단계 사용 권장
        split_method="auto"  # 분할 방법 선택
    )
    
    # 전체 멀티뷰 이미지 배경 제거 (옵션)
    remove_background(result, "multiview_output_no_bg.png")
    
    # 각 개별 뷰에서 배경 제거 (옵션)
    no_bg_files = remove_background_from_views(individual_files)
    
    print("\n완료! 생성된 파일들:")
    print("- multiview_output.png: 전체 멀티뷰 결과")
    print("- multiview_output_no_bg.png: 전체 멀티뷰 배경 제거 결과 (rembg 설치 시)")
    print("\n개별 뷰 파일들:")
    for file in individual_files:
        print(f"- {file}")
    
    if no_bg_files:
        print("\n배경 제거된 개별 뷰 파일들:")
        for file in no_bg_files:
            print(f"- {file}")

# 모델 파일 다운로드 스크립트
def download_models():
    """모델 파일 다운로드 헬퍼 함수"""
    try:
        from huggingface_hub import snapshot_download
        
        print("Zero123++ 모델 다운로드 중...")
        snapshot_download(
            repo_id="sudo-ai/zero123plus-v1.2",
            local_dir="./models/zero123plus-v1.2",
            local_dir_use_symlinks=False
        )
        
        print("Zero123++ 파이프라인 다운로드 중...")
        snapshot_download(
            repo_id="sudo-ai/zero123plus-pipeline", 
            local_dir="./models/zero123plus-pipeline",
            local_dir_use_symlinks=False
        )
        
        print("모델 다운로드 완료!")
        
    except ImportError:
        print("huggingface_hub가 설치되지 않았습니다.")
        print("설치 방법: pip install huggingface_hub")
    except Exception as e:
        print(f"다운로드 실패: {e}")

if __name__ == "__main__":
    # 모델 다운로드가 필요한 경우 주석 해제
    # download_models()
    model_path = "./models/zero123plus-v1.2"
    pipeline_path = "./models/zero123plus-pipeline"
    input_image = "./input/output_no_bg.png"
    
    print("Zero123++ 실행 모드를 선택하세요:")
    print("1. 기본 멀티뷰 생성 (6개 뷰)")
    print("2. 360도 회전 뷰 생성 (대화형)")
    
    mode = "2" #input("모드 선택 (1 또는 2): ").strip()
    
    if mode == "2":
        #demo_360_generation()
        demo_360_generation(model_path, pipeline_path, input_image)
    else:
        # 기본 메인 실행
        #main()
        main(model_path, pipeline_path, input_image)

