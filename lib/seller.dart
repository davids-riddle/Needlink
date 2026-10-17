import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bd_locations.dart';
import 'chat.dart';
import 'photo.dart';
import 'ui.dart';

// Admin-এর WhatsApp নম্বর। নিজের নম্বর বসান।
const String adminWhatsApp = '01XXXXXXXXX';

typedef _Doc = QueryDocumentSnapshot<Map<String, dynamic>>;

class _Approved {
  final Set<String> categories;
  final Set<String> areaKeys;
  const _Approved(this.categories, this.areaKeys);
}

// এলাকা যোগের ধরন
enum _Scope { upazila, district, division }

// এলাকার ডকুমেন্ট ID (Rules-এও একই নিয়ম যাচাই হয়)
String areaDocId(String uid, String scope, String div, String dist, String up) {
  if (scope == 'division') return '${uid}__div__$div';
  if (scope == 'district') return '${uid}__dist__$dist';
  return '${uid}__up__${dist}__$up';
}

// ============================================================
// Seller প্রধান স্ক্রিন
// ============================================================
class SellerScreen extends StatelessWidget {
  const SellerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller'),
        actions: [
          IconButton(
            tooltip: 'আমার Chat',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ChatListScreen(asBuyer: false),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('sellerProducts')
            .where('sellerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, prodSnap) {
          if (prodSnap.hasError) {
            return const Center(child: Text('তথ্য আনা যায়নি'));
          }
          if (!prodSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db
                .collection('sellerAreas')
                .where('sellerId', isEqualTo: uid)
                .snapshots(),
            builder: (context, areaSnap) {
              if (areaSnap.hasError) {
                return const Center(child: Text('তথ্য আনা যায়নি'));
              }
              if (!areaSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return _SellerBody(
                products: prodSnap.data!.docs,
                areas: areaSnap.data!.docs,
              );
            },
          );
        },
      ),
    );
  }
}

class _SellerBody extends StatelessWidget {
  final List<_Doc> products;
  final List<_Doc> areas;

  const _SellerBody({required this.products, required this.areas});

  @override
  Widget build(BuildContext context) {
    final pendingCount = [...products, ...areas]
        .where((d) => (d.data()['status'] as String?) == 'pending')
        .length;
    final activeProducts =
        products.where((d) => itemStatusOf(d.data()).active).length;
    final activeAreas = areas.where((d) => itemStatusOf(d.data()).active).length;
    final canFindNeeds = activeProducts > 0 && activeAreas > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _SummaryCard(
          activeProducts: activeProducts,
          activeAreas: activeAreas,
          pending: pendingCount,
        ),
        const SizedBox(height: 16),
        if (pendingCount > 0) ...[
          const _AdminContactCard(),
          const SizedBox(height: 16),
        ],
        SectionTitle(
          title: 'পণ্য / সেবা',
          trailing: TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddProductScreen(existing: products),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('যোগ করুন'),
          ),
        ),
        const SizedBox(height: 10),
        if (products.isEmpty)
          const AppCard(
            child: EmptyState(
              icon: Icons.inventory_2_outlined,
              message: 'এখনো কোনো পণ্য/সেবা যোগ করা হয়নি',
            ),
          ),
        for (final p in products)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ProductTile(doc: p),
          ),
        const SizedBox(height: 22),
        SectionTitle(
          title: 'এলাকা',
          trailing: TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddAreaScreen(existing: areas),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('যোগ করুন'),
          ),
        ),
        const SizedBox(height: 10),
        if (areas.isEmpty)
          const AppCard(
            child: EmptyState(
              icon: Icons.map_outlined,
              message: 'এখনো কোনো এলাকা যোগ করা হয়নি',
            ),
          ),
        for (final a in areas)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AreaTile(doc: a),
          ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: canFindNeeds
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SellerNeedsScreen(),
                    ),
                  )
              : null,
          icon: const Icon(Icons.travel_explore_rounded),
          label: const Text('মিলে যাওয়া Need দেখুন'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ChatListScreen(asBuyer: false),
            ),
          ),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('আমার Chat'),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int activeProducts;
  final int activeAreas;
  final int pending;

  const _SummaryCard({
    required this.activeProducts,
    required this.activeAreas,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return GradientBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'আপনার Seller অবস্থা',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(value: '$activeProducts', label: 'সক্রিয় পণ্য/সেবা'),
              _Stat(value: '$activeAreas', label: 'সক্রিয় এলাকা'),
              _Stat(value: '$pending', label: 'অপেক্ষায়'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminContactCard extends StatelessWidget {
  const _AdminContactCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'কিছু আবেদন অনুমোদনের অপেক্ষায় আছে',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'অনুমোদনের জন্য Admin-এর WhatsApp-এ যোগাযোগ করুন:',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          Row(
            children: [
              const Expanded(
                child: SelectableText(
                  adminWhatsApp,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'কপি করুন',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: adminWhatsApp));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('নম্বর কপি হয়েছে')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// আইটেম কার্ড ও কাজ (নবায়ন / মোছা)
// ============================================================
class _ProductTile extends StatelessWidget {
  final _Doc doc;
  const _ProductTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final key = (d['category'] as String?) ?? '';
    final cat = findCategory(key);
    final st = itemStatusOf(d);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          IconBadge(
            icon: cat?.icon ?? Icons.more_horiz,
            color: cat?.color ?? AppColors.locked,
            size: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryLabel(key),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                StatusPill(label: st.label, color: st.color, icon: st.icon),
              ],
            ),
          ),
          _ItemActions(doc: doc, status: st),
        ],
      ),
    );
  }
}

