import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bd_locations.dart';
import 'chat.dart';
import 'photo.dart';
import 'ui.dart';

// নির্দিষ্ট তারিখ সর্বোচ্চ কত দিন পর পর্যন্ত বাছাই করা যাবে
const int maxDeadlineDays = 30;

String _formatDateTime(DateTime d) {
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day}/${d.month}/${d.year}  •  $hh:$mm';
}

// ============================================================
// Buyer প্রধান স্ক্রিন
// ============================================================
class BuyerScreen extends StatelessWidget {
  const BuyerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer'),
        actions: [
          IconButton(
            tooltip: 'আমার Chat',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ChatListScreen(asBuyer: true),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (context, snap) {
              final d = snap.data?.data() ?? {};
              final location = [d['areaText'], d['upazilaOrThana'], d['district']]
                  .whereType<String>()
                  .where((s) => s.isNotEmpty)
                  .join(', ');
              return _ProfileHeader(
                name: (d['fullName'] as String?) ?? '',
                phone: (d['phone'] as String?) ?? '',
                location: location,
              );
            },
          ),
          const SizedBox(height: 26),
          const SectionTitle(title: 'কী প্রয়োজন?'),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
            children: needCategories
                .map((c) => _CategoryCard(category: c))
                .toList(),
          ),
          const SizedBox(height: 26),
          const SectionTitle(title: 'আমার Need'),
          const SizedBox(height: 12),
          _MyNeeds(uid: uid),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String phone;
  final String location;

