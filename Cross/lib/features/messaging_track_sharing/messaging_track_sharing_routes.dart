import 'package:cross_team5/features/messaging_track_sharing/screens/chat_screen.dart';
import 'package:flutter/material.dart';

class MessagingTrackSharingRoutes {
  static const String chatRoute = '/messaging/chat';

  static Map<String, WidgetBuilder> get routes => {
        chatRoute: (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ChatScreen(
            chatId: args['chatId'] as String?,
            receiverId: args['receiverId'] as String?,
            receiverName: args['receiverName'] as String? ?? '',
            receiverPhotoUrl: args['receiverPhotoUrl'] as String? ?? '',
            initialContent: args['initialContent'] as String?,
          );
        },
      };
}
