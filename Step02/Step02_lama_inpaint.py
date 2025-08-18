## Made by : ravendev ( dwfree74@naver.com / elca6659@gmail.com)
##           https://github.com/ravendev-team/ravendev-ai 
#
# pip install torch torchvision pillow numpy
#
# **마스크 팽창 → 텐서 변환 → 인페인팅 → 후처리(원본 영역 보존 + 블러링)**까지 통합한 예제 코드
#
# 주요 특징
#   마스크 팽창으로 잔상 영역 넓혀서 더 확실히 제거 유도
#   입력 텐서 16배수 패딩으로 모델 크기 요구사항 대응
#   출력 패딩 제거 후 원본 이미지 영역 유지 → 마스크 밖은 원본 유지
#   경계 블러링으로 잔상 경계 자연스럽게 처리
#   블러 강도(alpha)와 팽창 커널 크기(kernel)는 필요에 따라 조절 가능
#########################################################################
# input 파일 "input/background.png", "input/mask.png"
# input\background.png  복원시킬 배경이미지
# input\mask.png  마스크 이미지 (배경과 객체 중 객체에 대한 마스크임)
# 다운로드파일 : https://huggingface.co/spaces/aryadytm/remove-photo-object/blob/f00f2d12ada635f5f30f18ed74200ea89dd26631/assets/big-lama.pt
# models\big-lama.pt
# config\lama.yaml
#########################################################################
import torch
import cv2
import numpy as np
from PIL import Image

def inpaint_with_lama(image_path, mask_path, model_path="models/big-lama.pt", output_path="lama_output.png"):
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # 1. 이미지 & 마스크 읽기
    image = cv2.imread(image_path)
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    mask = cv2.imread(mask_path, cv2.IMREAD_GRAYSCALE)

    # 2. 마스크 팽창 (잔상 제거 도움)
    kernel = np.ones((7,7), np.uint8)  # 커널 크기 조절 가능
    mask_dilated = cv2.dilate(mask, kernel, iterations=1)

    # 3. 마스크 크기 이미지에 맞춤
    mask_dilated = cv2.resize(mask_dilated, (image.shape[1], image.shape[0]), interpolation=cv2.INTER_NEAREST)

    # 4. 텐서 변환 및 정규화
    image_tensor = torch.from_numpy(image).float().permute(2, 0, 1) / 255.0
    mask_tensor = torch.from_numpy(mask_dilated).float().unsqueeze(0) / 255.0

    image_tensor = image_tensor.unsqueeze(0).to(device)
    mask_tensor = mask_tensor.unsqueeze(0).to(device)

    # 5. 입력 텐서 패딩 함수 (16 배수)
    def pad_to_multiple(t, multiple=16):
        _, _, h, w = t.shape
        pad_h = (multiple - h % multiple) % multiple
        pad_w = (multiple - w % multiple) % multiple
        padding = (0, pad_w, 0, pad_h)  # (left, right, top, bottom)
        return torch.nn.functional.pad(t, padding), padding

    image_tensor, img_pad = pad_to_multiple(image_tensor, 16)
    mask_tensor, mask_pad = pad_to_multiple(mask_tensor, 16)

    # 6. 모델 로드
    print("🔍 Loading LaMa model...")
    model = torch.jit.load(model_path, map_location=device).eval()
    print("✅ Model loaded!")

    # 7. 인페인팅 추론
    with torch.no_grad():
        output = model(image_tensor, mask_tensor)

    # 8. 패딩 제거
    h_pad = img_pad[3]
    w_pad = img_pad[1]
    if h_pad > 0 or w_pad > 0:
        output = output[:, :, :-h_pad if h_pad > 0 else None, :-w_pad if w_pad > 0 else None]

    output_image = output[0].permute(1, 2, 0).cpu().numpy()
    output_image = (output_image * 255).clip(0, 255).astype(np.uint8)

    # 9. 후처리: 원본 영역 보존
    mask_binary = (mask_dilated > 127).astype(np.uint8)
    result = output_image.copy()
    result[mask_binary == 0] = image[mask_binary == 0]

    # 10. 후처리: 경계 부드럽게 블러 (옵션)
    blurred = cv2.GaussianBlur(result, (7,7), 0)
    alpha = 0.3  # 블러 강도, 0 ~ 1 사이
    result = cv2.addWeighted(result, 1 - alpha, blurred, alpha, 0)

    # 11. 결과 저장 (RGB → PIL)
    Image.fromarray(result).save(output_path)
    print(f"🖼️ 복원 결과 저장: {output_path}")


if __name__ == "__main__":
    inpaint_with_lama("input/background.png", "input/debug_full_mask.png")

