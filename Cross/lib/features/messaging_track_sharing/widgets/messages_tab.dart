import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/messaging_track_sharing/models/chat_model.dart';
import 'package:cross_team5/features/messaging_track_sharing/screens/chat_screen.dart';
import 'package:cross_team5/features/messaging_track_sharing/services/messaging_api_service.dart';
import 'package:cross_team5/features/messaging_track_sharing/services/messaging_socket_service.dart';
import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

enum MessageFilter { all, unreadOnly }

class MessagesTab extends StatefulWidget {
  final MessageFilter filter;

  const MessagesTab({super.key, this.filter = MessageFilter.all});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  final _api = MessagingApiService();
  final _socket = MessagingSocketService.shared;
  final _auth = AuthApiService();

  List<ChatModel> _chats = [];
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant MessagesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-filter happens in build; no reload needed
  }

  Future<void> _init() async {
    _currentUserId = await _auth.getStoredUserId();
    final token = await _auth.getStoredAccessToken() ?? '';
    await _socket.connect(token: token);
    _socket.onMessageNotify = _onNotify;
    await _load();
  }

  Future<void> _load() async {
    debugPrint(
      '[MessagesTab._load] Fetching chats. currentUserId=$_currentUserId',
    );
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
      
    try {
      final chats = await _api.getChats();
      if (!mounted) return;
      debugPrint('[MessagesTab._load] Got ${chats.length} chats');
      for (final c in chats) {
        final lm = c.lastMessage;
        debugPrint(
          '[MessagesTab._load] → chat ${c.id}: isUnread=${c.isUnread(_currentUserId ?? "")} senderId=${lm?.senderId} seenBy=${lm?.seenBy}',
        );
      }
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('[MessagesTab._load] Error: $e');
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onNotify(ChatModel incoming) {
    if (!mounted) return;
    setState(() {
      final idx = _chats.indexWhere((c) => c.id == incoming.id);
      if (idx >= 0) {
        _chats[idx] = incoming;
      } else {
        _chats = [incoming, ..._chats];
      }
    });
  }

  @override
  void dispose() {
    _socket.onMessageNotify = null;
    super.dispose();
  }

  List<ChatModel> get _filtered {
    final uid = _currentUserId ?? '';
    if (widget.filter == MessageFilter.unreadOnly) {
      return _chats.where((c) => c.isUnread(uid)).toList();
    }
    return _chats;
  }

  // Future<void> _openChat(ChatModel chat) async {
  //   debugPrint('[MessagesTab._openChat] Opening chat ${chat.id}. isUnread=${chat.isUnread(_currentUserId ?? "")}');

  //   // Optimistically mark as read in local state so the unread dot disappears immediately
  //   if (_currentUserId != null) {
  //     final idx = _chats.indexWhere((c) => c.id == chat.id);
  //     if (idx >= 0) {
  //       final lm = _chats[idx].lastMessage;
  //       if (lm != null && !lm.seenBy.contains(_currentUserId)) {
  //         debugPrint('[MessagesTab._openChat] Optimistically marking chat ${chat.id} as read');
  //         setState(() {
  //           _chats[idx] = _chats[idx].copyWith(
  //             lastMessage: LastMessageModel(
  //               id: lm.id,
  //               senderId: lm.senderId,
  //               content: lm.content,
  //               seenBy: [...lm.seenBy, _currentUserId!],
  //               createdAt: lm.createdAt,
  //             ),
  //           );
  //         });
  //       }
  //     }
  //   }

  //   final archived = await Navigator.of(context).push<bool>(
  //     MaterialPageRoute(
  //       builder: (_) => ChatScreen(
  //         chatId: chat.id,
  //         receiverId: chat.otherPerson?.userId ?? '',
  //         receiverName: chat.otherPerson?.displayName ?? '',
  //         receiverPhotoUrl: chat.otherPerson?.photoUrl ?? '',
  //       ),
  //     ),
  //   );
  //   if (!mounted) return;
  //   if (archived == true) {
  //     debugPrint('[MessagesTab._openChat] Chat ${chat.id} archived');
  //     setState(() => _chats.removeWhere((c) => c.id == chat.id));
  //   } else {
  //     final visitedChatId = chat.id;
  //     debugPrint('[MessagesTab._openChat] Returned from chat $visitedChatId, refreshing list');
  //     await _load();
  //     // Issue 1: server sometimes returns stale seenBy even after markChatAsRead
  //     // succeeds. Re-apply our optimistic read mark so the unread dot stays gone.
  //     if (mounted && _currentUserId != null) {
  //       final idx = _chats.indexWhere((c) => c.id == visitedChatId);
  //       if (idx >= 0 && _chats[idx].isUnread(_currentUserId!)) {
  //         debugPrint('[MessagesTab._openChat] Server still shows unread for $visitedChatId after reload — forcing local read');
  //         final lm = _chats[idx].lastMessage;
  //         if (lm != null) {
  //           setState(() {
  //             _chats[idx] = _chats[idx].copyWith(
  //               lastMessage: LastMessageModel(
  //                 id: lm.id,
  //                 senderId: lm.senderId,
  //                 content: lm.content,
  //                 seenBy: [...lm.seenBy, _currentUserId!],
  //                 createdAt: lm.createdAt,
  //               ),
  //             );
  //           });
  //         }
  //       }
  //     }
  //   }
  // }

  Future<void> _openChat(ChatModel chat) async {
    debugPrint('━━━ [MessagesTab._openChat] ━━━');
    debugPrint(
      '[MessagesTab._openChat] chat.id="${chat.id}" (empty=${chat.id.isEmpty})',
    );
    debugPrint('[MessagesTab._openChat] participants=${chat.participants}');
    debugPrint(
      '[MessagesTab._openChat] otherPerson.userId="${chat.otherPerson?.userId}" name="${chat.otherPerson?.displayName}"',
    );
    debugPrint(
      '[MessagesTab._openChat] isUnread=${chat.isUnread(_currentUserId ?? "")}',
    );

    // Optimistically mark as read in local state so the unread dot disappears immediately
    if (_currentUserId != null) {
      final idx = _chats.indexWhere((c) => c.id == chat.id);
      if (idx >= 0) {
        final lm = _chats[idx].lastMessage;
        if (lm != null && !lm.seenBy.contains(_currentUserId)) {
          debugPrint(
            '[MessagesTab._openChat] Optimistically marking chat ${chat.id} as read',
          );
          setState(() {
            _chats[idx] = _chats[idx].copyWith(
              lastMessage: LastMessageModel(
                id: lm.id,
                senderId: lm.senderId,
                content: lm.content,
                seenBy: [...lm.seenBy, _currentUserId!],
                createdAt: lm.createdAt,
              ),
            );
          });
        }
      }
    }

    // Push ChatScreen and wait for it to close
    // ✅ We now always get a result because ChatScreen always pops with true
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chat.id,
          receiverId: chat.otherPerson?.userId ?? '',
          receiverName: chat.otherPerson?.displayName ?? '',
          receiverPhotoUrl: chat.otherPerson?.photoUrl ?? '',
        ),
      ),
    );

    // ✅ ALWAYS refresh the messages list when returning from chat
    if (mounted) {
      debugPrint(
        '[MessagesTab._openChat] Chat closed, refreshing messages list',
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryOrange,
          strokeWidth: 2,
        ),
      );
    }

    if (_error != null && _chats.isEmpty) {
      return _buildError();
    }

    final chats = _filtered;

    if (chats.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: AppColors.primaryOrange,
      backgroundColor: AppColors.surface,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: chats.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: AppColors.white10, indent: 74),
        itemBuilder: (ctx, i) => _ChatTile(
          chat: chats[i],
          currentUserId: _currentUserId ?? '',
          onTap: () => _openChat(chats[i]),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.mail_outline_rounded, color: AppColors.white24, size: 60),
        const SizedBox(height: 20),
        Text(
          widget.filter == MessageFilter.unreadOnly
              ? 'No unread messages'
              : 'No messages yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.whiteSmoke,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Your conversations will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white54,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppColors.white54,
              size: 42,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.white54, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _load,
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
      ),
    );
  }
}

// ── Chat list tile ──────────────────────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;
  final VoidCallback onTap;

  const _ChatTile({
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final person = chat.otherPerson;
    final name = person?.displayName ?? '';
    final photo = person?.photoUrl ?? '';
    final lm = chat.lastMessage;
    final isUnread = chat.isUnread(currentUserId);

    return InkWell(
      onTap: onTap,
      splashColor: AppColors.whiteSmoke.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.containerMid,
              backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
              child: photo.isEmpty
                  ? Text(
                      _initials(name),
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 14,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (lm != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      lm.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isUnread ? AppColors.white70 : AppColors.white54,
                        fontSize: 13,
                        fontWeight: isUnread
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lm != null)
                  Text(
                    _timeAgo(lm.createdAt),
                    style: TextStyle(
                      color: isUnread
                          ? AppColors.primaryOrange
                          : AppColors.white54,
                      fontSize: 12,
                    ),
                  ),
                if (isUnread) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo';
    return '${(diff.inDays / 365).floor()}y';
  }
}
