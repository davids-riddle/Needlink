import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'ui.dart';

// একটি Offer-এ সর্বোচ্চ কয়টি ছবি
const int maxOfferPhotos = 3;

// একটি ছবির সর্বোচ্চ আকার (বাইট)। Firestore-এর ১ MB সীমার জন্য।
const int maxPhotoBytes = 150 * 1024;

Uint8List? _decode(String b64) {
  try {
    return base64Decode(b64);
  } catch (_) {
    return null;
  }
}

// ছবি বাছাই: ফোনেই ছোট ও হালকা করে base64 লেখা হিসেবে ফেরত দেয়
Future<List<String>> pickPhotosAsBase64(
  BuildContext context,
  int remaining,
) async {
  final messenger = ScaffoldMessenger.of(context);

  if (remaining <= 0) {
    messenger.showSnackBar(
      const SnackBar(content: Text('সর্বোচ্চ ৩টি ছবি দেওয়া যাবে')),
    );
    return [];
  }

  final picked = await ImagePicker().pickMultiImage(
    maxWidth: 600,
    maxHeight: 600,
    imageQuality: 60,
  );
  if (picked.isEmpty) return [];

  if (picked.length > remaining) {
    messenger.showSnackBar(
      SnackBar(content: Text('শুধু প্রথম $remaining টি ছবি নেওয়া হয়েছে')),
    );
  }

  final result = <String>[];
  for (final file in picked.take(remaining)) {
    final bytes = await file.readAsBytes();
    if (bytes.length > maxPhotoBytes) {
      messenger.showSnackBar(
        const SnackBar(content: Text('একটি ছবি খুব বড়, অন্য ছবি বাছাই করুন')),
      );
      continue;
    }
    result.add(base64Encode(bytes));
  }
  return result;
}

// একটি ছবি বড় করে দেখা
void showPhotoViewer(BuildContext context, List<String> photos, int index) {
  final bytes = _decode(photos[index]);
  if (bytes == null) return;
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          InteractiveViewer(
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    ),
  );
}

// Offer কার্ডে ছবির সারি
class PhotoStrip extends StatelessWidget {
  final List<String> photos;
  final double size;

  const PhotoStrip({super.key, required this.photos, this.size = 84});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final bytes = _decode(photos[i]);
          return GestureDetector(
            onTap: () => showPhotoViewer(context, photos, i),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Container(
                width: size,
                height: size,
                color: AppColors.background,
                child: bytes == null
                    ? const Icon(Icons.broken_image_outlined,
                        color: AppColors.locked)
                    : Image.memory(
                        bytes,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
