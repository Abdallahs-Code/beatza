import 'package:cross_team5/features/activity/screens/track_options_sheet.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/messaging_track_sharing/services/messaging_notification_service.dart';
import 'package:cross_team5/features/followers_social_graph/services/social_api_service.dart';
import 'package:cross_team5/features/messaging_track_sharing/models/chat_model.dart';
import 'package:cross_team5/features/messaging_track_sharing/models/message_model.dart';
import 'package:cross_team5/features/messaging_track_sharing/screens/attach_content_sheet.dart';
import 'package:cross_team5/features/messaging_track_sharing/services/messaging_api_service.dart';
import 'package:cross_team5/features/messaging_track_sharing/services/messaging_socket_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';
import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

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
  bool _isBlockedByReceiver = false;
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
    if (widget.chatId != null) {
      MessagingNotificationService.shared.setActiveChatId(widget.chatId);
    }
    _init();
  }

  Future<void> _init() async {
    _currentUserId = await _auth.getStoredUserId();
    final token = await _auth.getStoredAccessToken() ?? '';

    // If opened with only receiverId (e.g. from profile), find or create the chat via API
    if (_chatId == null &&
        widget.receiverId != null &&
        widget.receiverId!.isNotEmpty) {
      try {
        debugPrint(
          '[ChatScreen._init] No chatId. Calling findOrCreateChat for receiverId=${widget.receiverId}',
        );
        final foundId = await _api.findOrCreateChat(
          receiverId: widget.receiverId!,
        );
        if (foundId != null && foundId.isNotEmpty) {
          debugPrint(
            '[ChatScreen._init] findOrCreateChat returned chatId=$foundId',
          );
          _chatId = foundId;
          MessagingNotificationService.shared.setActiveChatId(foundId);
        } else {
          debugPrint(
            '[ChatScreen._init] findOrCreateChat returned null → new conversation',
          );
        }
      } catch (e) {
        debugPrint(
          '[ChatScreen._init] findOrCreateChat error: $e → falling back to new conversation',
        );
      }
    }

    debugPrint(
      '[ChatScreen._init] _chatId=$_chatId  _receiverId=$_receiverId  _currentUserId=$_currentUserId',
    );
    if (_chatId != null) {
      debugPrint('[ChatScreen._init] Has chatId → calling _loadMessages');
      await _loadMessages();
      debugPrint(
        '[ChatScreen._init] After _loadMessages → _isReceiverBlocked=$_isReceiverBlocked  _isBlockedByReceiver=$_isBlockedByReceiver',
      );
      debugPrint(
        '[ChatScreen._init] Calling markChatAsRead for chatId=$_chatId',
      );
      _api
          .markChatAsRead(chatId: _chatId!)
          .then((_) {
            debugPrint(
              '[ChatScreen._init] markChatAsRead SUCCESS for $_chatId',
            );
          })
          .catchError((e) {
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
    // Check blockingMe from public profile — covers the case where the receiver
    // has blocked us but the messages API hasn't reflected it yet.
    await _checkReceiverBlockingMe();
  }

  Future<void> _checkReceiverBlockingMe() async {
    final rid = _receiverId;
    debugPrint('━━━ [ChatScreen._checkReceiverBlockingMe] ━━━');
    debugPrint(
      '[ChatScreen._checkReceiverBlockingMe] receiverId="$rid" (null=${rid == null})',
    );
    if (rid == null || rid.isEmpty) {
      debugPrint(
        '[ChatScreen._checkReceiverBlockingMe] ⚠️ receiverId unknown — skipping blockingMe check',
      );
      return;
    }
    try {
      final blockingMe = await _api.getPublicProfileBlockingMe(userId: rid);
      debugPrint(
        '[ChatScreen._checkReceiverBlockingMe] blockingMe=$blockingMe  current _isBlockedByReceiver=$_isBlockedByReceiver',
      );
      if (blockingMe && mounted && !_isBlockedByReceiver) {
        debugPrint(
          '[ChatScreen._checkReceiverBlockingMe] → receiver is blocking us — setting _isBlockedByReceiver=true',
        );
        setState(() => _isBlockedByReceiver = true);
      }
    } catch (e) {
      debugPrint('[ChatScreen._checkReceiverBlockingMe] ❌ EXCEPTION: $e');
    }
  }

  Future<void> _loadMessages({bool loadMore = false}) async {
    if (!loadMore) {
      if (mounted)
        setState(() {
          _isLoading = true;
          _error = null;
        });
    } else {
      if (_loadingMore || !_hasMore) return;
      if (mounted) setState(() => _loadingMore = true);
    }

    try {
      debugPrint('━━━ [ChatScreen._loadMessages] ━━━');
      debugPrint(
        '[ChatScreen._loadMessages] _chatId="$_chatId" (empty=${_chatId?.isEmpty}) loadMore=$loadMore',
      );
      // For load-more, fetch older messages before the oldest we have
      final before = loadMore && _messages.isNotEmpty
          ? _messages.first.id
          : null;
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
            debugPrint(
              '[ChatScreen._loadMessages] Extracted receiverId from messages: $_receiverId',
            );
            break;
          }
        }
        if (_receiverId == null || _receiverId!.isEmpty) {
          debugPrint(
            '[ChatScreen._loadMessages] Could not extract receiverId — all ${allMsgs.length} messages are from currentUser or list is empty',
          );
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
        _isBlockedByReceiver = result.isBlockedByReceiver;
        debugPrint(
          '[ChatScreen._loadMessages] BLOCK STATE → isReceiverBlocked=$_isReceiverBlocked  isBlockedByReceiver=$_isBlockedByReceiver',
        );
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
    debugPrint(
      '[ChatScreen._onIncomingMessage] event. chatId=${chat.id}, content="${lm?.content}", senderId=${lm?.senderId}, _currentUserId=$_currentUserId, _chatId=$_chatId',
    );
    if (lm == null || _chatId == null) {
      debugPrint(
        '[ChatScreen._onIncomingMessage] Skipped: lm=${lm == null ? "null" : "ok"}, _chatId=${_chatId ?? "null"}',
      );
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
    debugPrint(
      '[ChatScreen._onIncomingMessage] Calling markChatAsRead for $_chatId',
    );
    _api
        .markChatAsRead(chatId: _chatId!)
        .then((_) {
          debugPrint('[ChatScreen._onIncomingMessage] markChatAsRead SUCCESS');
        })
        .catchError((e) {
          debugPrint(
            '[ChatScreen._onIncomingMessage] markChatAsRead FAILED: $e',
          );
        });
  }

  Future<void> _send() async {
    final content = _inputCtrl.text.trim();
    debugPrint('━━━ [ChatScreen._send] ━━━');
    debugPrint(
      '[ChatScreen._send] content="$content" (empty=${content.isEmpty}) isSending=$_isSending chatId="$_chatId"',
    );
    if (content.isEmpty || _isSending) {
      debugPrint(
        '[ChatScreen._send] EARLY EXIT: empty=${content.isEmpty} isSending=$_isSending',
      );
      return;
    }

    setState(() => _isSending = true);
    _inputCtrl.clear();

    try {
      if (_chatId == null) {
        debugPrint(
          '[ChatScreen._send] No chatId → sending via HTTP (new chat) receiverId=${widget.receiverId}',
        );
        final chat = await _api.sendMessage(
          receiverId: widget.receiverId!,
          content: content,
        );
        if (!mounted) return;
        final newChatId = chat.id;
        _chatId = newChatId;
        debugPrint('[ChatScreen._send] New chat created. chatId=$newChatId');
        // Store receiverId if not already set
        if (_receiverId == null || _receiverId!.isEmpty) {
          _receiverId = chat.receiver?.userId ?? chat.sender?.userId;
        }
        final token = await _auth.getStoredAccessToken() ?? '';
        await _socket.connect(token: token);
        _socket.joinChat(newChatId);
        await _loadMessages();
      } else {
        debugPrint(
          '[ChatScreen._send] Existing chat=$_chatId → sending via socket. isTrack=${_MessageBubble._isTrackMessage(content)}',
        );
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
        debugPrint(
          '[ChatScreen._send] Optimistic message added. id=${optimistic.id} content="${optimistic.content}"',
        );
        if (mounted) {
          setState(() => _messages = [..._messages, optimistic]);
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('[ChatScreen._send] ERROR: $e');
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      final isBlockError =
          msg.contains('block') ||
          msg.contains('forbidden') ||
          msg.contains('cannot send') ||
          msg.contains('disabled');
      debugPrint('[ChatScreen._send] isBlockError=$isBlockError  raw="$e"');
      if (isBlockError) {
        setState(() => _isBlockedByReceiver = true);
        debugPrint(
          '[ChatScreen._send] → set _isBlockedByReceiver=true, showing banner',
        );
      } else {
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
    Navigator.of(
      context,
    ).pop(true); // Return true to trigger MessagesTab refresh
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
    debugPrint(
      '[ChatScreen._openOptions] _isReceiverBlocked=$_isReceiverBlocked, _receiverId=$_receiverId',
    );
    final chatId = _chatId;
    final isBlocked = _isReceiverBlocked;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.container,
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
                onTap: () =>
                    Navigator.pop(ctx, isBlocked ? 'unblock' : 'block'),
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
          SnackBar(
            content: Text('Successfully archived conversation'),
            backgroundColor: AppColors.cardDark2,
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
          SnackBar(
            content: Text('Marked as unread'),
            backgroundColor: AppColors.cardDark2,
          ),
        );
      } catch (_) {}
    }
  }

  Future<void> _block() async {
    final rid = _receiverId;
    debugPrint(
      '[ChatScreen._block] Attempting block. receiverId=$rid, current _isReceiverBlocked=$_isReceiverBlocked',
    );
    if (rid == null || rid.isEmpty) {
      debugPrint('[ChatScreen._block] SKIPPED: receiverId is null or empty');
      return;
    }
    try {
      final result = await _social.blockUser(targetUserId: rid);
      debugPrint(
        '[ChatScreen._block] API result: status=${result.$1}, body=${result.$2}',
      );
      if (result.$1 >= 200 && result.$1 < 300) {
        if (mounted) setState(() => _isReceiverBlocked = true);
        debugPrint(
          '[ChatScreen._block] Block successful → _isReceiverBlocked=true',
        );
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
      debugPrint(
        '[ChatScreen._unblock] API result: status=${result.$1}, body=${result.$2}',
      );
      if (result.$1 >= 200 && result.$1 < 300) {
        if (mounted) setState(() => _isReceiverBlocked = false);
        debugPrint(
          '[ChatScreen._unblock] Unblock successful → _isReceiverBlocked=false',
        );
      } else {
        debugPrint(
          '[ChatScreen._unblock] Unblock returned non-2xx: ${result.$1}',
        );
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
          debugPrint(
            '[AttachSheet] onSelected link="$link" length=${link.length}',
          );
          debugPrint(
            '[AttachSheet] _isTrackMessage=${_MessageBubble._isTrackMessage(link)}',
          );
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
    MessagingNotificationService.shared.setActiveChatId(null);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeChat();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(child: _buildBody()),
            Builder(
              builder: (ctx) {
                debugPrint(
                  '[ChatScreen.build] isReceiverBlocked=$_isReceiverBlocked  isBlockedByReceiver=$_isBlockedByReceiver  isLoading=$_isLoading  chatId=$_chatId',
                );
                if (_isReceiverBlocked) return _buildBlockBanner();
                if (_isBlockedByReceiver)
                  return _buildBlockedByReceiverBanner();
                return _buildInputBar();
              },
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final photoUrl = widget.receiverPhotoUrl;
    return AppBar(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: _closeChat, // ✅ Use the new method instead of direct pop
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.containerMid,
            backgroundImage: photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl.isEmpty
                ? Text(
                    _initials(widget.receiverName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
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
        child: CircularProgressIndicator(
          color: AppColors.primaryOrange,
          strokeWidth: 2,
        ),
      );
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
            _scrollCtrl.position.maxScrollExtent -
                    _scrollCtrl.position.pixels <=
                100 &&
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
                  color: AppColors.primaryOrange,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          final msg = _messages[_messages.length - 1 - i];
          final isMe = msg.senderId == _currentUserId;

          // Show date separator above the oldest message of each day.
          // In reversed list, "older" = higher index = earlier in _messages.
          final olderIdx = _messages.length - 2 - i;
          final olderMsg = olderIdx >= 0 ? _messages[olderIdx] : null;
          final showDate =
              olderMsg == null || !_sameDay(olderMsg.createdAt, msg.createdAt);

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
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Say Hi 👋',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
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
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white38,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _loadMessages,
            child: const Text(
              'Try again',
              style: TextStyle(
                color: AppColors.primaryOrange,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            TextButton(
              onPressed: _unblock,
              child: const Text(
                'Unblock',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedByReceiverBanner() {
    return Container(
      color: const Color(0xFF161616),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 14,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block_rounded, color: Colors.white38, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'This profile has disabled receiving messages.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
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
              decoration: BoxDecoration(
                color: AppColors.containerMid,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white70,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
                    color: hasText
                        ? AppColors.primaryOrange
                        : AppColors.containerMid,
                    shape: BoxShape.circle,
                  ),
                  child: _isSending
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }
}

// ── Message bubble ──────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  static bool _isTrackMessage(String content) =>
      content.trim().startsWith('track::');

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
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (ctx) {
                final isTrack = _isTrackMessage(message.content);
                debugPrint(
                  '[MessageBubble.build] id="${message.id}" isTrack=$isTrack content="${message.content.length > 60 ? "${message.content.substring(0, 60)}..." : message.content}"',
                );
                if (isTrack) {
                  final raw = message.content.trim().substring(
                    'track::'.length,
                  );
                  // Current format:  permalink:"<pl>",profilelink:"<profileLink>"
                  // Legacy format A: <artistId>::<permalink>
                  // Legacy format B: <permalink>  (no "::")
                  String parsedPermalink = '';
                  String parsedProfileLink = '';

                  if (raw.contains('permalink:"')) {
                    // Current format — parse both fields via regex
                    final plMatch = RegExp(
                      r'permalink:"([^"]*)"',
                    ).firstMatch(raw);
                    final profMatch = RegExp(
                      r'profilelink:"([^"]*)"',
                    ).firstMatch(raw);
                    parsedPermalink = plMatch?.group(1) ?? '';
                    parsedProfileLink = profMatch?.group(1) ?? '';
                    debugPrint(
                      '[MessageBubble.build] Current format → permalink="$parsedPermalink" profilelink="$parsedProfileLink"',
                    );
                  } else {
                    // Legacy format — no profilelink embedded
                    final sepIdx = raw.indexOf('::');
                    parsedPermalink = sepIdx >= 0
                        ? raw.substring(sepIdx + 2)
                        : raw;
                    debugPrint(
                      '[MessageBubble.build] Legacy format (raw="$raw") → permalink="$parsedPermalink" (no profilelink — will fall back to current user)',
                    );
                  }

                  debugPrint(
                    '[MessageBubble.build] → TrackCardBubble permalink="$parsedPermalink" profilelink="$parsedProfileLink"',
                  );
                  return _TrackCardBubble(
                    key: ValueKey(message.content),
                    permalink: parsedPermalink,
                    profileLink: parsedProfileLink,
                    isMe: isMe,
                  );
                }
                return _buildTextBubble(maxBubbleWidth);
              },
            ),
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
        color: isMe ? AppColors.primaryOrange : AppColors.containerMid,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
      ),
      child: Text(
        message.content,
        style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.35),
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
  final String
  profileLink; // track owner's profileLink (empty on legacy messages)
  final String permalink;
  final bool isMe;

  const _TrackCardBubble({
    super.key,
    required this.profileLink,
    required this.permalink,
    required this.isMe,
  });

  static final Map<String, PlaybackTrackModel?> _cache = {};

  @override
  State<_TrackCardBubble> createState() => _TrackCardBubbleState();
}

class _TrackCardBubbleState extends State<_TrackCardBubble> {
  PlaybackTrackModel? _track;
  bool _loaded = false;

  String get _cacheKey => '${widget.profileLink}::${widget.permalink}';

  @override
  void initState() {
    super.initState();
    debugPrint('━━━ [TrackCardBubble.initState] ━━━');
    debugPrint(
      '[TrackCardBubble.initState] profileLink="${widget.profileLink}" permalink="${widget.permalink}" cacheKey="$_cacheKey"',
    );
    if (_TrackCardBubble._cache.containsKey(_cacheKey)) {
      _track = _TrackCardBubble._cache[_cacheKey];
      _loaded = true;
      debugPrint(
        '[TrackCardBubble.initState] Cache HIT → track=${_track == null ? "null (fallback text)" : "\"${_track!.title}\""}',
      );
    } else {
      debugPrint('[TrackCardBubble.initState] Cache MISS → calling _load()');
      _load();
    }
  }

  @override
  void didUpdateWidget(_TrackCardBubble old) {
    super.didUpdateWidget(old);
    final oldKey = '${old.profileLink}::${old.permalink}';
    if (oldKey != _cacheKey) {
      debugPrint(
        '[TrackCardBubble.didUpdateWidget] cacheKey changed: "$oldKey" → "$_cacheKey"',
      );
      if (_TrackCardBubble._cache.containsKey(_cacheKey)) {
        setState(() {
          _track = _TrackCardBubble._cache[_cacheKey];
          _loaded = true;
        });
      } else {
        setState(() {
          _track = null;
          _loaded = false;
        });
        _load();
      }
    }
  }

  Future<void> _load() async {
    debugPrint('━━━ [TrackCardBubble._load] ━━━');
    debugPrint(
      '[TrackCardBubble._load] profileLink="${widget.profileLink}" permalink="${widget.permalink}" cacheKey="$_cacheKey"',
    );
    try {
      final api = MessagingApiService();

      // Step 1 — resolve profileLink.
      // Current format: profileLink is embedded directly in the message payload.
      // Legacy format:  profileLink is empty — fall back to current user's profileLink
      //                 (best-effort, will 404 if they don't own the track).
      String resolvedProfileLink = widget.profileLink;

      if (resolvedProfileLink.isEmpty) {
        debugPrint(
          '[TrackCardBubble._load] profileLink empty (legacy message) — fetching current user profileLink as fallback',
        );
        final auth = AuthApiService();
        final userId = await auth.getStoredUserId() ?? '';
        debugPrint(
          '[TrackCardBubble._load] Fallback userId="$userId" (empty=${userId.isEmpty})',
        );
        if (userId.isEmpty) {
          debugPrint(
            '[TrackCardBubble._load] ❌ userId also empty — cannot resolve profileLink',
          );
          _TrackCardBubble._cache[_cacheKey] = null;
          if (mounted)
            setState(() {
              _track = null;
              _loaded = true;
            });
          return;
        }
        resolvedProfileLink =
            await api.getUserProfileLink(userId: userId) ?? '';
        debugPrint(
          '[TrackCardBubble._load] Fallback profileLink="$resolvedProfileLink" (empty=${resolvedProfileLink.isEmpty})',
        );
      }

      if (resolvedProfileLink.isEmpty) {
        debugPrint(
          '[TrackCardBubble._load] ❌ resolvedProfileLink is still empty — cannot call permalink API',
        );
        _TrackCardBubble._cache[_cacheKey] = null;
        if (mounted)
          setState(() {
            _track = null;
            _loaded = true;
          });
        return;
      }

      // Step 2 — call GET /api/public/tracks/v1/permalink/{profileLink}/{permalink}
      debugPrint(
        '[TrackCardBubble._load] calling getTrackByPermalink(profileLink="$resolvedProfileLink", permalink="${widget.permalink}")',
      );
      final result = await api.getTrackByPermalink(
        profileLink: resolvedProfileLink,
        permalink: widget.permalink,
      );
      debugPrint(
        '[TrackCardBubble._load] result=${result == null ? "NULL — showing fallback text" : "✅ id=${result.id} title=${result.title}"}',
      );
      _TrackCardBubble._cache[_cacheKey] = result;
      if (mounted)
        setState(() {
          _track = result;
          _loaded = true;
        });
    } catch (e, stack) {
      debugPrint('[TrackCardBubble._load] ❌ EXCEPTION: $e');
      debugPrint('[TrackCardBubble._load] stack: $stack');
      _TrackCardBubble._cache[_cacheKey] = null;
      if (mounted)
        setState(() {
          _track = null;
          _loaded = true;
        });
    }
  }

  void _play() {
    final track = _track;
    if (track == null) return;
    PlaybackStreamingEngineService.shared.playTrack(track);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return _buildPlaceholder();

    // Couldn't resolve permalink — fall back to plain text bubble
    if (_track == null) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: widget.isMe ? AppColors.primaryOrange : AppColors.containerMid,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
            bottomRight: Radius.circular(widget.isMe ? 4 : 18),
          ),
        ),
        child: Text(
          widget.permalink,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.35,
          ),
        ),
      );
    }

    final track = _track!;
    final artwork = track.artworkUrl ?? '';

    return GestureDetector(
      onTap: _play,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Album artwork
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: artwork.isNotEmpty
                    ? Image.network(
                        artwork,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, _) =>
                            _artworkPlaceholder(),
                      )
                    : _artworkPlaceholder(),
              ),
              const SizedBox(width: 10),
              // Title + artist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      track.artistName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Options button
              GestureDetector(
                onTap: () => _showOptions(context, track),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.more_horiz,
                    color: Colors.white54,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, PlaybackTrackModel track) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackOptionsSheet(track: track),
    );
  }

  Widget _artworkPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      color: AppColors.containerMid,
      child: const Icon(
        Icons.graphic_eq_rounded,
        color: Colors.white24,
        size: 24,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 240,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            color: AppColors.primaryOrange,
            strokeWidth: 2,
          ),
        ),
      ),
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
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      onTap: onTap,
    );
  }
}