class _AreaTile extends StatelessWidget {
  final _Doc doc;
  const _AreaTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final st = itemStatusOf(d);
    final scope = (d['scope'] as String?) ?? 'upazila';

    final IconData icon;
    final String kind;
    if (scope == 'division') {
      icon = Icons.map_outlined;
      kind = 'পুরো বিভাগ';
    } else if (scope == 'district') {
      icon = Icons.location_city_outlined;
      kind = 'পুরো জেলা';
    } else {
      icon = Icons.place_outlined;
      kind = 'উপজেলা / থানা';
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          IconBadge(icon: icon, color: AppColors.primary, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  areaScopeLabel(d),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  kind,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                StatusPill(label: st.label, color: st.color, icon: st.icon),
              ],
            ),
          ),
          _ItemActions(doc: doc, status: st),
        ],
      ),
    );
  }
}

class _ItemActions extends StatelessWidget {
  final _Doc doc;
  final ItemStatus status;

  const _ItemActions({required this.doc, required this.status});

  @override
  Widget build(BuildContext context) {
    if (!status.canRenew && !status.canDelete) {
      return const SizedBox(width: 8);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status.canRenew)
          IconButton(
            tooltip: 'নবায়ন / আবার আবেদন',
            icon: const Icon(Icons.autorenew_rounded, color: AppColors.primary),
            onPressed: () => _renewItem(context, doc),
          ),
        if (status.canDelete)
          IconButton(
            tooltip: 'মুছুন',
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.danger),
            onPressed: () => _deleteItem(context, doc),
          ),
      ],
    );
  }
}

Future<void> _renewItem(BuildContext context, _Doc doc) async {
  final messenger = ScaffoldMessenger.of(context);

  final days = await showDialog<int>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('কত দিনের জন্য নবায়ন করবেন?'),
      children: [
        for (final d in durationOptions)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, d),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(durationLabel(d)),
            ),
          ),
      ],
    ),
  );
  if (days == null) return;

  try {
    final data = Map<String, dynamic>.from(doc.data())
      ..remove('expiresAt')
      ..addAll({
        'status': 'pending',
        'durationDays': days,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    await doc.reference.set(data);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('আবেদন আবার পাঠানো হয়েছে। Admin অনুমোদনের অপেক্ষায়।'),
      ),
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('নবায়ন করা যায়নি, আবার চেষ্টা করুন')),
    );
  }
}

Future<void> _deleteItem(BuildContext context, _Doc doc) async {
  final messenger = ScaffoldMessenger.of(context);
  final ok = await confirmDialog(
    context,
    title: 'মুছে ফেলবেন?',
    body: 'এই আবেদনটি তালিকা থেকে মুছে যাবে।',
    yes: 'হ্যাঁ, মুছুন',
  );
  if (!ok) return;

  try {
    await doc.reference.delete();
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('মোছা যায়নি, আবার চেষ্টা করুন')),
    );
  }
}

