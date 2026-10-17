import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui.dart';

// ============================================================
// Chat তালিকা
// ============================================================
class ChatListScreen extends StatelessWidget {
  final bool asBuyer;
  const ChatListScreen({super.key, required this.asBuyer});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final field = asBuyer ? 'buyerId' : 'sellerId';

    return Scaffold(
      appBar: AppBar(title: const Text('আমার Chat')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where(field, isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Chat আনা যায়নি'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs.toList()
            ..sort((a, b) {
              final ta = (a.data()['lastAt'] as Timestamp?)?.toDate() ??
                  DateTime(2000);
              final tb = (b.data()['lastAt'] as Timestamp?)?.toDate() ??
                  DateTime(2000);
              return tb.compareTo(ta);
            });

          if (docs.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.forum_outlined,
                message: 'এখনো কোনো Chat নেই।\nSeller বাছাই হলে এখানে আসবে।',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final other = asBuyer
                  ? ((d['sellerName'] as String?) ?? '')
                  : ((d['buyerName'] as String?) ?? '');
              final last = (d['lastMessage'] as String?) ?? '';
              final needTitle = (d['needTitle'] as String?) ?? '';
              final initial = other.trim().isEmpty
                  ? '?'
                  : other.trim().substring(0, 1);

              return AppCard(
                padding: const EdgeInsets.all(14),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(chatId: docs[i].id),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 23,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            other.isEmpty ? 'ব্যবহারকারী' : other,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            needTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (last.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.locked),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// Chat স্ক্রিন
// ============================================================
class ChatScreen extends StatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  bool _sending = false;

  DocumentReference<Map<String, dynamic>> get _chatRef =>
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String uid) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final msgRef = _chatRef.collection('messages').doc();
      batch.set(msgRef, {
        'senderId': uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(_chatRef, {
        'lastMessage': text,
        'lastAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      _msgCtrl.clear();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('বার্তা পাঠানো যায়নি')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _chatRef.snapshots(),
        builder: (context, chatSnap) {
          if (chatSnap.hasError) {
            return const Center(child: Text('Chat আনা যায়নি'));
          }
          if (!chatSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chat = chatSnap.data!.data();
          if (chat == null) {
            return const Center(child: Text('Chat পাওয়া যায়নি'));
          }

          final isBuyer = chat['buyerId'] == uid;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: _ChatHeader(chat: chat, isBuyer: isBuyer),
              ),
              Expanded(
                child: _MessageList(chatRef: _chatRef, uid: uid),
              ),
              _InputBar(
                controller: _msgCtrl,
                sending: _sending,
                onSend: () => _send(uid),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final Map<String, dynamic> chat;
  final bool isBuyer;

  const _ChatHeader({required this.chat, required this.isBuyer});

  @override
  Widget build(BuildContext context) {
    final otherName = isBuyer
        ? ((chat['sellerName'] as String?) ?? '')
        : ((chat['buyerName'] as String?) ?? '');
    final otherPhone = isBuyer
        ? ((chat['sellerPhone'] as String?) ?? '')
        : ((chat['buyerPhone'] as String?) ?? '');
    final needTitle = (chat['needTitle'] as String?) ?? '';

    return GradientBox(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            needTitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            otherName.isEmpty ? 'ব্যবহারকারী' : otherName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (otherPhone.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Expanded(
                  child: SelectableText(
                    otherPhone,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'কপি করুন',
                  color: Colors.white,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: otherPhone));
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

class _MessageList extends StatelessWidget {
  final DocumentReference<Map<String, dynamic>> chatRef;
  final String uid;

  const _MessageList({required this.chatRef, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: chatRef
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, msgSnap) {
        if (msgSnap.hasError) {
          return const Center(child: Text('বার্তা আনা যায়নি'));
        }
        if (!msgSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final msgs = msgSnap.data!.docs;
        if (msgs.isEmpty) {
          return const Center(
            child: EmptyState(
              icon: Icons.chat_outlined,
              message: 'প্রথম বার্তাটি পাঠান',
            ),
          );
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: msgs.length,
          itemBuilder: (context, i) {
            final m = msgs[i].data();
            final mine = m['senderId'] == uid;

            return Align(
              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: mine ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(mine ? 18 : 4),
                    bottomRight: Radius.circular(mine ? 4 : 18),
                  ),
                  border: mine ? null : Border.all(color: AppColors.border),
                ),
                child: Text(
                  (m['text'] as String?) ?? '',
                  style: TextStyle(
                    color: mine ? Colors.white : AppColors.textDark,
                    height: 1.4,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'বার্তা লিখুন',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
