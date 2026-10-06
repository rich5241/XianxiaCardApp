import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';

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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF07070A),
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

  @override
  void initState() {
    super.initState();
    _loadCSVData();
  }

  static String getSmartAssetPath(String? input, {required bool isVideo}) {
    if (input == null || input.trim().isEmpty) return '';
    String path = input.trim().replaceAll('\r', '');

    if (path.startsWith('assets/')) return path;
    if (path.startsWith('/assets/')) return path.substring(1);
    if (path.startsWith('/')) path = path.substring(1);

    if (path.startsWith('images/') || path.startsWith('video/')) {
      return 'assets/$path';
    }

    final folder = isVideo ? 'video' : 'images';
    return 'assets/$folder/$path';
  }

  Future<void> _loadCSVData() async {
    try {
      final cacheBuster = '?v=${DateTime.now().millisecondsSinceEpoch}';
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

  void _openFullScreenVideo(BuildContext context, Map<String, String> card) {
    final videoPath = getSmartAssetPath(card['video_url'], isVideo: true);
    if (videoPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('此卡牌尚無影片資源')),
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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : cards.isEmpty
              ? const Center(child: Text('未讀取到卡牌資料', style: TextStyle(color: Colors.white)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 0.60,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    final imagePath = getSmartAssetPath(card['image_url'], isVideo: false);

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
                              // 封面圖
                              Positioned.fill(
                                child: Image.asset(
                                  imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.black54,
                                    padding: const EdgeInsets.all(8),
                                    child: const Center(
                                      child: Icon(Icons.image_not_supported, color: Colors.amber, size: 32),
                                    ),
                                  ),
                                ),
                              ),

                              // 底部遮罩
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

                              // 稱號與整個橫幅覆蓋的名字花邊框
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

                                    // 全橫幅覆蓋花邊裝飾名牌
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
                                          // 左側裝飾角
                                          const Positioned(
                                            left: 4,
                                            child: Icon(Icons.diamond, size: 8, color: Color(0xFFFFE885)),
                                          ),
                                          // 名字（字體加大，清晰立體）
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
                                          // 右側裝飾角
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

                              // 右上角播放圖示
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
    );
  }
}

// 影片播放頁面 (支持聲音播放 + 自動優化 + 台詞位置與大小提升)
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
  bool _isMuted = false; // 預設嘗試帶聲音播放

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
      
      // 嘗試開啟聲音自動播放
      try {
        await _controller.setVolume(1.0);
        await _controller.play();
      } catch (e) {
        // 若受瀏覽器阻擋則先靜音播放，並顯示提示
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
          // 1. 中央 9:16 影片區域與台詞對齊容器
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
                            // 影片主體 (點擊畫面可暫停/播放/喚醒聲音)
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

                            // 底部漸層遮罩
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

                            // 台詞與名字（向上抬高 position，字體加大）
                            Positioned(
                              left: 20,
                              right: 20,
                              bottom: 40, // 抬高位置，避免太貼近底部
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 名字金框標籤
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
                                    // 詩詞台詞（字體調大至 19px）
                                    Text(
                                      '「$description」',
                                      style: GoogleFonts.maShanZheng(
                                        textStyle: const TextStyle(
                                          color: Color(0xFFFFF4D6),
                                          fontSize: 19, // 字體加大
                                          height: 1.35,
                                          shadows: [
                                            Shadow(color: Colors.black, blurRadius: 8),
                                            Shadow(color: Colors.black87, blurRadius: 4),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // 右上角聲音開關按鈕
                            Positioned(
                              top: 12,
                              right: 12,
                              child: CircleAvatar(
                                backgroundColor:Colors.black.withOpacity(0.6),
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

          // 2. 左上角返回按鈕
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