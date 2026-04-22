import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/messaging_track_sharing/models/chat_model.dart';
import 'package:cross_team5/features/messaging_track_sharing/models/message_model.dart';
import 'package:cross_team5/features/messaging_track_sharing/screens/attach_content_sheet.dart';
import 'package:cross_team5/features/messaging_track_sharing/services/messaging_api_service.dart';
import 'package:cross_team5/features/messaging_track_sharing/services/messaging_socket_service.dart';
import 'package:flutter/material.dart';

const _kBg = Color(0xFF111111);
const _kSurface = Color(0xFF1C1C1C);
const _kOrange = Color(0xFFFF5500);

class ChatScreen extends StatefulWidget {
  // For existing conversations (from messages list)
  final String? chatId;

  // For new conversations (from profile / track share)
  final String? receiverId;
  final String receiverName;
  final String receiverPhotoUrl;

  // Pre-filled message (e.g. track link)
  final String? initialContent;

  const ChatScreen({
    super.key,
    this.chatId,
    this.receiverId,
    required this.receiverName,
    this.receiverPhotoUrl = '',
    this.initialContent,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = MessagingApiService();
  final _socket = MessagingSocketService.shared;
  final _auth = AuthApiService();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String? _chatId;
  String? _currentUserId;
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isReceiverBlocked = false;
  bool _isSending = false;
  String? _error;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _chatId = widget.chatId;
    if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
      _inputCtrl.text = widget.initialContent!;
    }
    _init();
  }

  Future<void> _init() async {
    _currentUserId = await _auth.getStoredUserId();
    final token = await _auth.getStoredAccessToken() ?? '';

    if (_chatId != null) {
      await _loadMessages();
      await _api.markChatAsRead(chatId: _chatId!);
      await _socket.connect(token: token);
      _socket.onMessageInRoom = _onIncomingMessage;
      _socket.joinChat(_chatId!);
    } else {
      // New conversation — no messages yet
      if (mounted) setState(() => _isLoading = false);
      await _socket.connect(token: token);
      _socket.onMessageInRoom = _onIncomingMessage;
    }
  }

  Future<void> _loadMessages({bool loadMore = false}) async {
    if (!loadMore) {
      if (mounted) setState(() { _isLoading = true; _error = null; });
    } else {
      if (_loadingMore || !_hasMore) return;
      if (mounted) setState(() => _loadingMore = true);
    }

    try {
      final before =
          loadMore && _messages.isNotEmpty ? _messages.last.id : null;
      final result = await _api.getChatMessages(
        chatId: _chatId!,
        limit: 20,
        before: before,
      );
      if (!mounted) return;
      setState(() {
        if (loadMore) {
          _messages = [..._messages, ...result.messages];
          _hasMore = result.messages.length == 20;
        } else {
          // API returns newest first; reverse for chronological display
          _messages = result.messages.reversed.toList();
          _hasMore = result.messages.length == 20;
        }
        _isReceiverBlocked = result.isReceiverBlocked;
        _isLoading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _loadingMore = false;
      });
    }
  }

  void _onIncomingMessage(ChatModel chat) {
    final lm = chat.lastMessage;
    if (lm == null || _chatId == null) return;
    if (lm.senderId == _currentUserId) return; // own message
    final msg = MessageModel(
      id: lm.id,
      chatId: _chatId!,
      senderId: lm.senderId,
      content: lm.content,
      seenBy: lm.seenBy,
      createdAt: lm.createdAt,
    );
    if (mounted) {
      setState(() {
        // Avoid duplicates
        if (!_messages.any((m) => m.id == msg.id)) {
          _messages = [..._messages, msg];
        }
      });
      _scrollToBottom();
    }
    // Mark as read since we are viewing this chat
    if (_chatId != null) {
      _api.markChatAsRead(chatId: _chatId!).catchError((_) => null);
    }
  }