// ============================================================
// নতুন পণ্য/সেবা যোগ
// ============================================================
class AddProductScreen extends StatefulWidget {
  final List<_Doc> existing;
  const AddProductScreen({super.key, required this.existing});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final Set<String> _selected = {};
  int _duration = 30;
  bool _saving = false;

  bool _blocked(String key) {
    for (final d in widget.existing) {
      final data = d.data();
      if ((data['category'] as String?) != key) continue;
      if (itemStatusOf(data).active) return true;
      if ((data['status'] as String?) == 'pending') return true;
    }
    return false;
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    if (_selected.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('অন্তত একটি পণ্য/সেবা বাছাই করুন')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      for (final key in _selected) {
        batch.set(db.collection('sellerProducts').doc('${uid}__$key'), {
          'sellerId': uid,
          'category': key,
          'status': 'pending',
          'durationDays': _duration,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      nav.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('আবেদন জমা হয়েছে। Admin অনুমোদনের পর Need দেখাবে।'),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('জমা দেওয়া যায়নি, আবার চেষ্টা করুন')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('পণ্য / সেবা যোগ')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(title: 'কী কী পণ্য/সেবা দেবেন?'),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: needCategories.map((c) {
                    final blocked = _blocked(c.key);
                    final sel = _selected.contains(c.key);
                    return FilterChip(
                      avatar: Icon(
                        c.icon,
                        size: 18,
                        color: blocked
                            ? AppColors.locked
                            : (sel ? Colors.white : c.color),
                      ),
                      label: Text(
                        blocked ? '${c.label} (চালু/অপেক্ষায়)' : c.label,
                      ),
                      labelStyle: TextStyle(
                        color: sel ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                      selected: sel,
                      selectedColor: c.color,
                      checkmarkColor: Colors.white,
                      onSelected: blocked
                          ? null
                          : (v) {
                              setState(() {
                                if (v) {
                                  _selected.add(c.key);
                                } else {
                                  _selected.remove(c.key);
                                }
                              });
                            },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: AppDropdown<int>(
              label: 'কত দিনের জন্য সেবা দেবেন?',
              icon: Icons.timer_outlined,
              value: _duration,
              items: durationOptions,
              itemLabel: durationLabel,
              onChanged: (v) => setState(() => _duration = v ?? _duration),
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('আবেদন জমা দিন'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// নতুন এলাকা যোগ: উপজেলা / পুরো জেলা / পুরো বিভাগ
// ============================================================
class AddAreaScreen extends StatefulWidget {
  final List<_Doc> existing;
  const AddAreaScreen({super.key, required this.existing});

  @override
  State<AddAreaScreen> createState() => _AddAreaScreenState();
}

class _AddAreaScreenState extends State<AddAreaScreen> {
  final List<Map<String, String>> _added = [];
  _Scope _scope = _Scope.upazila;
  String? _division;
  String? _district;
  String? _upazila;
  int _duration = 30;
  bool _saving = false;

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<String> get _districtOptions => _division == null
      ? <String>[]
      : (BdLocations.districtsByDivision[_division!] ?? <String>[]);

  List<String> get _upazilaOptions => _district == null
      ? <String>[]
      : BdLocations.upazilasOf(_district!)
          .where((u) => u != BdLocations.otherLabel)
          .toList();

  bool _existsActiveOrPending(String id) {
    for (final d in widget.existing) {
      if (d.id != id) continue;
      final data = d.data();
      if (itemStatusOf(data).active) return true;
      if ((data['status'] as String?) == 'pending') return true;
    }
    return false;
  }

  void _addArea() {
    final div = _division;
    if (div == null) {
      _snack('বিভাগ বাছাই করুন');
      return;
    }
    if (_scope != _Scope.division && _district == null) {
      _snack('জেলা বাছাই করুন');
      return;
    }
    if (_scope == _Scope.upazila && _upazila == null) {
      _snack('উপজেলা / থানা বাছাই করুন');
      return;
    }

    final scopeName = _scope.name;
    final dist = _scope == _Scope.division ? '' : _district!;
    final up = _scope == _Scope.upazila ? _upazila! : '';
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final id = areaDocId(uid, scopeName, div, dist, up);

    if (_added.any((a) => a['id'] == id)) {
      _snack('এই এলাকাটি আগেই যোগ করা আছে');
      return;
    }
    if (_existsActiveOrPending(id)) {
      _snack('এই এলাকাটি আগেই যোগ করা আছে বা অপেক্ষায় আছে');
      return;
    }

    setState(() {
      _added.add({
        'id': id,
        'scope': scopeName,
        'division': div,
        'district': dist,
        'upazila': up,
      });
      _upazila = null;
    });
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    if (_added.isEmpty) {
      _snack('অন্তত একটি এলাকা যোগ করুন');
      return;
    }

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      for (final a in _added) {
        batch.set(db.collection('sellerAreas').doc(a['id']!), {
          'sellerId': uid,
          'scope': a['scope'],
          'division': a['division'],
          'district': a['district'],
          'upazila': a['upazila'],
          'status': 'pending',
          'durationDays': _duration,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      nav.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('এলাকা জমা হয়েছে। Admin অনুমোদনের পর সক্রিয় হবে।'),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('জমা দেওয়া যায়নি, আবার চেষ্টা করুন')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _hint() {
    switch (_scope) {
      case _Scope.upazila:
        return 'একটি উপজেলা / থানা বাছাই করুন';
      case _Scope.district:
        return 'পুরো জেলা একটি আবেদন হিসেবে যাবে';
      case _Scope.division:
        return 'পুরো বিভাগ একটি আবেদন হিসেবে যাবে';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('এলাকা যোগ')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle(title: 'কোন এলাকায় সেবা দেবেন?'),
                const SizedBox(height: 14),
                SegmentedButton<_Scope>(
                  segments: const [
                    ButtonSegment(value: _Scope.upazila, label: Text('উপজেলা')),
                    ButtonSegment(value: _Scope.district, label: Text('পুরো জেলা')),
                    ButtonSegment(value: _Scope.division, label: Text('পুরো বিভাগ')),
                  ],
                  selected: {_scope},
                  onSelectionChanged: (s) => setState(() {
                    _scope = s.first;
                    _upazila = null;
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  _hint(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                AppDropdown<String>(
                  label: 'বিভাগ',
                  icon: Icons.map_outlined,
                  value: _division,
                  items: BdLocations.divisions,
                  itemLabel: (e) => e,
                  onChanged: (v) => setState(() {
                    _division = v;
                    _district = null;
                    _upazila = null;
                  }),
                ),
                if (_scope != _Scope.division)
                  AppDropdown<String>(
                    label: 'জেলা',
                    icon: Icons.location_city_outlined,
                    value: _district,
                    items: _districtOptions,
                    itemLabel: (e) => e,
                    onChanged: _division == null
                        ? null
                        : (v) => setState(() {
                              _district = v;
                              _upazila = null;
                            }),
                  ),
                if (_scope == _Scope.upazila)
                  AppDropdown<String>(
                    label: 'উপজেলা / থানা',
                    icon: Icons.place_outlined,
                    value: _upazila,
                    items: _upazilaOptions,
                    itemLabel: (e) => e,
                    onChanged: _district == null
                        ? null
                        : (v) => setState(() => _upazila = v),
                  ),
                OutlinedButton.icon(
                  onPressed: _addArea,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('এলাকা যোগ করুন'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(title: 'বাছাই করা এলাকা'),
                const SizedBox(height: 12),
                if (_added.isEmpty)
                  const Text(
                    'এখনো কোনো এলাকা যোগ হয়নি',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _added
                      .map((a) => InputChip(
                            label: Text(areaScopeLabel(<String, dynamic>{
                              'scope': a['scope'],
                              'division': a['division'],
                              'district': a['district'],
                              'upazila': a['upazila'],
                            })),
                            onDeleted: () => setState(() => _added.remove(a)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: AppDropdown<int>(
              label: 'কত দিনের জন্য সেবা দেবেন?',
              icon: Icons.timer_outlined,
              value: _duration,
              items: durationOptions,
              itemLabel: durationLabel,
              onChanged: (v) => setState(() => _duration = v ?? _duration),
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('আবেদন জমা দিন'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// মিলে যাওয়া Need ও Offer
// ============================================================
class SellerNeedsScreen extends StatelessWidget {
  const SellerNeedsScreen({super.key});

  Future<_Approved> _loadApproved(String uid) async {
    final db = FirebaseFirestore.instance;

    final prod = await db
        .collection('sellerProducts')
        .where('sellerId', isEqualTo: uid)
        .where('status', isEqualTo: 'approved')
        .get();
    final areas = await db
        .collection('sellerAreas')
        .where('sellerId', isEqualTo: uid)
        .where('status', isEqualTo: 'approved')
        .get();

    final categories = <String>{};
    for (final d in prod.docs) {
      final data = d.data();
      if (!isExpired(data['expiresAt'] as Timestamp?)) {
        categories.add((data['category'] as String?) ?? '');
      }
    }

    final areaKeys = <String>{};
    for (final d in areas.docs) {
      final data = d.data();
      if (isExpired(data['expiresAt'] as Timestamp?)) continue;
      final scope = (data['scope'] as String?) ?? 'upazila';
      if (scope == 'division') {
        areaKeys.add('division|${data['division']}');
      } else if (scope == 'district') {
        areaKeys.add('district|${data['district']}');
      } else {
        areaKeys.add('upazila|${data['district']}|${data['upazila']}');
      }
    }

    return _Approved(categories, areaKeys);
  }

  // Need-এর বিভাগ/জেলা/উপজেলা অনুমোদিত কোনো এলাকার মধ্যে পড়ে কি না
  bool _areaMatches(Set<String> keys, Map<String, dynamic> n) {
    return keys.contains('division|${n['division']}') ||
        keys.contains('district|${n['district']}') ||
        keys.contains('upazila|${n['district']}|${n['upazilaOrThana']}');
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('মিলে যাওয়া Need')),
      body: FutureBuilder<_Approved>(
        future: _loadApproved(uid),
        builder: (context, approvedSnap) {
          if (approvedSnap.hasError) {
            return const Center(child: Text('তথ্য আনা যায়নি'));
          }
          if (!approvedSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final approved = approvedSnap.data!;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db
                .collection('needs')
                .where('status', isEqualTo: 'active')
                .snapshots(),
            builder: (context, needSnap) {
              if (needSnap.hasError) {
                return const Center(child: Text('Need আনা যায়নি'));
              }
              if (!needSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: db
                    .collection('offers')
                    .where('sellerId', isEqualTo: uid)
                    .snapshots(),
                builder: (context, offerSnap) {
                  final offered = <String>{};
                  final offerDocs = offerSnap.data?.docs ??
                      <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                  for (final o in offerDocs) {
                    final id = o.data()['needId'];
                    if (id is String) offered.add(id);
                  }

                  final now = DateTime.now();
                  final matches = needSnap.data!.docs.where((doc) {
                    final d = doc.data();
                    final exp = d['expiresAt'] as Timestamp?;
                    if (exp == null || !exp.toDate().isAfter(now)) return false;
                    if (d['buyerId'] == uid) return false;
                    if (!approved.categories.contains(d['category'])) {
                      return false;
                    }
                    return _areaMatches(approved.areaKeys, d);
                  }).toList()
                    ..sort((a, b) {
                      final ea = (a.data()['expiresAt'] as Timestamp).toDate();
                      final eb = (b.data()['expiresAt'] as Timestamp).toDate();
                      return ea.compareTo(eb);
                    });

                  if (matches.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: EmptyState(
                          icon: Icons.search_off_rounded,
                          message:
                              'এই মুহূর্তে আপনার পণ্য/সেবা ও এলাকার সাথে মিলে এমন কোনো Need নেই',
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: matches.length,
                    itemBuilder: (context, i) {
                      final doc = matches[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _NeedOfferCard(
                          need: doc,
                          alreadyOffered: offered.contains(doc.id),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NeedOfferCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> need;
  final bool alreadyOffered;

  const _NeedOfferCard({required this.need, required this.alreadyOffered});

  Future<void> _makeOffer(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _OfferDialog(),
    );
    if (result == null) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      final me =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final profile = me.data() ?? {};

      await FirebaseFirestore.instance
          .collection('offers')
          .doc('${need.id}_$uid')
          .set({
        'needId': need.id,
        'sellerId': uid,
        'buyerId': need.data()['buyerId'],
        'price': int.parse(result['price'] as String),
        'message': result['message'],
        'photos': result['photos'] ?? <String>[],
        'sellerName': profile['fullName'] ?? '',
        'sellerPhone': profile['phone'] ?? '',
        'status': 'sent',
        'createdAt': FieldValue.serverTimestamp(),
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('আপনার Offer পাঠানো হয়েছে')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Offer পাঠানো যায়নি। Need বন্ধ হয়ে থাকলে বা আগে Offer দিয়ে থাকলে আর পাঠানো যাবে না।',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = need.data();
    final cat = findCategory((d['category'] as String?) ?? '');
    final urgent = d['urgent'] == true;
    final budget = d['budget'];
    final desc = (d['description'] as String?) ?? '';
    final area = '${d['upazilaOrThana'] ?? ''}, ${d['district'] ?? ''}';

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(
                icon: cat?.icon ?? Icons.more_horiz,
                color: cat?.color ?? AppColors.locked,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  (d['title'] as String?) ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (urgent)
                const StatusPill(
                  label: 'জরুরি',
                  color: AppColors.danger,
                  icon: Icons.bolt_rounded,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                label: categoryLabel((d['category'] as String?) ?? ''),
                color: cat?.color ?? AppColors.locked,
              ),
              needStatusPill(d),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              desc,
              style: const TextStyle(color: AppColors.textDark, height: 1.4),
            ),
          ],
          const SizedBox(height: 12),
          InfoRow(icon: Icons.place_outlined, text: area),
          if (budget != null) ...[
            const SizedBox(height: 6),
            InfoRow(icon: Icons.payments_outlined, text: 'বাজেট: $budget টাকা'),
          ],
          const SizedBox(height: 14),
          alreadyOffered
              ? const StatusPill(
                  label: 'আপনি এই Need-এ Offer দিয়েছেন',
                  color: AppColors.success,
                  icon: Icons.check_circle_outline,
                )
              : FilledButton(
                  onPressed: () => _makeOffer(context),
                  child: const Text('Offer দিন'),
                ),
        ],
      ),
    );
  }
}

// ============================================================
// Offer ফর্ম: দাম, বিস্তারিত ও ছবি (সর্বোচ্চ ৩টি)
// ============================================================
class _OfferDialog extends StatefulWidget {
  const _OfferDialog();

  @override
  State<_OfferDialog> createState() => _OfferDialogState();
}

class _OfferDialogState extends State<_OfferDialog> {
  final _priceCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final List<String> _photos = [];
  bool _picking = false;
  String? _error;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    setState(() => _picking = true);
    final added = await pickPhotosAsBase64(
      context,
      maxOfferPhotos - _photos.length,
    );
    if (!mounted) return;
    setState(() {
      _photos.addAll(added);
      _picking = false;
    });
  }

  void _submit() {
    final p = _priceCtrl.text.trim();
    final n = int.tryParse(p);
    if (n == null || n <= 0) {
      setState(() => _error = 'সঠিক টাকার অঙ্ক লিখুন');
      return;
    }
    if (_msgCtrl.text.trim().isEmpty) {
      setState(() => _error = 'বিস্তারিত লিখুন');
      return;
    }
    Navigator.of(context).pop({
      'price': p,
      'message': _msgCtrl.text.trim(),
      'photos': List<String>.from(_photos),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Offer দিন'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'দাম (টাকা)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _msgCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'বিস্তারিত (সেবা/পণ্য, সময়)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ছবি (${_photos.length}/$maxOfferPhotos)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_photos.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _photos.length; i++)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppRadius.button),
                          child: Image.memory(
                            base64Decode(_photos[i]),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: () => setState(() => _photos.removeAt(i)),
                            child: const CircleAvatar(
                              radius: 11,
                              backgroundColor: AppColors.danger,
                              child: Icon(Icons.close,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            if (_photos.length < maxOfferPhotos) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _picking ? null : _addPhotos,
                icon: _picking
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('ছবি যোগ করুন'),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('বাতিল'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('পাঠান'),
        ),
      ],
    );
  }
}
