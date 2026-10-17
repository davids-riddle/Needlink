import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'telegram_config.dart';

// ============================================================
// Telegram Bot Service
// ============================================================
// কাজ:
// ১. Photo পাঠানো (Admin notification এ)
// ২. Video পাঠানো (Ad/Discount এর জন্য)
// ৩. Text message পাঠানো (Admin notification)
// ৪. File ID থেকে download link পাওয়া
// ============================================================

class TelegramService {
  // ----------------------------------------------------------
  // Text message পাঠানো (Admin কে notification)
  // ----------------------------------------------------------
  static Future<bool> sendMessage({
    required String text,
    String? chatId,
    Map<String, dynamic>? replyMarkup,
  }) async {
    try {
      final targetChat = chatId ?? TelegramConfig.adminChatId;
      final url = Uri.parse('${TelegramConfig.apiUrl}/sendMessage');

      final body = <String, dynamic>{
        'chat_id': targetChat,
        'text': text,
        'parse_mode': 'HTML',
      };
      if (replyMarkup != null) {
        body['reply_markup'] = jsonEncode(replyMarkup);
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ----------------------------------------------------------
  // Photo পাঠানো (Admin notification এ thumbnail)
  // ----------------------------------------------------------
  static Future<Map<String, dynamic>?> sendPhoto({
    required File photo,
    String? caption,
    String? chatId,
    Map<String, dynamic>? replyMarkup,
  }) async {
    try {
      final targetChat = chatId ?? TelegramConfig.adminChatId;
      final url = Uri.parse('${TelegramConfig.apiUrl}/sendPhoto');

      final request = http.MultipartRequest('POST', url)
        ..fields['chat_id'] = targetChat
        ..files.add(await http.MultipartFile.fromPath('photo', photo.path));

      if (caption != null && caption.isNotEmpty) {
        request.fields['caption'] = caption;
        request.fields['parse_mode'] = 'HTML';
      }
      if (replyMarkup != null) {
        request.fields['reply_markup'] = jsonEncode(replyMarkup);
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['ok'] != true) return null;

      final result = data['result'] as Map<String, dynamic>;
      final photoList = result['photo'] as List?;
      if (photoList == null || photoList.isEmpty) return null;

      // সর্বোচ্চ resolution এর photo
      final largest = photoList.last as Map<String, dynamic>;
      return {
        'fileId': largest['file_id'],
        'messageId': result['message_id'],
      };
    } catch (e) {
      return null;
    }
  }

  // ----------------------------------------------------------
  // Video পাঠানো (Ad/Discount এর video)
  // ----------------------------------------------------------
  static Future<Map<String, dynamic>?> sendVideo({
    required File video,
    String? caption,
    String? thumbnailPath,
    int? durationSeconds,
    String? chatId,
    Map<String, dynamic>? replyMarkup,
  }) async {
    try {
      final targetChat = chatId ?? TelegramConfig.adminChatId;
      final url = Uri.parse('${TelegramConfig.apiUrl}/sendVideo');

      final request = http.MultipartRequest('POST', url)
        ..fields['chat_id'] = targetChat
        ..files.add(await http.MultipartFile.fromPath('video', video.path));

      if (caption != null && caption.isNotEmpty) {
        request.fields['caption'] = caption;
        request.fields['parse_mode'] = 'HTML';
      }
      if (durationSeconds != null) {
        request.fields['duration'] = durationSeconds.toString();
      }
      if (thumbnailPath != null) {
        request.files.add(
          await http.MultipartFile.fromPath('thumbnail', thumbnailPath),
        );
      }
      if (replyMarkup != null) {
        request.fields['reply_markup'] = jsonEncode(replyMarkup);
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['ok'] != true) return null;

      final result = data['result'] as Map<String, dynamic>;
      final videoData = result['video'] as Map<String, dynamic>?;
      if (videoData == null) return null;

      return {
        'fileId': videoData['file_id'],
        'fileUniqueId': videoData['file_unique_id'],
        'duration': videoData['duration'],
        'messageId': result['message_id'],
      };
    } catch (e) {
      return null;
    }
  }

  // ----------------------------------------------------------
  // File ID থেকে download link পাওয়া
  // ----------------------------------------------------------
  static Future<String?> getFileUrl(String fileId) async {
    try {
      final url = Uri.parse(
        '${TelegramConfig.apiUrl}/getFile?file_id=$fileId',
      );
      final response = await http.get(url);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['ok'] != true) return null;

      final result = data['result'] as Map<String, dynamic>;
      final filePath = result['file_path'] as String?;
      if (filePath == null) return null;

      return '${TelegramConfig.fileApiUrl}/$filePath';
    } catch (e) {
      return null;
    }
  }

  // ----------------------------------------------------------
  // Bot এর info দেখা (test করার জন্য)
  // ----------------------------------------------------------
  static Future<Map<String, dynamic>?> getMe() async {
    try {
      final url = Uri.parse('${TelegramConfig.apiUrl}/getMe');
      final response = await http.get(url);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['result'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }
}
