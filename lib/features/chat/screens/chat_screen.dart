import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/models/message_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../providers/auth_provider.dart';
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

  static const _quickReplies = [
    'Kaam hai',
    'Kitna charge?',
    'Kab aoge?',
    'Theek hai',
    'Nahi chahiye',
  ];

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
              // AppBar with contact info
              _buildAppBar(context, chat, currentUid),

              // Agreement / contact reveal banner
              if (chat != null) _buildStatusBanner(context, chat, currentUid),

              // Messages
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _firestoreService.streamMessages(widget.chatId),
                  builder: (context, msgSnap) {
                    final messages = msgSnap.data ?? [];

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, i) => _MessageBubble(
                        message: messages[i],
                        isMe: messages[i].senderId == currentUid,
                      ),
                    );
                  },
                ),
              ),

              // Quick replies row
              _QuickRepliesRow(
                replies: _quickReplies,
                onTap: (reply) => _send(currentUid, reply, isQuickReply: true),
              ),

              // Input bar
              _buildInputBar(currentUid),

              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ChatModel? chat, String currentUid) {
    return AppBar(
      leading: const BackButton(),
      title: const Text('Chat'), 
      actions: [
        if (chat?.status == ChatStatus.contactVisible)
          IconButton(
            icon: const Icon(Icons.phone, color: AppColors.online),
            tooltip: 'Contact visible',
            onPressed: () {
              // Launch phone dialer logic
            },
          ),
      ],
    );
  }

  Widget _buildStatusBanner(BuildContext context, ChatModel chat, String currentUid) {
    final agreement = chat.agreement;

    // ── CONTACT VISIBLE ──────────────────────────────
    if (chat.status == ChatStatus.contactVisible) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: AppColors.online.withOpacity(0.1),
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
            const Text('REVEALED', 
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
          ],
        ),
      );
    }

    // ── AGREED (one side) ─────────────────────────────
    if (agreement.userAgreed || agreement.providerAgreed) {
      final isUserInChat = chat.userId == currentUid;
      final myAgreed = isUserInChat ? agreement.userAgreed : agreement.providerAgreed;
      final otherAgreed = isUserInChat ? agreement.providerAgreed : agreement.userAgreed;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.accent.withOpacity(0.1),
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
    if (chat.status == ChatStatus.chatting || chat.status == ChatStatus.requested) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppColors.surfaceVariant,
        child: Row(
          children: [
            const Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Number chupaaya hua hai. Agree karein to dikhega.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => _agree(currentUid, chat),
              child: const Text('Agree'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildInputBar(String uid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Message likhein...',
                border: InputBorder.none,
                filled: false,
              ),
              minLines: 1,
              maxLines: 4,
              onSubmitted: (v) => _send(uid, v),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
            onPressed: () => _send(uid, _textController.text),
          ),
        ],
      ),
    );
  }

  Future<void> _send(String uid, String text, {bool isQuickReply = false}) async {
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

  Future<void> _agree(String currentUid, ChatModel chat) async {
    final isUser = chat.userId == currentUid;
    if (isUser) {
      await _firestoreService.setUserAgreed(widget.chatId);
    } else {
      await _firestoreService.setProviderAgreed(widget.chatId);
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
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                          color: message.seen ? const Color(0xFF90EE90) : Colors.white60,
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
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}
