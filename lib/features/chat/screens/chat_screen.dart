import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/all_models.dart';
import '../../../core/services/firestore_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../shared/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _firestoreService = FirestoreService();
  Future<UserModel?>? _partnerFuture;
  int _prevMessageCount = 0;

  static const _quickReplies = [
    'Kaam hai',
    'Kitna charge?',
    'Kab aoge?',
    'Theek hai',
    'Nahi chahiye',
  ];

  void _cachePartner(ChatModel chat, String currentUid) {
    if (_partnerFuture != null) return; // Already cached
    final partnerId = chat.userId == currentUid ? chat.providerId : chat.userId;
    _partnerFuture = _firestoreService.getUser(partnerId);

    // Mark messages as seen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firestoreService.markMessagesSeen(widget.chatId, currentUid);
    });

    setState(() {});
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthAppProvider>();
    final currentUid = auth.uid ?? '';

    return Scaffold(
      body: StreamBuilder<ChatModel?>(
        stream: _firestoreService.streamChat(widget.chatId),
        builder: (context, chatSnap) {
          final chat = chatSnap.data;

          return Column(
            children: [
              _buildAppBar(context, chat, currentUid),

              if (chat != null)
                Builder(builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _cachePartner(chat, currentUid);
                  });
                  return _buildStatusBanner(context, chat, currentUid);
                }),

              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _firestoreService.streamMessages(widget.chatId),
                  builder: (context, msgSnap) {
                    final messages = msgSnap.data ?? [];
                    final hasMessages = messages.isNotEmpty;

                    if (messages.length > _prevMessageCount) {
                      _prevMessageCount = messages.length;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    }

                    final inputEnabled =
                        _inputEnabledFor(chat, currentUid, hasMessages);

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: messages.length,
                            itemBuilder: (context, i) => _MessageBubble(
                              message: messages[i],
                              isMe: messages[i].senderId == currentUid,
                            ),
                          ),
                        ),
                        if (inputEnabled)
                          _QuickRepliesRow(
                            replies: _quickReplies,
                            onTap: (reply) => _send(currentUid, reply,
                                isQuickReply: true),
                          ),
                        _buildInputBar(currentUid, enabled: inputEnabled),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _inputEnabledFor(ChatModel? chat, String currentUid, bool hasMessages) {
    if (chat == null) return true;
    switch (chat.status) {
      case ChatStatus.cancelled:
      case ChatStatus.completed:
        return false;
      case ChatStatus.requested:
        final isProvider = chat.providerId == currentUid;
        if (isProvider) return false;
        return !hasMessages; // Customer's first request message
      case ChatStatus.chatting:
      case ChatStatus.agreed:
      case ChatStatus.contactVisible:
        return true;
    }
  }

  Widget _buildAppBar(
      BuildContext context, ChatModel? chat, String currentUid) {
    final partnerId = chat != null
        ? (chat.userId == currentUid ? chat.providerId : chat.userId)
        : null;

    return AppBar(
      leading: const BackButton(),
      titleSpacing: 0,
      title: partnerId == null
          ? Text(context.tr('app_name'))
          : FutureBuilder<UserModel?>(
              future: _partnerFuture,
              builder: (context, snapshot) {
                final user = snapshot.data;
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: user?.profilePic != null
                          ? NetworkImage(user!.profilePic!)
                          : null,
                      child: user?.profilePic == null
                          ? Text(
                              user?.name.isEmpty ?? true
                                  ? '?'
                                  : user!.name[0].toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user?.name ?? 'Loading...',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (chat?.status == ChatStatus.contactVisible &&
                              user?.phone != null)
                            Text(
                              user!.phone,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.online,
                                  fontWeight: FontWeight.w600),
                            )
                          else if (user != null)
                            Text(
                              user.maskedPhone,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
      actions: [
        if (chat?.status == ChatStatus.contactVisible)
          IconButton(
            icon: const Icon(Icons.call, color: AppColors.online),
            tooltip: context.tr('call_partner'),
            onPressed: () async {
              final user = await _partnerFuture;
              final p = user?.phone;
              if (p != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calling $p...')),
                );
              }
            },
          ),
      ],
    );
  }

  Widget _buildStatusBanner(
      BuildContext context, ChatModel chat, String currentUid) {
    final agreement = chat.agreement;
    final isProvider = chat.providerId == currentUid;

    // ── REQUESTED — waiting for provider acceptance ─────
    if (chat.status == ChatStatus.requested) {
      if (isProvider) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          color: AppColors.accent.withValues(alpha: 0.12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Naya kaam ka request aaya hai',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.accent),
              ),
              const SizedBox(height: 4),
              Text(
                'Accept karein to baat shuru ho jayegi.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptRequest(context),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.online,
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectRequest(context),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.warning.withValues(alpha: 0.12),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Request bhej di gayi. Provider ke accept ka intezaar hai...',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── CANCELLED ───────────────────────────────────────
    if (chat.status == ChatStatus.cancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.danger.withValues(alpha: 0.08),
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.danger),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isProvider
                    ? 'Aapne request reject kar di. Ye chat band ho gayi.'
                    : 'Request close ho gayi.',
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── COMPLETED — both parties rate ───────────────────
    if (chat.status == ChatStatus.completed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        color: AppColors.online.withValues(alpha: 0.12),
        child: FutureBuilder<bool>(
          future: _firestoreService.hasUserRated(widget.chatId, currentUid),
          builder: (context, ratedSnap) {
            final rated = ratedSnap.data ?? false;
            if (rated) {
              return const Row(
                children: [
                  Icon(Icons.verified, color: AppColors.online),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aap ne rating de di. Shukriya!',
                      style: TextStyle(
                        color: AppColors.online,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kaam mukammal ho gaya. Apne partner ko rate karein!',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.online),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => context.push('/rate/${widget.chatId}'),
                  icon: const Icon(Icons.star_rounded, size: 18),
                  label: const Text('Rate Karein'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.online,
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    // ── CONTACT VISIBLE ──────────────────────────────
    if (chat.status == ChatStatus.contactVisible) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: AppColors.online.withValues(alpha: 0.1),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.online),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '✅ Dono tayyar! Contact number reveal ho gaya',
                style: TextStyle(
                  color: AppColors.online,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isProvider)
              ElevatedButton.icon(
                onPressed: () => _completeJob(context),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Complete', style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.online,
                ),
              )
            else
              const Text('REVEALED',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
          ],
        ),
      );
    }

    // ── AGREED (one side) ─────────────────────────────
    if (agreement.userAgreed || agreement.providerAgreed) {
      final isUserInChat = chat.userId == currentUid;
      final myAgreed =
          isUserInChat ? agreement.userAgreed : agreement.providerAgreed;
      final otherAgreed =
          isUserInChat ? agreement.providerAgreed : agreement.userAgreed;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.accent.withValues(alpha: 0.1),
        child: Row(
          children: [
            const Icon(Icons.handshake_outlined, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                myAgreed
                    ? (otherAgreed
                        ? 'Dono tayyar hain!'
                        : 'Aapne agree kiya. Doosre ka intezaar hai...')
                    : 'Doosre ne agree kar diya. Aap bhi agree karein!',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!myAgreed)
              ElevatedButton(
                onPressed: () => _agree(currentUid, chat),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(80, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Agree', style: TextStyle(fontSize: 14)),
              ),
          ],
        ),
      );
    }

    // ── CHATTING — show agree CTA ─────────────────────
    if (chat.status == ChatStatus.chatting) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppColors.surfaceVariant,
        child: Row(
          children: [
            const Icon(Icons.lock_outline,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr('number_hidden'),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => _agree(currentUid, chat),
              child: Text(context.tr('agree')),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildInputBar(String uid, {required bool enabled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: enabled,
              decoration: InputDecoration(
                hintText: enabled ? 'Message likhein...' : 'Chat band hai',
                border: InputBorder.none,
                filled: false,
              ),
              minLines: 1,
              maxLines: 4,
              onSubmitted: (v) {
                if (enabled) _send(uid, v);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
            onPressed: enabled ? () => _send(uid, _textController.text) : null,
          ),
        ],
      ),
    );
  }

  Future<void> _send(String uid, String text,
      {bool isQuickReply = false}) async {
    final msg = text.trim();
    if (msg.isEmpty) return;
    _textController.clear();

    await _firestoreService.sendMessage(
      chatId: widget.chatId,
      senderId: uid,
      message: msg,
      isQuickReply: isQuickReply,
    );
  }

  Future<void> _acceptRequest(BuildContext context) async {
    try {
      await _firestoreService.acceptChat(widget.chatId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request accept ho gayi. Ab baat karein!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Accept nahi ho saka: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Reject Karein?'),
        content: const Text('Kya aap ye request reject karna chahte hain?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Close')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.rejectChat(widget.chatId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request reject kar di gayi.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reject nahi ho saka: $e')),
          );
        }
      }
    }
  }

  Future<void> _agree(String currentUid, ChatModel chat) async {
    try {
      if (chat.userId == currentUid) {
        await _firestoreService.setUserAgreed(widget.chatId);
      } else {
        await _firestoreService.setProviderAgreed(widget.chatId);
      }
    } catch (e) {
      debugPrint('Agree error: $e');
    }
  }

  Future<void> _completeJob(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Job Complete?'),
        content: const Text(
            'Kya aapne kaam khatam kar liya hai? Is se deal officially close ho jayegi.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Nahi')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Haan, Khatam')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.completeJobForChat(widget.chatId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Mubarak! Kaam mukammal. Ab apne partner ko rate karein.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.bubbleSent : AppColors.bubbleReceived,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: isMe ? Colors.white60 : AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.seen ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.seen
                              ? const Color(0xFF90EE90)
                              : Colors.white60,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _QuickRepliesRow extends StatelessWidget {
  final List<String> replies;
  final void Function(String) onTap;

  const _QuickRepliesRow({required this.replies, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ActionChip(
          label: Text(
            replies[i],
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          onPressed: () => onTap(replies[i]),
          backgroundColor: AppColors.surfaceVariant,
          side: const BorderSide(color: AppColors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}