  const _ProfileHeader({
    required this.name,
    required this.phone,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return GradientBox(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.25),
            ),
            child: const CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppColors.primary, size: 30),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'নাম নেই' : name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final NeedCategory category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NeedFormScreen(category: category),
        ),
      ),
      child: Row(
        children: [
          IconBadge(icon: category.icon, color: category.color, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              category.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Need পোস্ট ফর্ম
// ============================================================
class NeedFormScreen extends StatefulWidget {
  final NeedCategory category;
  const NeedFormScreen({super.key, required this.category});

  @override
  State<NeedFormScreen> createState() => _NeedFormScreenState();
}

class _NeedFormScreenState extends State<NeedFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _upazilaOtherCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();

  String _condition = 'যেকোনো';
  bool _urgent = false;

  bool _useDate = false;
  int _validity = 7;
  DateTime? _deadline;

  String? _division;
  String? _district;
  String? _upazila;

  bool _loadingProfile = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    _upazilaOtherCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final d = doc.data() ?? {};

    final div = d['division'] as String?;
    final dist = d['district'] as String?;
    final up = d['upazilaOrThana'] as String?;

    final divisionOk = BdLocations.divisions.contains(div);
    final districtOk = divisionOk &&
        (BdLocations.districtsByDivision[div!] ?? []).contains(dist);

    if (!mounted) return;
    setState(() {
      _division = divisionOk ? div : null;
      _district = districtOk ? dist : null;

      if (districtOk && up != null && up.isNotEmpty) {
        if (BdLocations.upazilasOf(dist!).contains(up)) {
          _upazila = up;
        } else {
          _upazila = BdLocations.otherLabel;
          _upazilaOtherCtrl.text = up;
        }
      }

      _areaCtrl.text = (d['areaText'] as String?) ?? '';
      _loadingProfile = false;
    });
  }

  Future<void> _pickDeadline() async {
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: maxDeadlineDays)),
      helpText: 'কোন তারিখ পর্যন্ত?',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 21, minute: 0),
      helpText: 'কোন সময় পর্যন্ত?',
    );
    if (time == null || !mounted) return;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!picked.isAfter(DateTime.now())) {
      messenger.showSnackBar(
        const SnackBar(content: Text('ভবিষ্যতের তারিখ ও সময় বাছাই করুন')),
      );
      return;
    }

    setState(() => _deadline = picked);
  }

  String? _required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label দিন';
    return null;
  }

  String? _validateBudget(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null || n <= 0) return 'সঠিক টাকার অঙ্ক লিখুন';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_useDate && _deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('তারিখ ও সময় বাছাই করুন')),
      );
      return;
    }

    setState(() => _saving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final upazilaValue = _upazila == BdLocations.otherLabel
          ? _upazilaOtherCtrl.text.trim()
          : _upazila;
      final budgetText = _budgetCtrl.text.trim();

      final DateTime expires = _useDate
          ? _deadline!
          : DateTime.now().add(Duration(days: _validity));

      await FirebaseFirestore.instance.collection('needs').add({
        'buyerId': uid,
        'category': widget.category.key,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'budget': budgetText.isEmpty ? null : int.parse(budgetText),
        'condition': _condition,
        'urgent': _urgent,
        'deadlineType': _useDate ? 'date' : 'days',
        'validityDays': _useDate ? null : _validity,
        'expiresAt': Timestamp.fromDate(expires),
        'division': _division,
        'district': _district,
        'upazilaOrThana': upazilaValue,
        'areaText': _areaCtrl.text.trim(),
        'status': 'active',
        'selectedSellerId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('আপনার Need পোস্ট হয়েছে')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('পোস্ট করা যায়নি, আবার চেষ্টা করুন')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _deadlineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(title: 'কতক্ষণ চলবে?'),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('দিন অনুযায়ী')),
            ButtonSegment(value: true, label: Text('তারিখ ও সময়')),
          ],
          selected: {_useDate},
          onSelectionChanged: (s) => setState(() => _useDate = s.first),
        ),
        const SizedBox(height: 14),
        if (!_useDate)
          AppDropdown<int>(
            label: 'কত দিনের মধ্যে লাগবে',
            icon: Icons.timer_outlined,
            value: _validity,
            items: validityOptions.keys.toList(),
            itemLabel: (e) => validityOptions[e] ?? '$e দিন',
            onChanged: (v) => setState(() => _validity = v ?? _validity),
          )
        else
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.button),
            onTap: _pickDeadline,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_outlined, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _deadline == null
                          ? 'তারিখ ও সময় বাছাই করুন'
                          : _formatDateTime(_deadline!),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _deadline == null
                            ? AppColors.textMuted
                            : AppColors.textDark,
                      ),
                    ),
                  ),
                  const Icon(Icons.edit_calendar_outlined,
                      color: AppColors.locked),
                ],
              ),
            ),
          ),
        if (_useDate)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'সর্বোচ্চ $maxDeadlineDays দিন পর পর্যন্ত বাছাই করা যাবে',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final districts = _division == null
        ? <String>[]
        : (BdLocations.districtsByDivision[_division!] ?? <String>[]);
    final upazilas = _district == null
        ? <String>[]
        : BdLocations.upazilasOf(_district!);

    return Scaffold(
      appBar: AppBar(title: Text(cat.label)),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconBadge(icon: cat.icon, color: cat.color),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: SectionTitle(title: 'প্রয়োজনের তথ্য'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _titleCtrl,
                          label: 'প্রয়োজনের শিরোনাম',
                          icon: Icons.title_rounded,
                          validator: (v) => _required(v, 'শিরোনাম'),
                        ),
                        AppTextField(
                          controller: _descCtrl,
                          label: 'বিস্তারিত লিখুন',
                          icon: Icons.notes_rounded,
                          maxLines: 4,
                          validator: (v) => _required(v, 'বিস্তারিত'),
                        ),
                        AppTextField(
                          controller: _budgetCtrl,
                          label: 'বাজেট (টাকা, ঐচ্ছিক)',
                          icon: Icons.payments_outlined,
                          keyboard: TextInputType.number,
                          validator: _validateBudget,
                        ),
                        AppDropdown<String>(
                          label: 'অবস্থা',
                          icon: Icons.inventory_outlined,
                          value: _condition,
                          items: conditionOptions,
                          itemLabel: (e) => e,
                          onChanged: (v) =>
                              setState(() => _condition = v ?? _condition),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('জরুরি'),
                          activeColor: AppColors.danger,
                          value: _urgent,
                          onChanged: (v) => setState(() => _urgent = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(child: _deadlineSection()),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionTitle(title: 'এলাকা'),
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
                          validator: (v) =>
                              v == null ? 'বিভাগ বাছাই করুন' : null,
                        ),
                        AppDropdown<String>(
                          label: 'জেলা',
                          icon: Icons.location_city_outlined,
                          value: _district,
                          items: districts,
                          itemLabel: (e) => e,
                          onChanged: _division == null
                              ? null
                              : (v) => setState(() {
                                    _district = v;
                                    _upazila = null;
                                  }),
                          validator: (v) =>
                              v == null ? 'জেলা বাছাই করুন' : null,
                        ),
                        AppDropdown<String>(
                          label: 'উপজেলা / থানা',
                          icon: Icons.place_outlined,
                          value: _upazila,
                          items: upazilas,
                          itemLabel: (e) => e,
                          onChanged: _district == null
                              ? null
                              : (v) => setState(() => _upazila = v),
                          validator: (v) =>
                              v == null ? 'উপজেলা / থানা বাছাই করুন' : null,
                        ),
                        if (_upazila == BdLocations.otherLabel)
                          AppTextField(
                            controller: _upazilaOtherCtrl,
                            label: 'উপজেলা / থানার নাম লিখুন',
                            icon: Icons.edit_location_alt_outlined,
                            validator: (v) =>
                                _required(v, 'উপজেলা / থানার নাম'),
                          ),
                        AppTextField(
                          controller: _areaCtrl,
                          label: 'বিস্তারিত এলাকা',
                          icon: Icons.home_outlined,
                          validator: (v) => _required(v, 'বিস্তারিত এলাকা'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
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
                        : const Text('Need পোস্ট করুন'),
                  ),
                ],
              ),
            ),
    );
  }
}

