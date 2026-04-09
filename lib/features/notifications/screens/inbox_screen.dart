import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthAppProvider>();
    final uid = auth.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: uid == null
          ? const Center(child: Text('Please login to see notifications'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('toUserId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: AppColors.textHint),
                        SizedBox(height: 16),
                        Text('Koi nayi notification nahi hai'),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final isRead = d['read'] ?? false;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isRead ? AppColors.surfaceVariant : AppColors.primaryLight,
                        child: Icon(
                          _getIcon(d['type']),
                          color: isRead ? AppColors.textSecondary : Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        d['title'] ?? '',
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(d['body'] ?? ''),
                      trailing: Text(
                        _formatTime(d['createdAt'] as Timestamp),
                        style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                      ),
                      onTap: () {
                        // Mark as read
                        docs[i].reference.update({'read': true});
                        // TODO: Navigate based on type
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  IconData _getIcon(String? type) {
    return switch (type) {
      'message' => Icons.chat_bubble_outline,
      'agreement' => Icons.handshake_outlined,
      'job' => Icons.work_outline,
      _ => Icons.notifications_outlined,
    };
  }

  String _formatTime(Timestamp ts) {
    final dt = ts.toDate();
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
