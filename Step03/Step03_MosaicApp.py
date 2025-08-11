import tkinter as tk
from tkinter import filedialog
from PIL import Image, ImageDraw, ImageTk
import numpy as np
import math
import os

class MosaicApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Emoji Mosaic GUI (File Selection)")

        # 파일 경로
        self.input_image_path = ""  # 동적으로 설정
        self.emoji_image_path = "emoji_rabbit.png"  # emoji_dog.png 와 emoji_rabbit.png 는 chatGPT 에서 생성된 이미지입니다.
        self.output_image_path = "output.png"

        # GUI 요소
        self.canvas_width = 600  # 800
        self.canvas_height = 400 # 600
        self.canvas = tk.Canvas(root, width=self.canvas_width, height=self.canvas_height, bg="white")
        self.canvas.pack(pady=10)

        self.load_button = tk.Button(root, text="Load Image", command=self.load_image)
        self.load_button.pack(pady=5)

        self.apply_button = tk.Button(root, text="Apply Mosaic", command=self.apply_mosaic)
        self.apply_button.pack(pady=5)

        self.clear_button = tk.Button(root, text="Clear Drawing", command=self.clear_drawing)
        self.clear_button.pack(pady=5)

        # 이미지 및 그리기 변수
        self.input_pil = None  # 원본 해상도 이미지
        self.display_pil = None  # 캔버스 표시용 축소 이미지
        self.photo = None
        self.draw_pil = None  # 캔버스 크기의 그리기 레이어
        self.draw = None
        self.brush_size = 10
        self.drawing = False
        self.original_width = 0
        self.original_height = 0
        self.scale_x = 1.0
        self.scale_y = 1.0
        self.canvas_offset_x = 0
        self.canvas_offset_y = 0
        self.display_width = 0
        self.display_height = 0

        # 캔버스 이벤트 바인딩
        self.canvas.bind("<B1-Motion>", self.paint)
        self.canvas.bind("<ButtonPress-1>", self.start_paint)
        self.canvas.bind("<ButtonRelease-1>", self.stop_paint)

    def load_image(self):
        # 파일 대화상자에서 PNG, JPG 파일 선택
        file_path = filedialog.askopenfilename(
            initialdir = "./",
            title = "Select Image File",
            filetypes = [("Image files", "*.png *.jpg *.jpeg")]
        )
        if not file_path:
            print("No file selected")
            return

        # 선택한 파일 경로 저장
        self.input_image_path = file_path
        if not os.path.exists(self.input_image_path):
            print(f"Error: {self.input_image_path} not found")
            return

        try:
            # 원본 이미지 로드
            self.input_pil = Image.open(self.input_image_path).convert("RGB")
            self.original_width, self.original_height = self.input_pil.size
            print(f"Original image size: {self.original_width}x{self.original_height}")

            # 캔버스 표시용 축소 이미지 (비율 유지)
            scale = min(self.canvas_width / self.original_width, self.canvas_height / self.original_height)
            self.display_width = int(self.original_width * scale)
            self.display_height = int(self.original_height * scale)
            self.display_pil = self.input_pil.resize((self.display_width, self.display_height), Image.LANCZOS)

            # 스케일링 비율 계산 (표시 이미지 기준)
            self.scale_x = self.display_width / self.original_width
            self.scale_y = self.display_height / self.original_height

            # 캔버스 중앙에 이미지 정렬
            self.canvas_offset_x = (self.canvas_width - self.display_width) // 2
            self.canvas_offset_y = (self.canvas_height - self.display_height) // 2
            self.photo = ImageTk.PhotoImage(self.display_pil)
            self.canvas.create_image(self.canvas_offset_x, self.canvas_offset_y, anchor="nw", image=self.photo)
            print(f"Display image size: ({self.display_width}, {self.display_height}), Offset: x={self.canvas_offset_x}, y={self.canvas_offset_y}, Scale: x={self.scale_x:.4f}, y={self.scale_y:.4f}")

            # 그리기 레이어 초기화 (캔버스 표시 이미지 크기)
            self.draw_pil = Image.new("RGBA", (self.display_width, self.display_height), (0, 0, 0, 0))
            self.draw = ImageDraw.Draw(self.draw_pil)
        except Exception as e:
            print(f"Error loading image: {e}")

    def start_paint(self, event):
        self.drawing = True
        self.paint(event)

    def paint(self, event):
        if not self.drawing or not self.input_pil:
            return

        # 캔버스 오프셋 보정
        x = event.x - self.canvas_offset_x
        y = event.y - self.canvas_offset_y
        if x < 0 or y < 0 or x >= self.draw_pil.size[0] or y >= self.draw_pil.size[1]:
            return

        # 빨간색 브러시로 그리기
        self.draw.ellipse(
            [x - self.brush_size, y - self.brush_size, x + self.brush_size, y + self.brush_size],
            fill=(255, 0, 0, 255)
        )

        # 캔버스 업데이트
        self.photo = ImageTk.PhotoImage(Image.alpha_composite(self.display_pil.convert("RGBA"), self.draw_pil))
        self.canvas.create_image(self.canvas_offset_x, self.canvas_offset_y, anchor="nw", image=self.photo)

    def stop_paint(self, event):
        self.drawing = False

    def clear_drawing(self):
        if not self.input_pil:
            return

        # 그리기 레이어 초기화
        self.draw_pil = Image.new("RGBA", (self.display_width, self.display_height), (0, 0, 0, 0))
        self.draw = ImageDraw.Draw(self.draw_pil)
        self.photo = ImageTk.PhotoImage(self.display_pil)
        self.canvas.create_image(self.canvas_offset_x, self.canvas_offset_y, anchor="nw", image=self.photo)

    def apply_mosaic(self):
        if not self.input_pil or not os.path.exists(self.emoji_image_path):
            print(f"Error: input image or {self.emoji_image_path} not found")
            return

        # 색칠된 영역 분석 (캔버스 표시 이미지 크기)
        draw_array = np.array(self.draw_pil)
        red_pixels = np.where((draw_array[:, :, 0] > 0) & (draw_array[:, :, 3] > 0))  # 빨간색 픽셀

        if len(red_pixels[0]) == 0:
            print("Error: No painted area detected")
            return

        # 색칠된 영역의 경계 상자 및 중심
        y_coords, x_coords = red_pixels
        min_x, max_x = np.min(x_coords), np.max(x_coords)
        min_y, max_y = np.min(y_coords), np.max(y_coords)
        face_center_x = (min_x + max_x) / 2
        face_center_y = (min_y + max_y) / 2
        face_width = max_x - min_x
        face_height = max_y - min_y
        print(f"Canvas painted area: min_x={min_x:.2f}, max_x={max_x:.2f}, min_y={min_y:.2f}, max_y={max_y:.2f}, center_x={face_center_x:.2f}, center_y={face_center_y:.2f}")

        # 원본 해상도로 좌표 변환
        orig_min_x = min_x / self.scale_x
        orig_max_x = max_x / self.scale_x
        orig_min_y = min_y / self.scale_y
        orig_max_y = max_y / self.scale_y
        orig_face_center_x = (orig_min_x + orig_max_x) / 2
        orig_face_center_y = (orig_min_y + orig_max_y) / 2
        orig_face_width = orig_max_x - orig_min_x
        orig_face_height = orig_max_y - orig_min_y
        print(f"Original image area: min_x={orig_min_x:.2f}, max_x={orig_max_x:.2f}, min_y={orig_min_y:.2f}, max_y={orig_max_y:.2f}, center_x={orig_face_center_x:.2f}, center_y={orig_face_center_y:.2f}")

        # 각도 추정 (색칠된 영역의 주성분 분석)
        coords = np.vstack((x_coords, y_coords)).T
        cov_matrix = np.cov(coords.T)
        eigenvalues, eigenvectors = np.linalg.eigh(cov_matrix)
        angle = -math.degrees(math.atan2(eigenvectors[1, 0], eigenvectors[0, 0]))  # 각도 반전
        print(f"Estimated angle: {angle:.2f} degrees")

        # 이모지 로드 및 상하 반전
        emoji = Image.open(self.emoji_image_path).convert("RGBA")
        print(f"Emoji original size: {emoji.size[0]}x{emoji.size[1]}")
        emoji = emoji.transpose(Image.FLIP_TOP_BOTTOM)  # 상하 반전

        # 이모지 크기 조정 (색칠 영역 비율에 맞춤)
        scale_factor = 1.5  # 이마~턱 커버
        target_width = orig_face_width * scale_factor
        target_height = orig_face_height * scale_factor
        resized_emoji = emoji.resize(
            (int(target_width), int(target_height)),
            Image.LANCZOS
        )
        print(f"Emoji resized size: {resized_emoji.size[0]}x{resized_emoji.size[1]}")
        rotated_emoji = resized_emoji.rotate(angle, expand=True)
        print(f"Emoji rotated size: {rotated_emoji.size[0]}x{rotated_emoji.size[1]}")

        # 이모지 붙이는 위치 계산 (색칠 영역 중앙)
        rw, rh = rotated_emoji.size
        paste_x = int(orig_face_center_x - rw / 2)
        paste_y = int(orig_face_center_y - rh / 2)
        print(f"Pasting emoji at: x={paste_x}, y={paste_y}, width={rw}, height={rh}, center: ({paste_x+rw/2:.2f}, {paste_y+rh/2:.2f})")

        # 출력 이미지 준비
        output_pil = self.input_pil.convert("RGBA")
        debug_draw = ImageDraw.Draw(output_pil)
        # 파란색 점 (이모지 중앙, 디버깅용, 제거하려면 아래 주석 처리)
        center_x, center_y = paste_x + rw/2, paste_y + rh/2
        debug_draw.ellipse(
            [center_x-5, center_y-5, center_x+5, center_y+5],
            fill=(0, 0, 255, 255)
        )

        # 모자이크 적용
        output_pil.paste(rotated_emoji, (paste_x, paste_y), rotated_emoji)
        output_pil = output_pil.convert("RGB")
        output_pil.save(self.output_image_path)
        print(f"✅ 저장 완료: 원본 해상도 유지, 색칠 위치에 모자이크 → {self.output_image_path}")

        # 결과 이미지 표시 (캔버스 크기로 축소)
        display_result = output_pil.resize((self.display_width, self.display_height), Image.LANCZOS)
        self.photo = ImageTk.PhotoImage(display_result)
        self.canvas.create_image(self.canvas_offset_x, self.canvas_offset_y, anchor="nw", image=self.photo)

if __name__ == "__main__":
    root = tk.Tk()
    app = MosaicApp(root)
    root.mainloop()


