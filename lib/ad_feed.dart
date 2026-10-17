import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'advert.dart';
import 'ui.dart';

// ============================================================
// Ad / Discount Feed (TikTok Style)
// ============================================================
class AdFeedScreen extends StatefulWidget {
  final String type; // 'ad' or 'discount'
  const AdFeedScreen({super.key, required this.type});

  @override
  State<AdFeedScreen> createState() => _AdFeedScreenState();
}

class _AdFeedScreenState extends State<AdFeedScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.type == 'ad' ? 'বিজ্ঞাপন সমূহ' : 'ডিসকাউন্ট সমূহ'),
        actions: [
          IconButton(
            tooltip: widget.type == 'ad' ? 'বিজ্ঞাপন দিন' : 'ডিসকাউন্ট দিন',
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AdvertFormScreen(type: widget.type),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: db.collection('users').doc(uid).get(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = userSnap.data!.data() ?? {};
          final userDistrict = user['district'] as String?;
          final userUpazila = user['upazilaOrThana'] as String?;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db
                .collection('adverts')
                .where('type', isEqualTo: widget.type)
                .where('status', isEqualTo: 'approved')
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return const Center(
                  child: Text('তথ্য আনা যায়নি', style: TextStyle(color: Colors.white)),
                );
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final now = DateTime.now();
              final docs = snap.data!.docs.where((doc) {
                final d = doc.data();
                final exp = d['expiresAt'] as Timestamp?;
                if (exp != null && !exp.toDate().isAfter(now)) return false;

                // Area Filter
                final targets = (d['targetAreas'] as List?) ?? [];
                for (final t in targets) {
                  if (t['district'] == userDistrict) {
                    if ((t['upazila'] as String?) == null || (t['upazila'] as String?).isEmpty) {
                      return true; // District wide
                    }
                    if (t['upazila'] == userUpazila) {
                      return true; // Exact upazila match
                    }
                  }
                }
                return false;
              }).toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'আপনার এলাকার জন্য এখনো কোনো পোস্ট নেই',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return PageView.builder(
                scrollDirection: Axis.vertical,
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  return _AdCard(data: docs[i].data());
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AdCard({required this.data});

  Future<void> _openLink(BuildContext context) async {
    final link = (data['link'] as String?) ?? '';
    if (link.isEmpty) return;
    final uri = Uri.parse(link.startsWith('http') ? link : 'https://$link');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch');
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('লিংকটি খোলা যায়নি')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] as String?) ?? '';
    final desc = (data['description'] as String?) ?? '';
    final link = (data['link'] as String?) ?? '';
    final discount = (data['discount'] as String?) ?? '';
    final type = (data['type'] as String?) ?? 'ad';
    final areas = ((data['targetAreas'] as List?) ?? [])
        .map((a) => a['district'])
        .join(', ');

    return Stack(
      fit: StackFit.expand,
      children: [
        // Placeholder for Video/Image
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black45, Colors.black87],
            ),
          ),
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined, color: Colors.white24, size: 80),
          ),
        ),

        // Content Overlay
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (type == 'discount' && discount.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      discount,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 12),
                InfoRow(icon: Icons.place_outlined, text: 'এলাকা: $areas'),
                const SizedBox(height: 20),
                if (link.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openLink(context),
                      icon: const Icon(Icons.link),
                      label: const Text('বিস্তারিত দেখুন'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
