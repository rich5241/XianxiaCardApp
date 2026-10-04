import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:video_player/video_player.dart';

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
        fontFamily: 'CustomFont', // 全域套用你的自訂字型
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
    _loadCSVData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  bool _hasVideo(Map<String, String> card) {
    final videoPath = getSmartAssetPath(card['video_url'], isVideo: true);
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

  void _showGachaDialog(BuildContext context, {bool isTenDraw = false}) {
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
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF120E0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFFE885), width: 2),
        ),
        title: Text(
          isTenDraw ? '✨ 十連抽結果 ✨' : '✨ 隨機抽卡 ✨',
          style: const TextStyle(color: Color(0xFFFFE885), fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: drawnCards.map((card) {
                final hasVid = _hasVideo(card);
                final imgPath = getSmartAssetPath(card['image_url'], isVideo: false);
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _openFullScreenVideo(context, card);
                  },
                  child: Container(
                    width: isTenDraw ? 80 : 120,
                    height: isTenDraw ? 120 : 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: hasVid ? const Color(0xFFFFE885) : Colors.grey, width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6.5),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            imgPath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: Colors.black54),
                          ),
                          if (!hasVid)
                            Container(
                              color: Colors.black.withOpacity(0.6),
                              child: const Center(
                                child: Text(
                                  '未更新',
                                  style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                card['name'] ?? '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFFFFE885), fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showGachaDialog(context, isTenDraw: false);
                },
                child: const Text('再抽一次', style: TextStyle(color: Color(0xFFFFE885))),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showGachaDialog(context, isTenDraw: true);
                },
                child: const Text('再抽十連', style: TextStyle(color: Color(0xFFFFE885))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('關閉', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ],
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
            tooltip: '隨機抽卡',
            onPressed: () => _showGachaDialog(context, isTenDraw: false),
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