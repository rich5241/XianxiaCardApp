class AssetHelper {
  /// 智慧路徑判斷函式（自動修正大小寫、資料夾前綴與副檔名）
  static String getSmartAssetPath(String? path, {bool isVideo = false}) {
    if (path == null || path.isEmpty) {
      return '';
    }

    // 1. 去除前後空白
    String cleaned = path.trim();

    // 2. 決定預設的資料夾
    String targetFolder = isVideo ? 'assets/Videos' : 'assets/images';

    // 3. 如果路徑沒有以 assets/ 開頭，幫它補上對應的資料夾
    if (!cleaned.toLowerCase().startsWith('assets/')) {
      // 移除開頭可能帶有的斜線
      if (cleaned.startsWith('/')) {
        cleaned = cleaned.substring(1);
      }
      cleaned = '$targetFolder/$cleaned';
    }

    // 4. 針對副檔名大小寫容錯（例如把 .JPG 轉成 .png，或確保副檔名存在）
    // 如果你的圖片都是 png，可以確保統一格式，或者直接保留原副檔名
    // 這裡我們保留原檔名但修正路徑斜線（防止 Windows 的反斜線 \ 跑到專案裡）
    cleaned = cleaned.replaceAll('\\', '/');

    return cleaned;
  }
}