import 'package:flutter/material.dart';
import 'screens/user_profile_screen.dart';

class UserProfileSocialIdentityRoutes {
  static const String userProfileRoute = '/user_profile';

  static Map<String, WidgetBuilder> routes = {
    userProfileRoute: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      final String userId = (args?['userId'] ?? '').toString().trim();
      final String token = (args?['token'] ?? '').toString().trim();
      final String? currentUserId = args?['currentUserId']?.toString();

      return UserProfileScreen(
        userId: userId.isEmpty ? 'test_user_id' : userId,
        token: token.isEmpty ? 'test_token' : token,
        currentUserId: currentUserId,
      );
    },
  };
}