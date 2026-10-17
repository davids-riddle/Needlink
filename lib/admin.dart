import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'ui.dart';

// ============================================================
// Admin কি না যাচাই (Rules-ও একই নিয়মে যাচাই করে)
// ============================================================
Future<bool> isAdminUser() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  final doc =
      await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
  return doc.exists;
}

// Home-এর header-এ দেখানো Admin বাটন। Admin না হলে কিছু দেখাবে না।
class AdminAppBarAction extends StatelessWidget {
  final Color? color;
  const AdminAppBarAction({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isAdminUser(),
      builder: (context, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return IconButton(
          tooltip: 'Admin',
          color: color,
          icon: const Icon(Icons.admin_panel_settings_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminScreen()),
          ),
        );
      },
    );
  }
}

// ============================================================
// Admin স্ক্রিন: অপেক্ষমাণ আবেদন
// ============================================================
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'পণ্য / সেবা'),
              Tab(text: 'এলাকা'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PendingList(collection: 'sellerProducts'),
            _PendingList(collection: 'sellerAreas'),
          ],
        ),
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  final String collection;
  const _PendingList({required this.collection});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('তথ্য আনা যায়নি। Rules ঠিক আছে কি না দেখুন।'),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs.toList()
          ..sort((a, b) {
            final ta = (a.data()['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.now();
            final tb = (b.data()['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.now();
            return ta.compareTo(tb);
          });

        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: EmptyState(
                icon: Icons.done_all_rounded,
                message: 'অপেক্ষমাণ কোনো আবেদন নেই',
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _RequestCard(
            doc: docs[i],
            isArea: collection == 'sellerAreas',
          ),
        );
      },
    );
  }
}

// ============================================================
// একটি আবেদনের কার্ড
// ============================================================
class _RequestCard extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool isArea;

  const _RequestCard({required this.doc, required this.isArea});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _busy = false;

  Future<void> _decide(bool approve) async {
    final messenger = ScaffoldMessenger.of(context);
    final d = widget.doc.data();
    final days = (d['durationDays'] as num?)?.toInt() ?? 30;

    setState(() => _busy = true);
    try {
      final updates = <String, dynamic>{
        'status': approve ? 'approved' : 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (approve) {
        updates['expiresAt'] = Timestamp.fromDate(
          DateTime.now().add(Duration(days: days)),
        );
        updates['approvedAt'] = FieldValue.serverTimestamp();
      }
      await widget.doc.reference.update(updates);
      messenger.showSnackBar(
        SnackBar(
          content: Text(approve ? 'অনুমোদন দেওয়া হয়েছে' : 'বাতিল করা হয়েছে'),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('কাজ করা যায়নি, আবার চেষ্টা করুন')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _scopeKind(Map<String, dynamic> d) {
    final scope = (d['scope'] as String?) ?? 'upazila';
    if (scope == 'division') return 'পুরো বিভাগ';
    if (scope == 'district') return 'পুরো জেলা';
    return 'উপজেলা / থানা';
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doc.data();
    final sellerId = (d['sellerId'] as String?) ?? '';
    final days = (d['durationDays'] as num?)?.toInt() ?? 30;
    final cat = findCategory((d['category'] as String?) ?? '');

    final title = widget.isArea
        ? areaScopeLabel(d)
        : categoryLabel((d['category'] as String?) ?? '');
    final subtitle = widget.isArea ? _scopeKind(d) : 'পণ্য / সেবা';

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: widget.isArea
                    ? Icons.place_outlined
                    : (cat?.icon ?? Icons.more_horiz),
                color: widget.isArea
                    ? AppColors.primary
                    : (cat?.color ?? AppColors.locked),
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: durationLabel(days),
                color: AppColors.info,
                icon: Icons.timer_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(sellerId)
                .get(),
            builder: (context, snap) {
              final u = snap.data?.data() ?? {};
              final name = (u['fullName'] as String?) ?? 'নাম পাওয়া যায়নি';
              final phone = (u['phone'] as String?) ?? '';
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoRow(icon: Icons.person_outline, text: name),
                    const SizedBox(height: 6),
                    InfoRow(
                      icon: Icons.phone_outlined,
                      text: phone.isEmpty ? 'নম্বর নেই' : phone,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _decide(false),
                  child: const Text('বাতিল'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : () => _decide(true),
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('অনুমোদন'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
