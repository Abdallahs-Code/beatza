class ChatPersonModel {
  final String userId;
  final String displayName;
  final String photoUrl;

  const ChatPersonModel({
    required this.userId,
    required this.displayName,
    required this.photoUrl,
  });

  factory ChatPersonModel.fromJson(Map<String, dynamic> json) {
    // photo may be nested under profileImg.imgLink
    String photo = json['photoUrl']?.toString() ?? '';
    if (photo.isEmpty) {
      final profileImg = json['profileImg'];
      if (profileImg is Map) {
        photo = profileImg['imgLink']?.toString() ?? '';
      }
    }
    return ChatPersonModel(
      userId: json['userId']?.toString() ?? json['_id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      photoUrl: photo,
    );
  }
}

class LastMessageModel {
  final String id;
  final String senderId;
  final String content;
  final List<String> seenBy;
  final DateTime createdAt;

  const LastMessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.seenBy,
    required this.createdAt,
  });

  factory LastMessageModel.fromJson(Map<String, dynamic> json) {
    return LastMessageModel(
      id: json['_id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      seenBy:
          (json['seenBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class ChatModel {
  final String id;
  // Participant user IDs (extracted from participant objects in GET /chats)
  final List<String> participants;
  final LastMessageModel? lastMessage;
  // HTTP GET /chats uses "receiver"; socket broadcasts use "sender"
  final ChatPersonModel? receiver;
  final ChatPersonModel? sender;

  const ChatModel({
    required this.id,
    this.participants = const [],
    this.lastMessage,
    this.receiver,
    this.sender,
  });

  ChatPersonModel? get otherPerson => receiver ?? sender;

  bool isUnread(String currentUserId) {
    final lm = lastMessage;
    if (lm == null) return false;
    return lm.senderId != currentUserId && !lm.seenBy.contains(currentUserId);
  }

  ChatModel copyWith({LastMessageModel? lastMessage}) {
    return ChatModel(
      id: id,
      participants: participants,
      lastMessage: lastMessage ?? this.lastMessage,
      receiver: receiver,
      sender: sender,
    );
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    final rawLm = json['lastMessage'];
    final rawReceiver = json['receiver'];
    final rawSender = json['sender'];

    // API uses "chat" key (GET /chats), fallbacks for socket events and other shapes
    String id = '';
    for (final key in ['chat', 'chatId', '_id', 'id']) {
      final v = json[key]?.toString() ?? '';
      if (v.isNotEmpty) {
        id = v;
        break;
      }
    }

    // Participants come as full user objects — extract their _id strings
    final participants = <String>[];
    final rawParticipants = json['participants'];
    if (rawParticipants is List) {
      for (final p in rawParticipants) {
        if (p is String && p.isNotEmpty) {
          participants.add(p);
        } else if (p is Map) {
          final pid =
              p['_id']?.toString() ??
              p['id']?.toString() ??
              p['userId']?.toString() ??
              '';
          if (pid.isNotEmpty) participants.add(pid);
        }
      }
    }

    return ChatModel(
      id: id,
      participants: participants,
      lastMessage: rawLm is Map<String, dynamic>
          ? LastMessageModel.fromJson(rawLm)
          : null,
      receiver: rawReceiver is Map<String, dynamic>
          ? ChatPersonModel.fromJson(rawReceiver)
          : null,
      sender: rawSender is Map<String, dynamic>
          ? ChatPersonModel.fromJson(rawSender)
          : null,
    );
  }
}