  Future<void> _send() async {
    final content = _inputCtrl.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _inputCtrl.clear();

    try {
      if (_chatId == null) {
        // First message — use REST API to create conversation
        final chat = await _api.sendMessage(
          receiverId: widget.receiverId!,
          content: content,
        );
        if (!mounted) return;
        final newChatId = chat.id;
        _chatId = newChatId;
        final token = await _auth.getStoredAccessToken() ?? '';
        await _socket.connect(token: token);
        _socket.joinChat(newChatId);
        // Load messages from API to get confirmed data
        await _loadMessages();
      } else {
        // Already in a room — use socket
        _socket.sendMessage(chatId: _chatId!, content: content);
        // Optimistically add message
        final now = DateTime.now();
        final optimistic = MessageModel(
          id: 'opt_${now.millisecondsSinceEpoch}',
          chatId: _chatId!,
          senderId: _currentUserId ?? '',
          content: content,
          seenBy: [_currentUserId ?? ''],
          createdAt: now,
        );
        if (mounted) {
          setState(() => _messages = [..._messages, optimistic]);
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade800,
          ),
        );
        _inputCtrl.text = content;
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _openOptions() async {
    final chatId = _chatId;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _OptionItem(
                icon: Icons.outlined_flag_rounded,
                label: 'Report',
                onTap: () => Navigator.pop(ctx, 'report'),
              ),
              _OptionItem(
                icon: Icons.block_rounded,
                label: 'Block',
                onTap: () => Navigator.pop(ctx, 'block'),
              ),
              if (chatId != null)
                _OptionItem(
                  icon: Icons.delete_outline_rounded,
                  label: 'Archive',
                  onTap: () => Navigator.pop(ctx, 'archive'),
                ),
              if (chatId != null)
                _OptionItem(
                  icon: Icons.mark_email_unread_outlined,
                  label: 'Mark as unread',
                  onTap: () => Navigator.pop(ctx, 'unread'),
                ),
            ],
          ),
        ),
      ),
    );

    if (action == 'archive' && chatId != null) {
      try {
        await _api.archiveChat(chatId: chatId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully archived conversation'),
            backgroundColor: Color(0xFF222222),
          ),
        );
        Navigator.of(context).pop(true); // return true = archived
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } else if (action == 'unread' && chatId != null) {
      try {
        await _api.markChatAsUnread(chatId: chatId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as unread'),
            backgroundColor: Color(0xFF222222),
          ),
        );
      } catch (_) {}
    }
  }

  void _openAttachSheet() {
    if (_currentUserId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachContentSheet(
        currentUserId: _currentUserId!,
        onSelected: (link) {
          _inputCtrl.text = link;
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  void dispose() {
    if (_chatId != null) _socket.leaveChat(_chatId!);
    _socket.onMessageInRoom = null;
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          if (!_isReceiverBlocked) _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final photoUrl = widget.receiverPhotoUrl;
    return AppBar(
      backgroundColor: _kBg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF2A2A2A),
            backgroundImage:
                photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty
                ? Text(
                    _initials(widget.receiverName),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              widget.receiverName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_horiz, color: Colors.white),
          onPressed: _openOptions,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: _kOrange, strokeWidth: 2));
    }

    if (_error != null && _messages.isEmpty) {
      return _buildError();
    }

    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollEndNotification &&
            _scrollCtrl.position.pixels <= 60 &&
            _hasMore &&
            !_loadingMore) {
          _loadMessages(loadMore: true);
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        itemCount: _messages.length + (_loadingMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (_loadingMore && i == 0) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                  child:
                      CircularProgressIndicator(color: _kOrange, strokeWidth: 2)),
            );
          }
          final idx = _loadingMore ? i - 1 : i;
          final msg = _messages[idx];
          final prevMsg = idx > 0 ? _messages[idx - 1] : null;
          final showDate = prevMsg == null ||
              !_sameDay(prevMsg.createdAt, msg.createdAt);
          final isMe = msg.senderId == _currentUserId;
          return Column(
            children: [
              if (showDate) _DateSeparator(date: msg.createdAt),
              _MessageBubble(message: msg, isMe: isMe),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'No messages here yet...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start your messaging history by tapping the\nbutton below',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              _inputCtrl.text = 'Hi';
              _send();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white38),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Say Hi 👋',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.white38, size: 42),
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _loadMessages,
            child: const Text('Try again',
                style: TextStyle(
                    color: _kOrange,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: const Color(0xFF161616),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _openAttachSheet,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white70, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _inputCtrl,
                style:
                    const TextStyle(color: Colors.white, fontSize: 15),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isSending ? null : _send,
            child: AnimatedBuilder(
              animation: _inputCtrl,
              builder: (_, __) {
                final hasText = _inputCtrl.text.trim().isNotEmpty;
                return Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasText ? _kOrange : const Color(0xFF2A2A2A),
                    shape: BoxShape.circle,
                  ),
                  child: _isSending
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  String _initials(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

// ── Date separator ─────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          _formatDate(date),
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return 'Today';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }
}

// ── Message bubble ──────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(message.createdAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isMe
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                  color: Colors.white, fontSize: 15, height: 1.35),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            time,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour;
    final m = local.minute.toString().padLeft(2, '0');
    final amPm = h >= 12 ? 'PM' : 'AM';
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$hour:$m $amPm';
  }
}

// ── Option item ─────────────────────────────────────────────────────────────────

class _OptionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 15)),
      onTap: onTap,
    );
  }
}