// ============================================================
// আমার Need তালিকা
// ============================================================
class _MyNeeds extends StatelessWidget {
  final String uid;
  const _MyNeeds({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('needs')
          .where('buyerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Text('তালিকা আনা যায়নি');
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
            return tb.compareTo(ta);
          });

        if (docs.isEmpty) {
          return const AppCard(
            child: EmptyState(
              icon: Icons.inbox_outlined,
              message:
                  'এখনো কোনো Need পোস্ট করা হয়নি।\nউপরের যেকোনো ক্যাটাগরি বেছে শুরু করুন।',
            ),
          );
        }

        return Column(
          children: docs
              .map((doc) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NeedTile(doc: doc),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _NeedTile extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _NeedTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final cat = findCategory((d['category'] as String?) ?? '');

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => NeedDetailScreen(needId: doc.id)),
      ),
      child: Row(
        children: [
          IconBadge(
            icon: cat?.icon ?? Icons.more_horiz,
            color: cat?.color ?? AppColors.locked,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (d['title'] as String?) ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  categoryLabel((d['category'] as String?) ?? ''),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                needStatusPill(d),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.locked),
        ],
      ),
    );
  }
}

// ============================================================
// Need বিস্তারিত: Offer দেখা, বাছাই, বন্ধ, Chat
// ============================================================
class NeedDetailScreen extends StatefulWidget {
  final String needId;
  const NeedDetailScreen({super.key, required this.needId});

  @override
  State<NeedDetailScreen> createState() => _NeedDetailScreenState();
}

class _NeedDetailScreenState extends State<NeedDetailScreen> {
  bool _busy = false;

