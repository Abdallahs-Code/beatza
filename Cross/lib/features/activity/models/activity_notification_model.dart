import 'package:flutter/material.dart';

enum ActivityNotificationFilter {
  all,
  reposts,
  likes,
  comments,
  followings,
  newTracks,
  mentions,
}

extension ActivityNotificationFilterX on ActivityNotificationFilter {
  String get label {
    switch (this) {
      case ActivityNotificationFilter.all:
        return 'Show all notifications';
      case ActivityNotificationFilter.reposts:
        return 'Reposts';
      case ActivityNotificationFilter.likes:
        return 'Likes';
      case ActivityNotificationFilter.comments:
        return 'Comments';
      case ActivityNotificationFilter.followings:
        return 'Followings';
      case ActivityNotificationFilter.newTracks:
        return 'New tracks';
      case ActivityNotificationFilter.mentions:
        return 'Mentions';
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityNotificationFilter.all:
        return Icons.notifications_none_rounded;
      case ActivityNotificationFilter.reposts:
        return Icons.repeat_rounded;
      case ActivityNotificationFilter.likes:
        return Icons.favorite_border_rounded;
      case ActivityNotificationFilter.comments:
        return Icons.chat_bubble_outline_rounded;
      case ActivityNotificationFilter.followings:
        return Icons.person_add_alt_1_rounded;
      case ActivityNotificationFilter.newTracks:
        return Icons.music_note_rounded;
      case ActivityNotificationFilter.mentions:
        return Icons.alternate_email_rounded;
    }
  }

  bool matches(ActivityNotificationModel notification) {
    switch (this) {
      case ActivityNotificationFilter.all:
        return true;
      case ActivityNotificationFilter.reposts:
        return notification.activityType == 'track_reposted';
      case ActivityNotificationFilter.likes:
        return notification.activityType == 'track_liked';
      case ActivityNotificationFilter.comments:
        return notification.activityType == 'track_commented';
      case ActivityNotificationFilter.followings:
        return notification.activityType == 'user_followed';
      case ActivityNotificationFilter.newTracks:
        return notification.activityType == 'new_track';
      case ActivityNotificationFilter.mentions:
        return notification.activityType == 'user_mentioned';
    }
  }
}

class ActivityNotificationActor {
  final String userId;
  final String displayName;
  final String avatarUrl;

  const ActivityNotificationActor({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
  });

  factory ActivityNotificationActor.fromJson(Map<String, dynamic> json) {
    return ActivityNotificationActor(
      userId: (json['userId'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      avatarUrl: (json['avatarUrl'] ?? '').toString(),
    );
  }
}

class ActivityNotificationTarget {
  final String targetType;
  final String targetId;
  final String? title;
  final String? trackId;
  final String? commentText;
  final String? mentionedUserProfileLink;

  const ActivityNotificationTarget({
    required this.targetType,
    required this.targetId,
    this.title,
    this.trackId,
    this.commentText,
    this.mentionedUserProfileLink,
  });

  factory ActivityNotificationTarget.fromJson(Map<String, dynamic> json) {
    return ActivityNotificationTarget(
      targetType: (json['targetType'] ?? '').toString(),
      targetId: (json['targetId'] ?? '').toString(),
      title: json['title']?.toString(),
      trackId: json['trackId']?.toString(),
      commentText: json['commentText']?.toString(),
      mentionedUserProfileLink: json['mentionedUserProfileLink']?.toString(),
    );
  }
}

class ActivityNotificationModel {
  final String notificationId;
  final String to;
  final bool read;
  final String activityType;
  final ActivityNotificationActor actor;
  final ActivityNotificationTarget target;
  final DateTime createdAt;

  const ActivityNotificationModel({
    required this.notificationId,
    required this.to,
    required this.read,
    required this.activityType,
    required this.actor,
    required this.target,
    required this.createdAt,
  });

  factory ActivityNotificationModel.fromJson(Map<String, dynamic> json) {
    return ActivityNotificationModel(
      notificationId: (json['notificationId'] ?? '').toString(),
      to: (json['to'] ?? '').toString(),
      read: json['read'] == true,
      activityType: (json['activityType'] ?? '').toString(),
      actor: ActivityNotificationActor.fromJson(
        Map<String, dynamic>.from(
          (json['actor'] as Map?) ?? <String, dynamic>{},
        ),
      ),
      target: ActivityNotificationTarget.fromJson(
        Map<String, dynamic>.from(
          (json['target'] as Map?) ?? <String, dynamic>{},
        ),
      ),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now().toUtc(),
    );
  }

  ActivityNotificationModel copyWith({
    String? notificationId,
    String? to,
    bool? read,
    String? activityType,
    ActivityNotificationActor? actor,
    ActivityNotificationTarget? target,
    DateTime? createdAt,
  }) {
    return ActivityNotificationModel(
      notificationId: notificationId ?? this.notificationId,
      to: to ?? this.to,
      read: read ?? this.read,
      activityType: activityType ?? this.activityType,
      actor: actor ?? this.actor,
      target: target ?? this.target,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ActivityNotificationsPage {
  final int total;
  final int offset;
  final int limit;
  final List<ActivityNotificationModel> notifications;

  const ActivityNotificationsPage({
    required this.total,
    required this.offset,
    required this.limit,
    required this.notifications,
  });

  factory ActivityNotificationsPage.fromJson(Map<String, dynamic> json) {
    final rawNotifications =
        (json['notifications'] as List?) ?? const <dynamic>[];

    return ActivityNotificationsPage(
      total: (json['total'] as num?)?.toInt() ?? rawNotifications.length,
      offset: (json['offset'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? rawNotifications.length,
      notifications: rawNotifications
          .whereType<Map>()
          .map(
            (item) => ActivityNotificationModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}