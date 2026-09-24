import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/all_models.dart';
import '../../../core/services/firestore_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/status_view.dart';
import '../../../shared/widgets/section_header.dart';

class MyJobsScreen extends StatelessWidget {
  const MyJobsScreen({super.key});

  bool _isActive(ChatModel c) =>
      c.status == ChatStatus.chatting ||
      c.status == ChatStatus.agreed ||
      c.status == ChatStatus.contactVisible;

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthAppProvider>().uid;
    if (uid == null) {
      return const Scaffold(body: EmptyView(icon: Icons.lock_outline, message: 'Please login'));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Work'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.work_history_outlined), text: 'Working Now'),
              Tab(icon: Icon(Icons.history_rounded), text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _JobsList(uid: uid, activeOnly: true, isActive: _isActive),
            _JobsList(uid: uid, activeOnly: false, isActive: _isActive),
          ],
        ),
      ),
    );
  }
}

class _JobsList extends StatelessWidget {
  final String uid;
  final bool activeOnly;
  final bool Function(ChatModel) isActive;

  const _JobsList({
    required this.uid,
    required this.activeOnly,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatModel>>(
      stream: FirestoreService().streamUserChats(uid),
      builder: (context, snap) {
        final chats = snap.data ?? [];
        final filtered =
            chats.where((c) => activeOnly ? isActive(c) : !isActive(c)).toList();

        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }
        if (filtered.isEmpty) {
          return EmptyView(
            icon: activeOnly
                ? Icons.hourglass_empty_rounded
                : Icons.done_all_rounded,
            message: activeOnly
                ? 'No work in progress'
                : 'No history yet',
            detail: activeOnly
                ? 'Start chatting with a provider to begin.'
                : 'Completed jobs will appear here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _ChatTile(chat: filtered[i]),
        );
      },
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatModel chat;

  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: FirestoreService()
          .getUser(chat.status == ChatStatus.completed
              ? chat.providerId
              : chat.userId),
      builder: (context, snap) {
        final name = snap.data?.name;
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Text(
                name == null || name.isEmpty
                    ? '?'
                    : name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(chat.providerId == (context.read<AuthAppProvider>().uid)
                ? 'Customer'
                : (name ?? 'Provider')),
            subtitle: Text(
              chat.lastMessage ?? 'New request',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: _StatusPill(status: chat.status),
            onTap: () => context.push('/chat/${chat.id}'),
          ),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ChatStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ChatStatus.requested => ('Requested', AppColors.warning),
      ChatStatus.chatting => ('Chatting', AppColors.info),
      ChatStatus.agreed => ('Deal Agreed', AppColors.primary),
      ChatStatus.contactVisible => ('In Progress', AppColors.info),
      ChatStatus.completed => ('Completed', AppColors.online),
      ChatStatus.cancelled => ('Closed', AppColors.textMuted),
    };
    return PillBadge(text: label, color: color);
  }
}