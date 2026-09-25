import os
from PIL import Image, ImageDraw, ImageFont

# 建立輸出目錄
output_dir = os.path.join("assets", "UI")
os.makedirs(output_dir, exist_ok=True)

def create_card_frame(filename, border_color, inner_color):
    width, height = 400, 600
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 繪製邊框與背景
    draw.rounded_rectangle([10, 10, width - 10, height - 10], radius=20, fill=inner_color, outline=border_color, width=8)
    draw.rounded_rectangle([25, 25, width - 25, height - 25], radius=12, outline=border_color, width=3)
    
    # 存檔
    filepath = os.path.join(output_dir, filename)
    img.save(filepath)
    print(f"已生成: {filepath}")

# 生成素材
create_card_frame("card_frame.png", "#D4AF37", "#1A1A24")  # 墨玉金色邊框
create_card_frame("card_back.png", "#808080", "#2D2D3A")   # 灰色卡背

print("\n✅ 墨玉鑲金 UI 素材生成成功！")