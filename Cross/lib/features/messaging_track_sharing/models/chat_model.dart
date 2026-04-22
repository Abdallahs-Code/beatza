class ChatPersonModel {
  final String displayName;
  final String photoUrl;

  const ChatPersonModel({required this.displayName, required this.photoUrl});

  factory ChatPersonModel.fromJson(Map<String, dynamic> json) {
    return ChatPersonModel(
      displayName: json['displayName']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString() ?? '',
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
      seenBy: (json['seenBy'] as List<dynamic>?)
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
  final LastMessageModel? lastMessage;
  // HTTP GET /chats uses "receiver"; socket broadcasts use "sender"
  final ChatPersonModel? receiver;
  final ChatPersonModel? sender;

  const ChatModel({
    required this.id,
    this.lastMessage,
    this.receiver,
    this.sender,
  });

  ChatPersonModel? get otherPerson => receiver ?? sender;

  bool isUnread(String currentUserId) {
    final lm = lastMessage;
    if (lm == null) return false;
    return lm.senderId != currentUserId &&
        !lm.seenBy.contains(currentUserId);
  }

  ChatModel copyWith({LastMessageModel? lastMessage}) {
    return ChatModel(
      id: id,
      lastMessage: lastMessage ?? this.lastMessage,
      receiver: receiver,
      sender: sender,
    );
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    final rawLm = json['lastMessage'];
    final rawReceiver = json['receiver'];
    final rawSender = json['sender'];
    return ChatModel(
      id: json['_id']?.toString() ?? '',
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
