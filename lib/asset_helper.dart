class AssetHelper {
  /// 智慧路徑判斷函式
  static String getSmartAssetPath(String? path, {bool isVideo = false}) {
    if (path == null || path.isEmpty) {
      return '';
    }

    String cleaned = path.trim().replaceAll('\\', '/');

    // 如果路徑已經包含 assets/ 開頭，直接採用，不要重複疊加！
    if (cleaned.toLowerCase().startsWith('assets/')) {
      return cleaned;
    }

    // 移除開頭可能帶有的斜線
    if (cleaned.startsWith('/')) {
      cleaned = cleaned.substring(1);
    }

    // 根據類型補上對應的預設資料夾
    String targetFolder = isVideo ? 'assets/Videos' : 'assets/images';
    return '$targetFolder/$cleaned';
  }
}