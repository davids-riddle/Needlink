// ============================================================
// Telegram Bot Configuration
// ============================================================
// ⚠️ গুরুত্বপূর্ণ:
// ১. Token কখনো GitHub/Public repo-তে লেখো না
// ২. Token কখনো কারো সাথে share করো না
// ============================================================

class TelegramConfig {
  // BotFather থেকে পাওয়া token এখানে বসাবে (Admin পরে বসাবে)
  // Example: '1234567890:AAHxxxxxxxxxxxxxxxxxxxxx'
  static const String botToken = 'এখানে_TOKEN_বসবে';

  // Bot এর username (@ সহ নয়, শুধু username)
  static const String botUsername = 'needlink_ad_bot';

  // Admin (তুমি) এর Telegram Chat ID
  // এটা দিয়ে bot তোমাকে notification পাঠাবে
  static const String adminChatId = '8278542212';

  // Telegram API base URL
  static const String apiBase = 'https://api.telegram.org/bot';

  // Full API URL (bot token সহ)
  static String get apiUrl => '$apiBase$botToken';

  // File API URL
  static String get fileApiUrl =>
      'https://api.telegram.org/file/bot$botToken';
}
