import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/followers_social_graph/services/social_api_service.dart';
import 'package:cross_team5/features/messaging_track_sharing/models/chat_model.dart';
import 'package:cross_team5/features/messaging_track_sharing/models/message_model.dart';
import 'package:cross_team5/features/messaging_track_sharing/screens/attach_content_sheet.dart';
import 'package:cross_team5/features/messaging_track_sharing/services/messaging_api_service.dart';
import 'package:cross_team5/features/messaging_track_sharing/services/messaging_socket_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
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
  final _social = SocialApiService();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String? _chatId;
  String? _currentUserId;
  String? _receiverId;
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
    _receiverId = widget.receiverId;
    if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
      _inputCtrl.text = widget.initialContent!;
    }
    _init();
  }

  Future<void> _init() async {
    _currentUserId = await _auth.getStoredUserId();
    final token = await _auth.getStoredAccessToken() ?? '';

    // Issue 5 fix: if opened with only receiverId (e.g. from profile), look for an existing chat first
    if (_chatId == null &&
        widget.receiverId != null &&
        widget.receiverId!.isNotEmpty) {
      try {
        debugPrint('[ChatScreen._init] No chatId. Searching for existing chat with receiverId=${widget.receiverId}');
        final chats = await _api.getChats(limit: 50);
        debugPrint('[ChatScreen._init] Fetched ${chats.length} chats to search');
        for (final c in chats) {
          debugPrint('[ChatScreen._init] → chat ${c.id}: receiver.userId="${c.receiver?.userId}" sender.userId="${c.sender?.userId}"');
        }
        ChatModel? found;
        try {
          found = chats.firstWhere(
            (c) =>
                (c.receiver?.userId.isNotEmpty == true &&
                    c.receiver?.userId == widget.receiverId) ||
                (c.sender?.userId.isNotEmpty == true &&
                    c.sender?.userId == widget.receiverId),
          );
        } catch (_) {}
        if (found != null) {
          debugPrint('[ChatScreen._init] Found existing chat: ${found.id}');
          _chatId = found.id;
        } else {
          debugPrint('[ChatScreen._init] No existing chat found → new conversation');
        }
      } catch (e) {
        debugPrint('[ChatScreen._init] Error searching for existing chat: $e');
      }
    }

    if (_chatId != null) {
      await _loadMessages();
      debugPrint('[ChatScreen._init] Calling markChatAsRead for chatId=$_chatId');
      _api.markChatAsRead(chatId: _chatId!).then((_) {
        debugPrint('[ChatScreen._init] markChatAsRead SUCCESS for $_chatId');
      }).catchError((e) {
        debugPrint('[ChatScreen._init] markChatAsRead FAILED: $e');
      });
      await _socket.connect(token: token);
      _socket.onMessageInRoom = _onIncomingMessage;
      _socket.joinChat(_chatId!);
    } else {
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
      // For load-more, fetch older messages before the oldest we have
      final before =
          loadMore && _messages.isNotEmpty ? _messages.first.id : null;
      final result = await _api.getChatMessages(
        chatId: _chatId!,
        limit: 20,
        before: before,
      );
      if (!mounted) return;

      // Issues 4 & 5: extract receiverId from message senderIds.
      // Any senderId that isn't the current user IS the receiver.
      final allMsgs = loadMore
          ? [...result.messages.reversed, ..._messages]
          : result.messages.reversed.toList();
      if (_receiverId == null || _receiverId!.isEmpty) {
        for (final msg in allMsgs) {
          if (msg.senderId.isNotEmpty && msg.senderId != _currentUserId) {
            _receiverId = msg.senderId;
            debugPrint('[ChatScreen._loadMessages] Extracted receiverId from messages: $_receiverId');
            break;
          }
        }
        if (_receiverId == null || _receiverId!.isEmpty) {
          debugPrint('[ChatScreen._loadMessages] Could not extract receiverId — all ${allMsgs.length} messages are from currentUser or list is empty');
        }
      }

      setState(() {
        if (loadMore) {
          _messages = [...result.messages.reversed, ..._messages];
          _hasMore = result.messages.length == 20;
        } else {
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
    debugPrint('[ChatScreen._onIncomingMessage] event. chatId=${chat.id}, content="${lm?.content}", senderId=${lm?.senderId}, _currentUserId=$_currentUserId, _chatId=$_chatId');
    if (lm == null || _chatId == null) {
      debugPrint('[ChatScreen._onIncomingMessage] Skipped: lm=${lm == null ? "null" : "ok"}, _chatId=${_chatId ?? "null"}');
      return;
    }
    if (lm.senderId == _currentUserId) {
      debugPrint('[ChatScreen._onIncomingMessage] Skipped: own message echo');
      return;
    }
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
        if (!_messages.any((m) => m.id == msg.id)) {
          _messages = [..._messages, msg];
        }
      });
      _scrollToBottom();
    }
    // Issue 1: mark as read because user is actively viewing this chat
    debugPrint('[ChatScreen._onIncomingMessage] Calling markChatAsRead for $_chatId');
    _api.markChatAsRead(chatId: _chatId!).then((_) {
      debugPrint('[ChatScreen._onIncomingMessage] markChatAsRead SUCCESS');
    }).catchError((e) {
      debugPrint('[ChatScreen._onIncomingMessage] markChatAsRead FAILED: $e');
    });
  }

  Future<void> _send() async {
    final content = _inputCtrl.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _inputCtrl.clear();

    try {
      if (_chatId == null) {
        final chat = await _api.sendMessage(
          receiverId: widget.receiverId!,
          content: content,
        );
        if (!mounted) return;
        final newChatId = chat.id;
        _chatId = newChatId;
        // Store receiverId if not already set
        if (_receiverId == null || _receiverId!.isEmpty) {
          _receiverId = chat.receiver?.userId ?? chat.sender?.userId;
        }
        final token = await _auth.getStoredAccessToken() ?? '';
        await _socket.connect(token: token);
        _socket.joinChat(newChatId);
        await _loadMessages();
      } else {
        _socket.sendMessage(chatId: _chatId!, content: content);
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


    /// Closes the chat and signals to the parent that a refresh is needed
  void _closeChat() {
    Navigator.of(context).pop(true); // Return true to trigger MessagesTab refresh
  }




  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients && _scrollCtrl.position.pixels != 0) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _openOptions() async {
    debugPrint('[ChatScreen._openOptions] _isReceiverBlocked=$_isReceiverBlocked, _receiverId=$_receiverId');
    final chatId = _chatId;
    final isBlocked = _isReceiverBlocked;
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
                icon: isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                label: isBlocked ? 'Unblock' : 'Block',
                onTap: () => Navigator.pop(ctx, isBlocked ? 'unblock' : 'block'),
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

    if (action == 'block') {
      await _block();
    } else if (action == 'unblock') {
      await _unblock();
    } else if (action == 'archive' && chatId != null) {
      try {
        await _api.archiveChat(chatId: chatId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully archived conversation'),
            backgroundColor: Color(0xFF222222),
          ),
        );
        Navigator.of(context).pop(true);
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
          const SnackBar(content: Text('Marked as unread'), backgroundColor: Color(0xFF222222)),
        );
      } catch (_) {}
    }
  }

  Future<void> _block() async {
    final rid = _receiverId;
    debugPrint('[ChatScreen._block] Attempting block. receiverId=$rid, current _isReceiverBlocked=$_isReceiverBlocked');
    if (rid == null || rid.isEmpty) {
      debugPrint('[ChatScreen._block] SKIPPED: receiverId is null or empty');
      return;
    }
    try {
      final result = await _social.blockUser(targetUserId: rid);
      debugPrint('[ChatScreen._block] API result: status=${result.$1}, body=${result.$2}');
      if (result.$1 >= 200 && result.$1 < 300) {
        if (mounted) setState(() => _isReceiverBlocked = true);
        debugPrint('[ChatScreen._block] Block successful → _isReceiverBlocked=true');
      } else {
        debugPrint('[ChatScreen._block] Block returned non-2xx: ${result.$1}');
      }
    } catch (e) {
      debugPrint('[ChatScreen._block] Exception: $e');
    }
  }

  Future<void> _unblock() async {
    final rid = _receiverId;
    debugPrint('[ChatScreen._unblock] Attempting unblock. receiverId=$rid');
    if (rid == null || rid.isEmpty) {
      debugPrint('[ChatScreen._unblock] SKIPPED: receiverId is null or empty');
      return;
    }
    try {
      final result = await _social.unblockUser(targetUserId: rid);
      debugPrint('[ChatScreen._unblock] API result: status=${result.$1}, body=${result.$2}');
      if (result.$1 >= 200 && result.$1 < 300) {
        if (mounted) setState(() => _isReceiverBlocked = false);
        debugPrint('[ChatScreen._unblock] Unblock successful → _isReceiverBlocked=false');
      } else {
        debugPrint('[ChatScreen._unblock] Unblock returned non-2xx: ${result.$1}');
      }
    } catch (e) {
      debugPrint('[ChatScreen._unblock] Exception: $e');
    }
  }

  void _openAttachSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachContentSheet(
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
    return WillPopScope(
      // ✅ Intercept hardware back button to ensure we always return true
      onWillPop: () async {
        _closeChat();
        return false; // We already handled the pop, so prevent default behavior
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(child: _buildBody()),
            if (_isReceiverBlocked)
              _buildBlockBanner()
            else
              _buildInputBar(),
          ],
        ),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: _closeChat, // ✅ Use the new method instead of direct pop
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
        if (n is ScrollUpdateNotification &&
            _scrollCtrl.hasClients &&
            _scrollCtrl.position.maxScrollExtent - _scrollCtrl.position.pixels <= 100 &&
            _hasMore &&
            !_loadingMore) {
          _loadMessages(loadMore: true);
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollCtrl,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        itemCount: _messages.length + (_loadingMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          // With reverse:true: i=0 = newest (bottom), i=N-1 = oldest (top)
          // Spinner appears at top (oldest end) when loading more
          if (_loadingMore && i == _messages.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                  child: CircularProgressIndicator(
                      color: _kOrange, strokeWidth: 2)),
            );
          }
          final msg = _messages[_messages.length - 1 - i];
          final isMe = msg.senderId == _currentUserId;

          // Show date separator above the oldest message of each day.
          // In reversed list, "older" = higher index = earlier in _messages.
          final olderIdx = _messages.length - 2 - i;
          final olderMsg = olderIdx >= 0 ? _messages[olderIdx] : null;
          final showDate = olderMsg == null ||
              !_sameDay(olderMsg.createdAt, msg.createdAt);

          return Column(
            mainAxisSize: MainAxisSize.min,
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

  Widget _buildBlockBanner() {
    return Container(
      color: const Color(0xFF161616),
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Expanded(
              child: Text(
                "You've blocked this account and can't send messages to them.",
                style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
              ),
            ),
            TextButton(
              onPressed: _unblock,
              child: const Text('Unblock',
                  style: TextStyle(
                      color: _kOrange,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
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
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A2A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white70, size: 22),
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
                style: const TextStyle(color: Colors.white, fontSize: 15),
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
              builder: (context, _) {
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

  static bool _looksLikePermalink(String content) {
    final c = content.trim();
    return c.length > 8 &&
        c.length < 200 &&
        !c.contains(' ') &&
        RegExp(r'^[a-zA-Z0-9\-_./%]+$').hasMatch(c);
  }

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.72;
    final time = _formatTime(message.createdAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (_looksLikePermalink(message.content))
              _TrackCardBubble(permalink: message.content.trim(), isMe: isMe)
            else
              _buildTextBubble(maxBubbleWidth),
            const SizedBox(height: 3),
            Text(
              time,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextBubble(double maxWidth) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isMe ? _kOrange : const Color(0xFF2A2A2A),
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

// ── Track card bubble (shared track message) ────────────────────────────────────

class _TrackCardBubble extends StatefulWidget {
  final String permalink;
  final bool isMe;

  const _TrackCardBubble({required this.permalink, required this.isMe});

  // Static cache so we don't re-fetch on ListView rebuilds
  static final Map<String, PlaybackTrackModel?> _cache = {};

  @override
  State<_TrackCardBubble> createState() => _TrackCardBubbleState();
}

class _TrackCardBubbleState extends State<_TrackCardBubble> {
  PlaybackTrackModel? _track;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (_TrackCardBubble._cache.containsKey(widget.permalink)) {
      _track = _TrackCardBubble._cache[widget.permalink];
      _loaded = true;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final result = await MessagingApiService()
        .getTrackByPermalink(permalink: widget.permalink);
    _TrackCardBubble._cache[widget.permalink] = result;
    if (mounted) setState(() { _track = result; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      // Show shimmer-like placeholder while fetching
      return _buildPlaceholder();
    }
    if (_track == null) {
      // Couldn't load — render as plain text bubble
      return Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: widget.isMe ? _kOrange : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
            bottomRight: Radius.circular(widget.isMe ? 4 : 18),
          ),
        ),
        child: Text(widget.permalink,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, height: 1.35)),
      );
    }

    final track = _track!;
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Artwork banner
          if (track.artworkUrl != null && track.artworkUrl!.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.network(
                track.artworkUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, _) => const SizedBox(height: 0),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.play_circle_filled_rounded,
                    color: _kOrange, size: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 260,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
          child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: _kOrange, strokeWidth: 2))),
    );
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
