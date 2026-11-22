
import 'package:flutter/material.dart';


import 'package:cross_team5/features/user_profile_social_identity/user_profile_social_identity.dart';

class UserProfileSocialIdentityRoutes {
  static const String userProfileRoute = '/user_profile';

  static Map<String, WidgetBuilder> routes = {
    userProfileRoute: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      final String userId = (args?['userId'] ?? '').toString().trim();
      final String token = (args?['token'] ?? '').toString().trim();
      final String? currentUserId = args?['currentUserId']?.toString();
      final bool initialIsFollowing =
          (args?['initialIsFollowing'] ?? false) as bool;

      return UserProfileScreen(
        userId: userId.isEmpty ? 'test_user_id' : userId,
        token: token.isEmpty ? 'test_token' : token,
        currentUserId: currentUserId,
        initialIsFollowing: initialIsFollowing,
      );
    },
  };
}
