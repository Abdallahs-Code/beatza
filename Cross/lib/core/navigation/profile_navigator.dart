import 'package:flutter/material.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/followers_social_graph/models/follower.dart';
import 'package:cross_team5/features/followers_social_graph/services/social_api_service.dart';
import 'package:cross_team5/features/user_profile_social_identity/user_profile_social_identity.dart';

class ProfileNavigator {
  ProfileNavigator._();

  /// Fetches credentials, following list, and blocked list for the authenticated
  /// user, then determines [initialIsFollowing] and [initialIsBlocked] for [userId].
  static Future<Map<String, dynamic>> _resolveArgs(String userId) async {
    final token = await AuthApiService().getStoredAccessToken() ?? '';
    final currentUserId = await AuthApiService().getStoredUserId();
    final normalizedCurrentUserId = currentUserId?.trim() ?? '';

    bool initialIsFollowing = false;
    bool initialIsBlocked = false;

    if (normalizedCurrentUserId.isNotEmpty) {
      try {
        final results = await Future.wait<(int, dynamic)>([
          SocialApiService().getFollowing(userId: normalizedCurrentUserId),
          SocialApiService().getBlockedUsers(),
        ]);

        final followingResult = results[0];
        final blockedResult = results[1];

        if (followingResult.$1 == 200 && followingResult.$2 is List) {
          initialIsFollowing = (followingResult.$2 as List).any(
            (u) => u is Follower && u.userId.trim() == userId,
          );
        }

        if (blockedResult.$1 == 200 && blockedResult.$2 is List) {
          initialIsBlocked = (blockedResult.$2 as List).any(
            (u) => u is Follower && u.userId.trim() == userId,
          );
        }
      } catch (_) {}
    }

    return {
      'userId': userId,
      'token': token,
      'currentUserId': normalizedCurrentUserId.isEmpty
          ? null
          : normalizedCurrentUserId,
      'initialIsFollowing': initialIsFollowing,
      'initialIsBlocked': initialIsBlocked,
    };
  }

  /// Returns true if the authenticated user currently follows [targetUserId].
  ///
  /// Uses the same following-list check as [push] / [pushViaState] so all
  /// follow-state queries stay consistent across the app.
  static Future<bool> checkIsFollowing(String targetUserId) async {
    final normalizedTarget = targetUserId.trim();
    if (normalizedTarget.isEmpty) return false;
    final currentUserId = await AuthApiService().getStoredUserId();
    final normalizedCurrent = currentUserId?.trim() ?? '';
    if (normalizedCurrent.isEmpty) return false;
    try {
      final result = await SocialApiService().getFollowing(
        userId: normalizedCurrent,
      );
      if (result.$1 == 200 && result.$2 is List) {
        return (result.$2 as List).any(
          (u) => u is Follower && u.userId.trim() == normalizedTarget,
        );
      }
    } catch (_) {}
    return false;
  }

  /// Navigates to the user profile screen.
  ///
  /// Automatically fetches the token, current user ID, and resolves the
  /// follow/block relationship before pushing the route. Guards against an
  /// empty [userId] and checks [context.mounted] after the async work.
  static Future<void> push(BuildContext context, String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;

    final args = await _resolveArgs(normalizedUserId);

    if (!context.mounted) return;

    await Navigator.pushNamed(
      context,
      UserProfileSocialIdentityRoutes.userProfileRoute,
      arguments: args,
    );
  }

  /// Navigates to the user profile via a [NavigatorState] directly.
  ///
  /// Use this when the caller's [BuildContext] has been invalidated before
  /// pushing — typically after calling [Navigator.pop] on a bottom sheet.
  static Future<void> pushViaState(
    NavigatorState navigator,
    String userId,
  ) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;

    final args = await _resolveArgs(normalizedUserId);

    await navigator.pushNamed(
      UserProfileSocialIdentityRoutes.userProfileRoute,
      arguments: args,
    );
  }
}
