class AssetHelper {
  /// 終極智慧路徑解析器（自動過濾所有重複的 assets 與資料夾）
  static String getSmartAssetPath(String? path, {bool isVideo = false}) {
    if (path == null || path.isEmpty) {
      return '';
    }

    // 1. 統一斜線方向並去除前後空白
    String cleaned = path.trim().replaceAll('\\', '/');

    // 2. 移除開頭可能帶有的斜線
    while (cleaned.startsWith('/')) {
      cleaned = cleaned.substring(1);
    }

    // 3. 強制把所有重複出現的 assets/、images/、Videos/ 前綴全部拔掉
    // 這樣不管前面被加了幾次 assets/assets/images/，都會被洗成乾淨的檔名
    cleaned = cleaned.replaceAll(RegExp(r'^(assets/)+', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'^(images/)+', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'^(Videos/)+', caseSensitive: false), '');

    // 4. 根據類型重新組合成正確且唯一的標準路徑
    String targetFolder = isVideo ? 'assets/Videos' : 'assets/images';
    
    final finalPath = '$targetFolder/$cleaned';
    
    // 5. 印出結果方便我們在 Console 觀察
    print('AssetHelper Final -> Input: "$path" => Output: "$finalPath"');

    return finalPath;
  }
}