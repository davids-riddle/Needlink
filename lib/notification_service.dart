import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  // ----------------------------------------------------------
  // নতুন কিছুর নোটিফিকেশন চেক করা
  // ----------------------------------------------------------
  static Future<bool> hasNewNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastSeenTime = prefs.getInt('last_seen_notification_${user.uid}') ?? 0;
    final lastSeenDate = DateTime.fromMillisecondsSinceEpoch(lastSeenTime);

    final db = FirebaseFirestore.instance;
    final uid = user.uid;

    bool hasNew = false;

    // ১. Buyer এর জন্য নতুন অফার চেক
    final offersQuery = await db
        .collection('offers')
        .where('buyerId', isEqualTo: uid)
        .where('createdAt', isGreaterThan: lastSeenDate)
        .limit(1)
        .get();
    if (offersQuery.docs.isNotEmpty) hasNew = true;

    // ২. Ad / Discount চেক (সব ইউজারের জন্য)
    final advertsQuery = await db
        .collection('adverts')
        .where('status', isEqualTo: 'approved')
        .where('createdAt', isGreaterThan: lastSeenDate)
        .limit(1)
        .get();
    if (advertsQuery.docs.isNotEmpty) hasNew = true;

    // ৩. Seller এর জন্য নতুন Need চেক
    // (সহজ রাখার জন্য আমরা চেক করছি সে Seller কি না, এবং নতুন কোনো Need এসেছে কি না)
    final sellerAreas = await db
        .collection('sellerAreas')
        .where('sellerId', isEqualTo: uid)
        .where('status', isEqualTo: 'approved')
        .limit(1)
        .get();

    if (sellerAreas.docs.isNotEmpty) {
      final needsQuery = await db
          .collection('needs')
          .where('status', isEqualTo: 'active')
          .where('createdAt', isGreaterThan: lastSeenDate)
          .limit(1)
          .get();
      if (needsQuery.docs.isNotEmpty) hasNew = true;
    }

    return hasNew;
  }

  // ----------------------------------------------------------
  // নোটিফিকেশন সিন (User যখন 🔔 এ ক্লিক করবে)
  // ----------------------------------------------------------
  static Future<void> markNotificationsAsSeen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'last_seen_notification_${user.uid}',
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
