// ============================================================
// Telegram Bot Configuration
// ============================================================
// ⚠️ গুরুত্বপূর্ণ:
// ১. এই file টা কখনো GitHub/Public এ upload করো না
// ২. Token কখনো কারো সাথে share করো না
// ৩. .gitignore এ এই file টা রাখো
// ============================================================

class TelegramConfig {
  // BotFather থেকে পাওয়া token এখানে বসাও
  // Example: '1234567890:AAHxxxxxxxxxxxxxxxxxxxxx'
  static const String botToken = 'static const String botToken = '';;

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
