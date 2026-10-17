import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ============================================================
// রং (পুরো অ্যাপের রং এখান থেকেই আসবে)
// ============================================================
class AppColors {
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF0B4F4A);
  static const Color primaryLight = Color(0xFFD1FAE5);
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFEF3C7);
  static const Color background = Color(0xFFF3F6F5);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color locked = Color(0xFF94A3B8);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);
  static const Color violet = Color(0xFF7C3AED);
}

// ============================================================
// Radius
// ============================================================
class AppRadius {
  static const double card = 18;
  static const double button = 14;
  static const double pill = 999;
}

// ============================================================
// Theme
// ============================================================
class AppTheme {
  static ThemeData light() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================
// ক্যাটাগরি
// ============================================================
class NeedCategory {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const NeedCategory(this.key, this.label, this.icon, this.color);
}

const List<NeedCategory> needCategories = [
  NeedCategory('products', 'পণ্য', Icons.inventory_2_outlined, Color(0xFF0F766E)),
  NeedCategory('services', 'সেবা', Icons.build_outlined, Color(0xFF2563EB)),
  NeedCategory('house_room', 'বাসা / রুম', Icons.house_outlined, Color(0xFFD97706)),
  NeedCategory('tutor', 'টিউটর', Icons.school_outlined, Color(0xFF7C3AED)),
  NeedCategory('jobs', 'চাকরি', Icons.work_outline, Color(0xFF4F46E5)),
  NeedCategory('digital', 'ডিজিটাল / ফ্রিল্যান্স', Icons.laptop_mac_outlined, Color(0xFF0891B2)),
  NeedCategory('transport', 'পরিবহন', Icons.directions_car_outlined, Color(0xFFEA580C)),
  NeedCategory('event', 'ইভেন্ট সেবা', Icons.celebration_outlined, Color(0xFFDB2777)),
  NeedCategory('rental', 'ভাড়া', Icons.key_outlined, Color(0xFF15803D)),
  NeedCategory('other', 'অন্যান্য', Icons.more_horiz, Color(0xFF475569)),
];

NeedCategory? findCategory(String key) {
  for (final c in needCategories) {
    if (c.key == key) return c;
  }
  return null;
}

String categoryLabel(String key) => findCategory(key)?.label ?? 'অন্যান্য';

const List<String> conditionOptions = ['নতুন', 'ব্যবহৃত', 'যেকোনো'];

const Map<int, String> validityOptions = {
  1: '১ দিন',
  3: '৩ দিন',
  7: '৭ দিন',
  15: '১৫ দিন',
  30: '৩০ দিন',
};

const List<int> durationOptions = [1, 7, 15, 30, 60, 90, 120, 365];

String durationLabel(int d) => d == 365 ? '১ বছর' : '$d দিন';

// ============================================================
// এলাকার লেখা
// ============================================================
String areaLabel({
  required String upazila,
  required String district,
  required String division,
}) =>
    '$upazila, $district • $division';

String areaGroupLabel({
  required String district,
  required String division,
}) =>
    '$district • $division';

// Seller-এর sellerAreas doc থেকে এলাকার নাম বানায় (Fix করা হলো)
String areaScopeLabel(Map<String, dynamic> d) {
  final scope = (d['scope'] as String?) ?? 'upazila';
  final division = (d['division'] as String?) ?? '';
  final district = (d['district'] as String?) ?? '';
  final upazila = (d['upazila'] as String?) ?? '';

  if (scope == 'division') {
    return division.isEmpty ? 'বিভাগ নেই' : division;
  }
  if (scope == 'district') {
    return district.isEmpty ? 'জেলা নেই' : district;
  }
  if (upazila.isEmpty && district.isEmpty) return 'এলাকা নেই';
  if (district.isEmpty) return upazila;
  if (upazila.isEmpty) return district;
  return '$upazila, $district';
}

// ============================================================
// সময়ের সহায়ক
// ============================================================
bool isExpired(Timestamp? ts) =>
    ts == null || !ts.toDate().isAfter(DateTime.now());

String remainingText(Timestamp? ts) {
  if (ts == null) return '';
  final diff = ts.toDate().difference(DateTime.now());
  if (diff.isNegative) return 'মেয়াদ শেষ';
  return '${diff.inDays} দিন ${diff.inHours % 24} ঘণ্টা বাকি';
}

// ============================================================
// শেয়ার্ড উইজেট
// ============================================================
class GradientBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry radius;

  const GradientBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = const BorderRadius.all(Radius.circular(AppRadius.card)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
      ),
      child: child,
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.surface,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: box,
      ),
    );
  }
}

class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionTitle({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primaryLight,
            child: Icon(icon, size: 30, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboard;
  final int maxLines;
  final bool obscure;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboard,
    this.maxLines = 1,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboard,
        obscureText: obscure,
        maxLines: obscure ? 1 : maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;

  const AppDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        items: items
            .map((e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(itemLabel(e), overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String yes,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('না'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(yes),
        ),
      ],
    ),
  );
  return ok == true;
}

// ============================================================
// Need ও আইটেমের স্ট্যাটাস
// ============================================================
Widget needStatusPill(Map<String, dynamic> d) {
  final status = (d['status'] as String?) ?? 'active';
  final exp = d['expiresAt'] as Timestamp?;

  if (status == 'matched') {
    return const StatusPill(
      label: 'Seller বাছাই হয়েছে',
      color: AppColors.primary,
      icon: Icons.handshake_outlined,
    );
  }
  if (status == 'closed') {
    return const StatusPill(
      label: 'বন্ধ',
      color: AppColors.locked,
      icon: Icons.lock_outline,
    );
  }
  if (isExpired(exp)) {
    return const StatusPill(
      label: 'মেয়াদ শেষ',
      color: AppColors.danger,
      icon: Icons.timer_off_outlined,
    );
  }
  return StatusPill(
    label: remainingText(exp),
    color: AppColors.primary,
    icon: Icons.schedule_rounded,
  );
}

class ItemStatus {
  final String label;
  final Color color;
  final IconData icon;
  final bool active;
  final bool canRenew;
  final bool canDelete;

  const ItemStatus({
    required this.label,
    required this.color,
    required this.icon,
    required this.active,
    required this.canRenew,
    required this.canDelete,
  });
}

ItemStatus itemStatusOf(Map<String, dynamic> d) {
  final status = (d['status'] as String?) ?? 'pending';
  final exp = d['expiresAt'] as Timestamp?;

  if (status == 'approved' && !isExpired(exp)) {
    return ItemStatus(
      label: 'সক্রিয় • ${remainingText(exp)}',
      color: AppColors.success,
      icon: Icons.check_circle_outline,
      active: true,
      canRenew: false,
      canDelete: false,
    );
  }
  if (status == 'approved') {
    return const ItemStatus(
      label: 'মেয়াদ শেষ',
      color: AppColors.danger,
      icon: Icons.timer_off_outlined,
      active: false,
      canRenew: true,
      canDelete: true,
    );
  }
  if (status == 'rejected') {
    return const ItemStatus(
      label: 'বাতিল হয়েছে',
      color: AppColors.danger,
      icon: Icons.cancel_outlined,
      active: false,
      canRenew: true,
      canDelete: true,
    );
  }
  return const ItemStatus(
    label: 'অনুমোদনের অপেক্ষায়',
    color: AppColors.warning,
    icon: Icons.hourglass_top_rounded,
    active: false,
    canRenew: false,
    canDelete: true,
  );
}
