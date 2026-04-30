class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final List<String> seenBy;
  final DateTime createdAt;
  final bool isReceiverBlocked;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.seenBy,
    required this.createdAt,
    this.isReceiverBlocked = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id']?.toString() ?? '',
      chatId: json['chatId']?.toString() ?? '',
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
      isReceiverBlocked: json['isReceiverBlocked'] == true,
    );
  }
}
