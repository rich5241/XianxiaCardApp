
import os
from PIL import Image

image_dir = 'assets/images'
if os.path.exists(image_dir):
    count = 0
    for filename in os.listdir(image_dir):
        if filename.lower().endswith(('.png', '.jpg', '.jpeg')):
            filepath = os.path.join(image_dir, filename)
            try:
                # 打開圖片並重新儲存，微調檔案特徵但不影響畫質
                img = Image.open(filepath)
                img.save(filepath, quality=95)
                count += 1
            except Exception as e:
                print(f"處理 {filename} 失敗: {e}")
    print(f"成功處理了 {count} 張圖片！")
else:
    print("找不到 assets/images 資料夾，請確認腳本是否放在專案根目錄。")
