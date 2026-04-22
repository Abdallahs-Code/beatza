import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/messaging_track_sharing/models/chat_model.dart';
import 'package:cross_team5/features/messaging_track_sharing/screens/chat_screen.dart';
import 'package:cross_team5/features/messaging_track_sharing/services/messaging_api_service.dart';
import 'package:cross_team5/features/messaging_track_sharing/services/messaging_socket_service.dart';
import 'package:flutter/material.dart';

const _kSurface = Color(0xFF1C1C1C);
const _kOrange = Color(0xFFFF5500);

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
    if (mounted) setState(() { _isLoading = true; _error = null; });
    try {
      final chats = await _api.getChats();
      if (!mounted) return;
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _openChat(ChatModel chat) async {
    final archived = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chat.id,
          receiverName: chat.otherPerson?.displayName ?? '',
          receiverPhotoUrl: chat.otherPerson?.photoUrl ?? '',
        ),
      ),
    );
    // If archived, remove from list
    if (archived == true && mounted) {
      setState(() => _chats.removeWhere((c) => c.id == chat.id));
    } else if (mounted) {
      // Mark as read in local state
      setState(() {
        final idx = _chats.indexWhere((c) => c.id == chat.id);
        if (idx >= 0) {
          final lm = _chats[idx].lastMessage;
          if (lm != null && _currentUserId != null &&
              !lm.seenBy.contains(_currentUserId)) {
            final updatedLm = LastMessageModel(
              id: lm.id,
              senderId: lm.senderId,
              content: lm.content,
              seenBy: [...lm.seenBy, _currentUserId!],
              createdAt: lm.createdAt,
            );
            _chats[idx] = _chats[idx].copyWith(lastMessage: updatedLm);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: _kOrange, strokeWidth: 2));
    }

    if (_error != null && _chats.isEmpty) {
      return _buildError();
    }

    final chats = _filtered;

    if (chats.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: _kOrange,
      backgroundColor: _kSurface,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: chats.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: Colors.white10, indent: 74),
        itemBuilder: (ctx, i) =>
            _ChatTile(
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
        const Icon(Icons.mail_outline_rounded,
            color: Colors.white24, size: 60),
        const SizedBox(height: 20),
        Text(
          widget.filter == MessageFilter.unreadOnly
              ? 'No unread messages'
              : 'No messages yet',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Your conversations will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white38, fontSize: 14, height: 1.5),
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
            const Icon(Icons.error_outline_rounded,
                color: Colors.white38, size: 42),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _load,
              child: const Text('Try again',
                  style: TextStyle(
                      color: _kOrange,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
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
      splashColor: Colors.white.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF2A2A2A),
              backgroundImage:
                  photo.isNotEmpty ? NetworkImage(photo) : null,
              child: photo.isEmpty
                  ? Text(
                      _initials(name),
                      style: const TextStyle(
                        color: Colors.white,
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
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: isUnread
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  if (lm != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      lm.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            isUnread ? Colors.white70 : Colors.white38,
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
                      color: isUnread ? _kOrange : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                if (isUnread) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _kOrange,
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
