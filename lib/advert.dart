import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

import 'bd_locations.dart';
import 'telegram_service.dart';
import 'telegram_config.dart';
import 'ui.dart';

// ============================================================
// Ad / Discount Form
// ============================================================
class AdvertFormScreen extends StatefulWidget {
  final String type; // 'ad' or 'discount'
  const AdvertFormScreen({super.key, required this.type});

  @override
  State<AdvertFormScreen> createState() => _AdvertFormScreenState();
}

class _AdvertFormScreenState extends State<AdvertFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(); // For discount amount

  // Media
  File? _imageFile;
  File? _videoFile;
  VideoPlayerController? _videoController;
  int _videoDuration = 0;

  // Area
  String? _division;
  String? _district;
  String? _upazila;
  final List<Map<String, String>> _targetAreas = [];

  int _durationDays = 7;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _linkCtrl.dispose();
    _discountCtrl.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // Media Pickers
  // ----------------------------------------------------------
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 20),
    );
    if (picked == null) return;

    final file = File(picked.path);
    final controller = VideoPlayerController.file(file);
    await controller.initialize();

    final duration = controller.value.duration.inSeconds;

    if (duration > 20) {
      controller.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ভিডিও সর্বোচ্চ ২০ সেকেন্ড হতে পারবে')),
        );
      }
      return;
    }

    setState(() {
      _videoFile = file;
      _videoController = controller;
      _videoDuration = duration;
    });
  }

  // ----------------------------------------------------------
  // Area Adding
  // ----------------------------------------------------------
  void _addArea() {
    if (_division == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('বিভাগ বাছাই করুন')),
      );
      return;
    }
    if (_district == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('জেলা বাছাই করুন')),
      );
      return;
    }

    final area = {
      'division': _division!,
      'district': _district!,
      'upazila': _upazila ?? '',
    };

    if (_targetAreas.any((a) => a['district'] == area['district'] && a['upazila'] == area['upazila'])) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('এই এলাকাটি আগেই যোগ করা হয়েছে')),
      );
      return;
    }

    setState(() {
      _targetAreas.add(area);
      _upazila = null;
    });
  }

  // ----------------------------------------------------------
  // Save & Upload
  // ----------------------------------------------------------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_targetAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অন্তত একটি টার্গেট এলাকা যোগ করুন')),
      );
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      String? tgVideoFileId;
      String? tgVideoThumbId;

      // 1. Upload Video to Telegram (if exists)
      if (_videoFile != null) {
        final thumbPath = await VideoThumbnail.thumbnailFile(
          video: _videoFile!.path,
          thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 200,
          quality: 70,
        );

        final tgResult = await TelegramService.sendVideo(
          video: _videoFile!,
          caption: 'New ${widget.type.toUpperCase()}: ${_titleCtrl.text.trim()}',
          durationSeconds: _videoDuration,
          thumbnailPath: thumbPath,
          chatId: TelegramConfig.adminChatId,
        );

        if (tgResult == null) {
          throw Exception('Telegram upload failed');
        }
        tgVideoFileId = tgResult['fileId'];
        tgVideoThumbId = tgResult['messageId'].toString();
      }

      // 2. Save to Firestore
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('adverts').add({
        'type': widget.type, // 'ad' or 'discount'
        'ownerId': uid,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'discount': widget.type == 'discount' ? _discountCtrl.text.trim() : null,
        'link': _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
        'targetAreas': _targetAreas,
        'durationDays': _durationDays,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'videoFileId': tgVideoFileId,
        'videoDuration': tgVideoFileId != null ? _videoDuration : null,
        'hasImage': _imageFile != null,
      });

      // 3. Send Notification to Admin
      await TelegramService.sendMessage(
        text: '🔔 <b>নতুন ${widget.type == 'ad' ? 'বিজ্ঞাপন' : 'ডিসকাউন্ট'} এসেছে!</b>\n\n'
            '<b>শিরোনাম:</b> ${_titleCtrl.text.trim()}\n'
            '<b>এলাকা:</b> ${_targetAreas.map((a) => a['district']).join(", ")}\n\n'
            'Admin Panel থেকে Approve করুন।',
      );

      nav.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('সফলভাবে জমা হয়েছে। Admin Approve করলে পাবলিশ হবে।')),
      );

    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('জমা দেওয়া যায়নি। ইন্টারনেট চেক করুন।')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ----------------------------------------------------------
  // UI Build
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDiscount = widget.type == 'discount';
    final districts = _division == null
        ? <String>[]
        : (BdLocations.districtsByDivision[_division!] ?? <String>[]);
    final upazilas = _district == null
        ? <String>[]
        : BdLocations.upazilasOf(_district!);

    return Scaffold(
      appBar: AppBar(
        title: Text(isDiscount ? 'ডিসকাউন্ট দিন' : 'বিজ্ঞাপন দিন'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle(title: isDiscount ? 'ডিসকাউন্টের তথ্য' : 'বিজ্ঞাপনের তথ্য'),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _titleCtrl,
                    label: 'শিরোনাম',
                    icon: Icons.title,
                    validator: (v) => v!.isEmpty ? 'শিরোনাম দিন' : null,
                  ),
                  AppTextField(
                    controller: _descCtrl,
                    label: 'বিস্তারিত',
                    icon: Icons.notes,
                    maxLines: 3,
                    validator: (v) => v!.isEmpty ? 'বিস্তারিত দিন' : null,
                  ),
                  if (isDiscount)
                    AppTextField(
                      controller: _discountCtrl,
                      label: 'ডিসকাউন্টের পরিমাণ (যেমন: ২০% বা ১০০৳)',
                      icon: Icons.discount,
                      validator: (v) => v!.isEmpty ? 'পরিমাণ দিন' : null,
                    ),
                  AppTextField(
                    controller: _linkCtrl,
                    label: 'লিংক (ঐচ্ছিক)',
                    icon: Icons.link,
                    keyboard: TextInputType.url,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Media Section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle(title: 'ছবি ও ভিডিও (ঐচ্ছিক)'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: Text(_imageFile == null ? 'ছবি যোগ করুন' : 'ছবি বদলান'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickVideo,
                          icon: const Icon(Icons.video_file),
                          label: Text(_videoFile == null ? 'ভিডিও যোগ করুন' : 'ভিডিও বদলান'),
                        ),
                      ),
                    ],
                  ),
                  if (_videoFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'ভিডিও সাইজ: $_videoDuration সেকেন্ড',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Target Areas
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle(title: 'কোন এলাকায় দেখাবে?'),
                  const SizedBox(height: 16),
                  AppDropdown<String>(
                    label: 'বিভাগ',
                    icon: Icons.map,
                    value: _division,
                    items: BdLocations.divisions,
                    itemLabel: (e) => e,
                    onChanged: (v) => setState(() {
                      _division = v;
                      _district = null;
                      _upazila = null;
                    }),
                  ),
                  if (_division != null)
                    AppDropdown<String>(
                      label: 'জেলা',
                      icon: Icons.location_city,
                      value: _district,
                      items: districts,
                      itemLabel: (e) => e,
                      onChanged: (v) => setState(() {
                        _district = v;
                        _upazila = null;
                      }),
                    ),
                  if (_district != null)
                    AppDropdown<String>(
                      label: 'উপজেলা (ফাঁকা রাখলে পুরো জেলা)',
                      icon: Icons.place,
                      value: _upazila,
                      items: upazilas,
                      itemLabel: (e) => e,
                      onChanged: (v) => setState(() => _upazila = v),
                    ),
                  OutlinedButton(
                    onPressed: _addArea,
                    child: const Text('এলাকা যোগ করুন'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _targetAreas.map((a) {
                      return Chip(
                        label: Text('${a['upazila'] ?? ''} ${a['district']}'),
                        onDeleted: () => setState(() => _targetAreas.remove(a)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Duration
            AppCard(
              child: AppDropdown<int>(
                label: 'কত দিন চলবে?',
                icon: Icons.timer,
                value: _durationDays,
                items: const [3, 7, 15, 30],
                itemLabel: (e) => '$e দিন',
                onChanged: (v) => setState(() => _durationDays = v ?? 7),
              ),
            ),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('জমা দিন (Admin Approve করবে)'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
