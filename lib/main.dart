import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'admin.dart';
import 'bd_locations.dart';
import 'buyer.dart';
import 'seller.dart';
import 'ui.dart';

class AppConfig {
  static const String appName = 'Need Link';
  static const bool buyerEnabled = true;
  static const bool sellerEnabled = true;
  static const bool adsEnabled = true; // Ad চালু করা হলো
  static const bool discountEnabled = true; // Discount চালু করা হলো
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const NeedLinkApp());
}

class NeedLinkApp extends StatelessWidget {
  const NeedLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const AuthScreen();
      },
    );
  }
}

// ============================================================
// Login / Register
// ============================================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _upazilaOtherCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  String? _division;
  String? _district;
  String? _upazila;

  bool _isLogin = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _upazilaOtherCtrl.dispose();
    _areaCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _requiredField(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label দিন';
    return null;
  }

  String? _validatePhone(String? value) {
    final v = value?.trim() ?? '';
    if (!RegExp(r'^01\d{9}$').hasMatch(v)) {
      return 'সঠিক ফোন নম্বর দিন (01XXXXXXXXX)';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (!v.contains('@') || !v.contains('.')) return 'সঠিক ইমেইল দিন';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে';
    }
    return null;
  }

  String _authMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'ইমেইলটি সঠিক নয়';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'ইমেইল বা পাসওয়ার্ড ভুল';
      case 'email-already-in-use':
        return 'এই ইমেইল দিয়ে আগেই অ্যাকাউন্ট আছে';
      case 'weak-password':
        return 'পাসওয়ার্ড বেশি দুর্বল';
      case 'network-request-failed':
        return 'ইন্টারনেট সংযোগ চেক করুন';
      default:
        return 'সমস্যা হয়েছে, আবার চেষ্টা করুন';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    try {
      if (_isLogin) {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
      } else {
        final upazilaValue = _upazila == BdLocations.otherLabel
            ? _upazilaOtherCtrl.text.trim()
            : _upazila;

        final cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
          'fullName': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'division': _division,
          'district': _district,
          'upazilaOrThana': upazilaValue,
          'areaText': _areaCtrl.text.trim(),
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      _showError(_authMessage(e.code));
    } catch (_) {
      _showError('কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _header() {
    return SafeArea(
      bottom: false,
      child: GradientBox(
        radius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.link_rounded, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 14),
            const Text(
              AppConfig.appName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'প্রয়োজন বলুন, সমাধান পান',
              style: TextStyle(color: Colors.white.withOpacity(0.85)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final districts = _division == null
        ? <String>[]
        : (BdLocations.districtsByDivision[_division!] ?? <String>[]);
    final upazilas = _district == null
        ? <String>[]
        : BdLocations.upazilasOf(_district!);

    return Scaffold(
      body: Column(
        children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('লগইন')),
                          ButtonSegment(value: false, label: Text('নতুন অ্যাকাউন্ট')),
                        ],
                        selected: {_isLogin},
                        onSelectionChanged: (s) =>
                            setState(() => _isLogin = s.first),
                      ),
                      const SizedBox(height: 18),
                      AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _isLogin
                                    ? 'আপনার অ্যাকাউন্টে ঢুকুন'
                                    : 'নতুন অ্যাকাউন্ট খুলুন',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 18),
                              if (!_isLogin) ...[
                                AppTextField(
                                  controller: _nameCtrl,
                                  label: 'পুরো নাম',
                                  icon: Icons.person_outline,
                                  validator: (v) => _requiredField(v, 'পুরো নাম'),
                                ),
                                AppTextField(
                                  controller: _phoneCtrl,
                                  label: 'ফোন নম্বর (01XXXXXXXXX)',
                                  icon: Icons.phone_outlined,
                                  keyboard: TextInputType.phone,
                                  validator: _validatePhone,
                                ),
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
                                        _requiredField(v, 'উপজেলা / থানার নাম'),
                                  ),
                                AppTextField(
                                  controller: _areaCtrl,
                                  label: 'বিস্তারিত এলাকা',
                                  icon: Icons.home_outlined,
                                  validator: (v) =>
                                      _requiredField(v, 'বিস্তারিত এলাকা'),
                                ),
                              ],
                              AppTextField(
                                controller: _emailCtrl,
                                label: 'ইমেইল',
                                icon: Icons.mail_outline,
                                keyboard: TextInputType.emailAddress,
                                validator: _validateEmail,
                              ),
                              AppTextField(
                                controller: _passCtrl,
                                label: 'পাসওয়ার্ড',
                                icon: Icons.lock_outline,
                                obscure: true,
                                validator: _validatePassword,
                              ),
                              const SizedBox(height: 6),
                              ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                child: _loading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(_isLogin
                                        ? 'লগইন করুন'
                                        : 'অ্যাকাউন্ট তৈরি করুন'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Home
// ============================================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openItem(BuildContext context, _HomeItem item) {
    if (!item.active) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('এই অংশটি শীঘ্রই আসছে')),
      );
      return;
    }
    if (item.title == 'Buyer') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BuyerScreen()),
      );
    } else if (item.title == 'Seller') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SellerScreen()),
      );
    } else if (item.title == 'বিজ্ঞাপন') {
      // Ad Screen (পরে বানাবো, আপাতত মেসেজ)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('বিজ্ঞাপন সেকশন শীঘ্রই আসছে')),
      );
    } else if (item.title == 'Discount') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ডিসকাউন্ট সেকশন শীঘ্রই আসছে')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    final items = [
      _HomeItem(
        title: 'Buyer',
        subtitle: 'প্রয়োজন পোস্ট করুন',
        icon: Icons.shopping_bag_outlined,
        color: AppColors.primary,
        active: AppConfig.buyerEnabled,
      ),
      _HomeItem(
        title: 'Seller',
        subtitle: 'সেবা ও পণ্য দিন',
        icon: Icons.storefront_outlined,
        color: AppColors.info,
        active: AppConfig.sellerEnabled,
      ),
      _HomeItem(
        title: 'বিজ্ঞাপন',
        subtitle: 'ব্যবসা প্রচার করুন',
        icon: Icons.campaign_outlined,
        color: AppColors.accent,
        active: AppConfig.adsEnabled,
      ),
      _HomeItem(
        title: 'Discount',
        subtitle: 'অফার ঘোষণা করুন',
        icon: Icons.local_offer_outlined,
        color: AppColors.violet,
        active: AppConfig.discountEnabled,
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: GradientBox(
              radius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 26),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConfig.appName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'স্বাগতম',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const AdminAppBarAction(color: Colors.white),
                  IconButton(
                    tooltip: 'লগআউট',
                    color: Colors.white,
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.95,
                children: items
                    .map((item) => _HomeCard(
                          item: item,
                          onTap: () => _openItem(context, item),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool active;

  const _HomeItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.active,
  });
}

class _HomeCard extends StatelessWidget {
  final _HomeItem item;
  final VoidCallback onTap;

  const _HomeCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = item.active ? item.color : AppColors.locked;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      color: item.active ? AppColors.surface : const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconBadge(icon: item.icon, color: color, size: 48),
              if (!item.active)
                const Icon(Icons.lock_outline_rounded,
                    size: 18, color: AppColors.locked),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: item.active ? AppColors.textDark : AppColors.locked,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.active ? item.subtitle : 'শীঘ্রই আসছে',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
