import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  // 用來暫存點擊通知時帶入的角色名稱
  static String? pendingPayload;
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 初始化通知設定
  Future<void> initNotification({required Function(String? payload) onSelectNotification}) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 初始化設定
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          pendingPayload = payload; // 加上這兩行來記錄點擊目標
        }
        onSelectNotification(payload);
      },
    );

    // 請求 iOS 權限
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // 呼叫 OpenAI GPT API 生成角色台詞
  Future<String> generateGptQuote(String characterName, String triggerType) async {
    const String apiKey = '你的_OPENAI_API_KEY'; // 之後要換成你的金鑰
    
    if (apiKey == '你的_OPENAI_API_KEY') {
      // 如果還沒設定金鑰的備用預設台詞，避免直接報錯
      return '主上，$triggerType到囉，記得要照顧好自己喔！';
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {
              "role": "system",
              "content": "你是一個仙俠/後宮手遊中的角色。請根據指定的角色名稱與提醒情境，用該角色獨特的口吻寫一句簡短的提醒台詞（20字以內，不要有引號）。"
            },
            {
              "role": "user",
              "content": "角色名稱：$characterName，情境：$triggerType"
            }
          ],
          "max_tokens": 50,
          "temperature": 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String content = data['choices'][0]['message']['content'].trim();
        return content;
      }
    } catch (e) {
      debugPrint('GPT API 呼叫失敗: $e');
    }

    // 發生例外時的預設回退台詞
    return '主上，$triggerType的時間到了，快來找我吧！';
  }

  // 觸發提醒的核心流程：隨機抽角 -> 呼叫 GPT -> 發送通知
  Future<void> triggerRandomCharacterReminder(List<Map<String, String>> cards, String triggerType) async {
    if (cards.isEmpty) return;

    // 1. 隨機抽選一位角色
    final random = Random();
    final chosenCard = cards[random.nextInt(cards.length)];
    final String charName = chosenCard['name'] ?? '神秘佳麗';
    final String charId = chosenCard['id'] ?? ''; // 用於點擊跳轉

    // 2. 呼叫 GPT 產生台詞
    final String quote = await generateGptQuote(charName, triggerType);

    // 3. 設定通知內容
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'gacha_reminder_channel',
      '後宮即時提醒',
      channelDescription: '來自後宮角色的貼心提醒',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    // 4. 發送本地通知（payload 夾帶角色名稱或 ID，供點擊跳轉使用）
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      '【$charName】的呼喚',
      quote,
      platformChannelSpecifics,
      payload: charName, // 點擊時會帶這個過去
    );
  }
}