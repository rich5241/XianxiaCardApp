import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:video_player/video_player.dart';
import 'asset_helper.dart';

void main() {
  runApp(const XianxiaCardApp());
}

class XianxiaCardApp extends StatelessWidget {
  const XianxiaCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '修仙幻想典藏',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07070A),
        fontFamily: 'CustomFont',
      ),
      home: const GalleryHomeScreen(),
    );
  }
}

class GalleryHomeScreen extends StatefulWidget {
  const GalleryHomeScreen({super.key});

  @override
  State<GalleryHomeScreen> createState() => _GalleryHomeScreenState();
}

class _GalleryHomeScreenState extends State<GalleryHomeScreen> {
  List<Map<String, String>> cards = [];
  bool isLoading = true;

  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCSVData().then((_) {
      // 需求一：登入/啟動完成後自動觸發一次十連抽
      if (cards.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showGachaDialog(context, isTenDraw: true);
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String getSmartAssetPath(String? input, {required bool isVideo}) {
    if (input == null || input.trim().isEmpty) return '';
    
    String path = input.trim().replaceAll('\\', '/').replaceAll('\r', '');
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.startsWith('assets/')) {
      path = path.substring(7);
    }
    path = path.replaceAll(RegExp(r'^(images/|Images/|video/|Video/|Videos/)+', caseSensitive: false), '');

    final folder = isVideo ? 'Videos' : 'images';
    final finalPath = 'assets/$folder/$path';
    return finalPath;
  }

  Future<void> _loadCSVData() async {
    try {
      String rawData = '';
      try {
        rawData = await rootBundle.loadString('assets/data/cards_data.csv');
      } catch (e) {
        print("讀取 CSV 失敗: $e");
      }

      if (rawData.startsWith('\uFEFF')) {
        rawData = rawData.substring(1);
      }

      rawData = rawData.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

      List<List<dynamic>> listData = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(rawData);

      if (listData.isNotEmpty) {
        List<String> headers = listData[0].map((e) => e.toString().trim().replaceAll('\r', '')).toList();
        List<Map<String, String>> loadedCards = [];

        for (int i = 1; i < listData.length; i++) {
          final row = listData[i];
          if (row.isEmpty || row.every((item) => item.toString().trim().isEmpty)) continue;

          Map<String, String> cardMap = {};
          for (int j = 0; j < headers.length; j++) {
            cardMap[headers[j]] = (j < row.length) ? row[j].toString().trim().replaceAll('\r', '') : '';
          }
          loadedCards.add(cardMap);
        }

        setState(() {
          cards = loadedCards;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('DEBUG: 讀取 CSV 錯誤 -> $e');
      setState(() => isLoading = false);
    }
  }

  bool hasVid(Map<String, String> card) {
    final videoPath = AssetHelper.getSmartAssetPath(card['video_url'], isVideo: true);
    return videoPath.isNotEmpty;
  }

  void _openFullScreenVideo(BuildContext context, Map<String, String> card) {
    final videoPath = getSmartAssetPath(card['video_url'], isVideo: true);
    if (videoPath.isEmpty) {
      _showUnreleasedDialog(context, card['name'] ?? '此角色');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenVideoPage(card: card, videoPath: videoPath),
      ),
    );
  }

  void _showUnreleasedDialog(BuildContext context, String characterName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1710),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFFFE885), width: 1.5),
        ),
        title: Text(
          characterName,
          style: const TextStyle(color: Color(0xFFFFE885), fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          '這個角色目前尚無影片，正在趕工製作中！',
          style: TextStyle(color: Color(0xFFFFF4D6)),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D2E1E),
                side: const BorderSide(color: Color(0xFFFFE885)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('確定', style: TextStyle(color: Color(0xFFFFE885))),
            ),
          ),
        ],
      ),
    );
  }

  // 需求二：點進抽卡介面（點擊禮品圖示）時不要自動抽獎，改為顯示抽卡大廳選單
  void _showGachaLobby(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF120E0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFFE885), width: 2),
        ),
        title: const Text(
          '✨ 修仙招募大廳 ✨',
          style: TextStyle(color: Color(0xFFFFE885), fontWeight: FontWeight.bold, letterSpacing: 2),
            textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '請選擇您的招募方式，尋找有緣佳麗：',
              style: TextStyle(color: Color(0xFFFFF4D6), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D2E1E),
                    side: const BorderSide(color: Color(0xFFFFE885), width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.card_giftcard, color: Color(0xFFFFE885)),
                  label: const Text('單抽一次', style: TextStyle(color: Color(0xFFFFE885), fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(context);
                    _showGachaDialog(context, isTenDraw: false);
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A4222),
                    side: const BorderSide(color: Color(0xFFFFD700), width: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.auto_awesome, color: Color(0xFFFFD700)),
                  label: const Text('十連絕美抽', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(context);
                    _showGachaDialog(context, isTenDraw: true);
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('返回典藏', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  // 需求三與需求四：十連抽展示改為上下各五個角色，並增加華麗金光特效
  void _showGachaDialog(BuildContext context, {required bool isTenDraw}) {
    if (cards.isEmpty) return;
    final random = Random();
    List<Map<String, String>> drawnCards = [];

    int count = isTenDraw ? 10 : 1;
    for (int i = 0; i < count; i++) {
      int index = random.nextInt(cards.length);
      drawnCards.add(cards[index]);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GachaResultDialog(
        drawnCards: drawnCards,
        isTenDraw: isTenDraw,
        onRedrawSingle: () {
          Navigator.pop(context);
          _showGachaDialog(context, isTenDraw: false);
        },
        onRedrawTen: () {
          Navigator.pop(context);
          _showGachaDialog(context, isTenDraw: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCards = cards.where((card) {
      final name = card['name'] ?? '';
      final type = card['type'] ?? '';
      final query = searchQuery.toLowerCase();
      return name.toLowerCase().contains(query) || type.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Column(
          children: [
            Text(
              cards.isNotEmpty ? '後 宮 佳 麗 (${cards.length})' : '後 宮 佳 麗',
              style: const TextStyle(
                color: Color(0xFFFFE885),
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                fontSize: 20,
                shadows: [Shadow(color: Color(0xFFD4AF37), blurRadius: 10)],
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              '修仙幻想典藏',
              style: TextStyle(
                color: Color(0xFFB5A478),
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard, color: Color(0xFFFFE885)),
            tooltip: '招募大廳',
            onPressed: () => _showGachaLobby(context), // 點擊改為打開大廳選單，不直接自動抽獎
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : cards.isEmpty
              ? const Center(child: Text('未讀取到卡牌資料', style: TextStyle(color: Colors.white)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        style: const TextStyle(color: Color(0xFFFFE885)),
                        decoration: InputDecoration(
                          hintText: '搜尋角色名稱或稱號...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFFFFE885)),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFF16120E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF3D2E1E)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFFFE885), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filteredCards.isEmpty
                          ? const Center(child: Text('找不到符合的角色', style: TextStyle(color: Colors.white70)))
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 200,
                                childAspectRatio: 0.60,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: filteredCards.length,
                              itemBuilder: (context, index) {
                                final card = filteredCards[index];
            final videoPath = AssetHelper.getSmartAssetPath(card['video_url'], isVideo: true);
            final hasVid = videoPath.isNotEmpty; // 確保這行有保留
                                return GestureDetector(
                                  onTap: () => _openFullScreenVideo(context, card),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFFFE885), width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFD4AF37).withOpacity(0.25),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.5),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
        child: Builder(
          builder: (context) {
            final imagePath = AssetHelper.getSmartAssetPath(card['image_url'], isVideo: false);
            return Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(8),
                child: const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.amber, size: 32),
                ),
              ),
            );
          },
        ),
      ),
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            bottom: 0,
                                            height: 90,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                  colors: [
                                                    Colors.black.withOpacity(0.95),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            bottom: 0,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if ((card['type'] ?? '').isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                    margin: const EdgeInsets.only(bottom: 4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF3D2E1E),
                                                      borderRadius: BorderRadius.circular(3),
                                                      border: Border.all(color: const Color(0xFFFFD700), width: 0.8),
                                                    ),
                                                    child: Text(
                                                      card['type']!,
                                                      style: const TextStyle(color: Color(0xFFFFE885), fontSize: 9.5),
                                                    ),
                                                  ),
                                                Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [
                                                        Color(0xFF3A2E1F),
                                                        Color(0xFF1F1710),
                                                        Color(0xFF3A2E1F),
                                                      ],
                                                    ),
                                                    border: const Border(
                                                      top: BorderSide(color: Color(0xFFFFE885), width: 1.5),
                                                      bottom: BorderSide(color: Color(0xFFFFE885), width: 1.5),
                                                    ),
                                                    boxShadow: const [
                                                      BoxShadow(color: Colors.black, blurRadius: 6),
                                                    ],
                                                  ),
                                                  child: Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      const Positioned(
                                                        left: 4,
                                                        child: Icon(Icons.diamond, size: 8, color: Color(0xFFFFE885)),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                                        child: Text(
                                                          card['name'] ?? '',
                                                          textAlign: TextAlign.center,
                                                          style: const TextStyle(
                                                            color: Color(0xFFFFF6DF),
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.bold,
                                                            letterSpacing: 2,
                                                            shadows: [
                                                              Shadow(color: Colors.black, blurRadius: 4),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const Positioned(
                                                        right: 4,
                                                        child: Icon(Icons.diamond, size: 8, color: Color(0xFFFFE885)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                           right: 6,
                                           top: 6,
                                           child: Container(
                                             padding: const EdgeInsets.all(3),
                                             decoration: BoxDecoration(
                                               color: Colors.black.withOpacity(0.6),
                                               shape: BoxShape.circle,
                                               border: Border.all(color: const Color(0xFFFFE885), width: 1),
                                             ),
                                             child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFFFE885), size: 16),
                                           ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

// 需求三與四：帶有特效與強制上下各5個角色的十連抽展示元件
class GachaResultDialog extends StatefulWidget {
  final List<Map<String, String>> drawnCards;
  final bool isTenDraw;
  final VoidCallback onRedrawSingle;
  final VoidCallback onRedrawTen;

  const GachaResultDialog({
    super.key,
    required this.drawnCards,
    required this.isTenDraw,
    required this.onRedrawSingle,
    required this.onRedrawTen,
  });

  @override
  State<GachaResultDialog> createState() => _GachaResultDialogState();
}

class _GachaResultDialogState extends State<GachaResultDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    // 華麗十連抽登場特效控制器 (縮放 + 金光閃爍)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.95, end: 1.02).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _glowAnim = Tween<double>(begin: 2.0, end: 8.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool _hasVideo(Map<String, String> card) {
    final videoPath = AssetHelper.getSmartAssetPath(card['video_url'], isVideo: true);
    return videoPath.isNotEmpty;
  }

  void _openCardVideo(BuildContext context, Map<String, String> card) {
    final videoPath = AssetHelper.getSmartAssetPath(card['video_url'], isVideo: true);
    if (videoPath.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1F1710),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFFFE885), width: 1.5),
          ),
          title: Text(
            card['name'] ?? '此角色',
            style: const TextStyle(color: Color(0xFFFFE885), fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            '這個角色目前尚無影片，正在趕工製作中！',
            style: TextStyle(color: Color(0xFFFFF4D6)),
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D2E1E),
                  side: const BorderSide(color: Color(0xFFFFE885)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('確定', style: TextStyle(color: Color(0xFFFFE885))),
              ),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenVideoPage(card: card, videoPath: videoPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return AlertDialog(
          backgroundColor: const Color(0xFF120E0A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: widget.isTenDraw ? const Color(0xFFFFD700) : const Color(0xFFFFE885),
              width: widget.isTenDraw ? 2.5 : 1.5,
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isTenDraw) const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 24),
              const SizedBox(width: 8),
              Text(
                widget.isTenDraw ? '✨ 十連絕美抽 (仙緣大吉) ✨' : '✨ 隨機單抽結果 ✨',
                style: TextStyle(
                  color: const Color(0xFFFFE885),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: [
                    Shadow(
                      color: const Color(0xFFFFD700),
                      blurRadius: widget.isTenDraw ? _glowAnim.value : 3.0,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(width: 8),
              if (widget.isTenDraw) const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 24),
            ],
          ),
          content: SizedBox(
            width: widget.isTenDraw ? 700 : 220,
            child: widget.isTenDraw
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 上排 5 個角色
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: widget.drawnCards.sublist(0, 5).map((card) => _buildCardItem(context, card)).toList(),
                      ),
                      const SizedBox(height: 14),
                      // 下排 5 個角色 (嚴格達成上下各5個)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: widget.drawnCards.sublist(5, 10).map((card) => _buildCardItem(context, card)).toList(),
                      ),
                    ],
                  )
                : Center(
                    child: _buildCardItem(context, widget.drawnCards[0], isSingle: true),
                  ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.refresh, color: Color(0xFFFFE885), size: 16),
                  onPressed: widget.onRedrawSingle,
                  label: const Text('再抽一次', style: TextStyle(color: Color(0xFFFFE885))),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.flash_on, color: Color(0xFFFFD700), size: 16),
                  onPressed: widget.onRedrawTen,
                  label: const Text('再抽十連', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('收下典藏', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCardItem(BuildContext context, Map<String, String> card, {bool isSingle = false}) {
    final hasVid = _hasVideo(card);
    final videoPath = AssetHelper.getSmartAssetPath(card['video_url'], isVideo: true);
    final width = isSingle ? 140.0 : 110.0;
    final height = isSingle ? 210.0 : 165.0;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _openCardVideo(context, card);
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasVid ? const Color(0xFFFFD700) : Colors.grey,
            width: hasVid ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: hasVid ? const Color(0xFFFFD700).withOpacity(0.35) : Colors.black45,
              blurRadius: 6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.5),
          child: Stack(
            fit: StackFit.expand,
children: [
  Builder(
    builder: (context) {
      // 先宣告並算出imgPath
      final imgPath = AssetHelper.getSmartAssetPath(card['image_url'], isVideo: false);
      
      return Image.asset(
        imgPath,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => Container(
          color: Colors.black54,
          padding: const EdgeInsets.all(4),
          child: Center(
            child: Text(
              '找不到: \n$imgPath',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    },
  ),
 // 這裡確保是在 children: [ ... ] 裡面
          if (!hasVid)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: Text(
                  '未更新',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                  child: Text(
                    card['name'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFFFE885), fontSize: 11, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FullScreenVideoPage extends StatefulWidget {
  final Map<String, String> card;
  final String videoPath;

  const FullScreenVideoPage({super.key, required this.card, required this.videoPath});

  @override
  State<FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _startVideoPlayer();
  }

  Future<void> _startVideoPlayer() async {
    try {
      _controller = VideoPlayerController.asset(widget.videoPath);
      await _controller.initialize();
      await _controller.setLooping(true);
      
      try {
        await _controller.setVolume(1.0);
        await _controller.play();
      } catch (e) {
        await _controller.setVolume(0.0);
        await _controller.play();
        _isMuted = true;
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('DEBUG: 影片播放錯誤 -> $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.card['name'] ?? '';
    final description = widget.card['description'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _hasError
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
                      const SizedBox(height: 12),
                      Text(
                        '無法播放影片\n(${widget.videoPath})',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  )
                : _isInitialized
                    ? AspectRatio(
                        aspectRatio: 9 / 16,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_isMuted) {
                                      _isMuted = false;
                                      _controller.setVolume(1.0);
                                    }
                                    if (_controller.value.isPlaying) {
                                      _controller.pause();
                                    } else {
                                      _controller.play();
                                    }
                                  });
                                },
                                child: VideoPlayer(_controller),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: 160,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.92),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 20,
                              right: 20,
                              bottom: 40,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF3D2E1E), Color(0xFF1E1710)],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFFFE885), width: 1.3),
                                      boxShadow: const [
                                        BoxShadow(color: Colors.black87, blurRadius: 8),
                                      ],
                                    ),
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        color: Color(0xFFFFE885),
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                        shadows: [Shadow(color: Color(0xFFD4AF37), blurRadius: 6)],
                                      ),
                                    ),
                                  ),
                                  if (description.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      '「$description」',
                                      style: const TextStyle(
                                        color: Color(0xFFFFF4D6),
                                        fontSize: 19,
                                        height: 1.35,
                                        shadows: [
                                          Shadow(color: Colors.black, blurRadius: 8),
                                          Shadow(color: Colors.black87, blurRadius: 4),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: CircleAvatar(
                                backgroundColor: Colors.black.withOpacity(0.6),
                                radius: 20,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    _isMuted ? Icons.volume_off : Icons.volume_up,
                                    color: const Color(0xFFFFE885),
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isMuted = !_isMuted;
                                      _controller.setVolume(_isMuted ? 0.0 : 1.0);
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const CircularProgressIndicator(color: Color(0xFFFFE885)),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: SafeArea(
              child: CircleAvatar(
                backgroundColor: Colors.black87,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFFFE885)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}