  Future<void> _closeNeed() async {
    final ok = await confirmDialog(
      context,
      title: 'Need বন্ধ করবেন?',
      body: 'বন্ধ করলে এই Need আর Seller-দের কাছে দেখাবে না।',
      yes: 'হ্যাঁ, বন্ধ করুন',
    );
    if (!ok) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance
          .collection('needs')
          .doc(widget.needId)
          .update({'status': 'closed'});
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('বন্ধ করা যায়নি, আবার চেষ্টা করুন')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _selectOffer(
    Map<String, dynamic> need,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> offers,
    QueryDocumentSnapshot<Map<String, dynamic>> chosen,
  ) async {
    final ok = await confirmDialog(
      context,
      title: 'Seller বাছাই করবেন?',
      body:
          'এই Seller-কে বাছাই করলে বাকি Offer বাতিল হবে, Need বন্ধ হবে এবং Chat খুলবে।',
      yes: 'হ্যাঁ, বাছাই করুন',
    );
    if (!ok) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final db = FirebaseFirestore.instance;

      final buyerSnap = await db.collection('users').doc(uid).get();
      final buyer = buyerSnap.data() ?? {};
      final chosenData = chosen.data();
      final sellerId = chosenData['sellerId'] as String;

      final batch = db.batch();

      batch.update(db.collection('needs').doc(widget.needId), {
        'status': 'matched',
        'selectedSellerId': sellerId,
        'matchedAt': FieldValue.serverTimestamp(),
      });

      for (final o in offers) {
        batch.update(o.reference, {
          'status': o.id == chosen.id ? 'accepted' : 'rejected',
        });
      }

      batch.set(db.collection('chats').doc(widget.needId), {
        'needId': widget.needId,
        'needTitle': need['title'] ?? '',
        'buyerId': uid,
        'sellerId': sellerId,
        'buyerName': buyer['fullName'] ?? '',
        'buyerPhone': buyer['phone'] ?? '',
        'sellerName': chosenData['sellerName'] ?? '',
        'sellerPhone': chosenData['sellerPhone'] ?? '',
        'lastMessage': '',
        'lastAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      messenger.showSnackBar(
        const SnackBar(content: Text('Seller বাছাই হয়েছে। Chat খোলা হয়েছে।')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('বাছাই করা যায়নি, আবার চেষ্টা করুন')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Need বিস্তারিত')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: db.collection('needs').doc(widget.needId).snapshots(),
        builder: (context, needSnap) {
          if (needSnap.hasError) {
            return const Center(child: Text('Need আনা যায়নি'));
          }
          if (!needSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final nd = needSnap.data!.data();
          if (nd == null) {
            return const Center(
              child: EmptyState(
                icon: Icons.search_off_rounded,
                message: 'Need পাওয়া যায়নি',
              ),
            );
          }

          final status = (nd['status'] as String?) ?? 'active';
          final canSelect =
              status == 'active' && !isExpired(nd['expiresAt'] as Timestamp?);

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db
                .collection('offers')
                .where('needId', isEqualTo: widget.needId)
                .where('buyerId', isEqualTo: uid)
                .snapshots(),
            builder: (context, offerSnap) {
              final offers = (offerSnap.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                ..sort((a, b) {
                  final pa = (a.data()['price'] as num?) ?? 0;
                  final pb = (b.data()['price'] as num?) ?? 0;
                  return pa.compareTo(pb);
                });

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  _NeedInfoCard(data: nd),
                  const SizedBox(height: 16),
                  if (status == 'matched')
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(chatId: widget.needId),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Chat খুলুন'),
                    ),
                  if (canSelect)
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _closeNeed,
                      icon: const Icon(Icons.block_rounded),
                      label: const Text('Need বন্ধ করুন'),
                    ),
                  const SizedBox(height: 24),
                  SectionTitle(
                    title: 'Offer সমূহ',
                    trailing: StatusPill(
                      label: '${offers.length}টি',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (offers.isEmpty)
                    const AppCard(
                      child: EmptyState(
                        icon: Icons.local_offer_outlined,
                        message: 'এখনো কোনো Offer আসেনি',
                      ),
                    ),
                  for (final o in offers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OfferCard(
                        offer: o,
                        canSelect: canSelect && !_busy,
                        onSelect: () => _selectOffer(nd, offers, o),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _NeedInfoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _NeedInfoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cat = findCategory((data['category'] as String?) ?? '');
    final urgent = data['urgent'] == true;
    final budget = data['budget'];
    final desc = (data['description'] as String?) ?? '';
    final area = [data['areaText'], data['upazilaOrThana'], data['district']]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(', ');

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: cat?.icon ?? Icons.more_horiz,
                color: cat?.color ?? AppColors.locked,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  (data['title'] as String?) ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
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
                label: categoryLabel((data['category'] as String?) ?? ''),
                color: cat?.color ?? AppColors.locked,
              ),
              needStatusPill(data),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              desc,
              style: const TextStyle(
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 14),
          InfoRow(icon: Icons.place_outlined, text: area),
          if (budget != null) ...[
            const SizedBox(height: 8),
            InfoRow(icon: Icons.payments_outlined, text: 'বাজেট: $budget টাকা'),
          ],
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> offer;
  final bool canSelect;
  final VoidCallback onSelect;

  const _OfferCard({
    required this.offer,
    required this.canSelect,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final d = offer.data();
    final status = (d['status'] as String?) ?? 'sent';
    final accepted = status == 'accepted';
    final rejected = status == 'rejected';
    final sellerName = (d['sellerName'] as String?) ?? '';
    final phone = (d['sellerPhone'] as String?) ?? '';
    final message = (d['message'] as String?) ?? '';
    final price = d['price']?.toString() ?? '';
    final photos = ((d['photos'] as List?) ?? const [])
        .whereType<String>()
        .toList();

    return Opacity(
      opacity: rejected ? 0.55 : 1,
      child: AppCard(
        color: accepted ? AppColors.primaryLight : AppColors.surface,
        borderColor: accepted ? AppColors.primary : null,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconBadge(
                  icon: Icons.storefront_outlined,
                  color: AppColors.primary,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sellerName.isEmpty ? 'Seller' : sellerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Text(
                  '৳ $price',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.textDark,
                  height: 1.4,
                ),
              ),
            ],
            if (photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              PhotoStrip(photos: photos),
            ],
            if (accepted && phone.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        phone,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'নম্বর কপি করুন',
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: phone));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('নম্বর কপি হয়েছে')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (accepted)
              const StatusPill(
                label: 'বাছাই করা হয়েছে',
                color: AppColors.success,
                icon: Icons.check_circle_outline,
              )
            else if (rejected)
              const StatusPill(label: 'বাতিল', color: AppColors.locked)
            else if (canSelect)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSelect,
                  child: const Text('এই Seller-কে বাছাই করুন'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
