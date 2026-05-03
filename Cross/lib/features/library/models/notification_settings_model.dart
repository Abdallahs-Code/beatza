class NotificationSettings {
  final String newFollower;
  final String repostOfYourPost;
  final String newPostByFollowedUser;
  final String likesAndPlaysOnYourPost;
  final String commentOnYourPost;
  final String recommendedContent;
  final String updatesFromSoundcloud;
  final String soundcloudFeatureUpdatesEducation;
  final String surveysAndFeedback;
  final String promotionalPartnershipContent;
  final String soundcloudNewsletter;
  final bool newMessageEmail;
  final String newMessageDevices; 

  const NotificationSettings({
    required this.newFollower,
    required this.repostOfYourPost,
    required this.newPostByFollowedUser,
    required this.likesAndPlaysOnYourPost,
    required this.commentOnYourPost,
    required this.recommendedContent,
    required this.updatesFromSoundcloud,
    required this.soundcloudFeatureUpdatesEducation,
    required this.surveysAndFeedback,
    required this.promotionalPartnershipContent,
    required this.soundcloudNewsletter,
    required this.newMessageEmail,
    required this.newMessageDevices,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final msg = json['newMessage'] as Map<String, dynamic>? ?? {};
    return NotificationSettings(
      newFollower: (json['newFollower'] ?? 'off').toString(),
      repostOfYourPost: (json['repostOfYourPost'] ?? 'off').toString(),
      newPostByFollowedUser: (json['newPostByFollowedUser'] ?? 'off')
          .toString(),
      likesAndPlaysOnYourPost: (json['likesAndPlaysOnYourPost'] ?? 'off')
          .toString(),
      commentOnYourPost: (json['commentOnYourPost'] ?? 'off').toString(),
      recommendedContent: (json['recommendedContent'] ?? 'off').toString(),
      updatesFromSoundcloud: (json['updatesFromSoundcloud'] ?? 'off')
          .toString(),
      soundcloudFeatureUpdatesEducation:
          (json['soundcloudFeatureUpdatesEducation'] ?? 'off').toString(),
      surveysAndFeedback: (json['surveysAndFeedback'] ?? 'off').toString(),
      promotionalPartnershipContent:
          (json['promotionalPartnershipContent'] ?? 'off').toString(),
      soundcloudNewsletter: (json['soundcloudNewsletter'] ?? 'off').toString(),
      newMessageEmail: msg['email'] == true,
      newMessageDevices: (msg['devices'] ?? 'off').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'newFollower': newFollower,
    'repostOfYourPost': repostOfYourPost,
    'newPostByFollowedUser': newPostByFollowedUser,
    'likesAndPlaysOnYourPost': likesAndPlaysOnYourPost,
    'commentOnYourPost': commentOnYourPost,
    'recommendedContent': recommendedContent,
    'updatesFromSoundcloud': updatesFromSoundcloud,
    'soundcloudFeatureUpdatesEducation': soundcloudFeatureUpdatesEducation,
    'surveysAndFeedback': surveysAndFeedback,
    'promotionalPartnershipContent': promotionalPartnershipContent,
    'soundcloudNewsletter': soundcloudNewsletter,
    'newMessage': {'email': newMessageEmail, 'devices': newMessageDevices},
  };

  static bool hasDevices(String v) => v == 'devices' || v == 'both';
  static bool hasEmail(String v) => v == 'email' || v == 'both';

  static String toggleDevices(String current) {
    switch (current) {
      case 'off':
        return 'devices';
      case 'email':
        return 'both';
      case 'devices':
        return 'off';
      case 'both':
        return 'email';
      default:
        return 'devices';
    }
  }

  static String toggleEmail(String current) {
    switch (current) {
      case 'off':
        return 'email';
      case 'devices':
        return 'both';
      case 'email':
        return 'off';
      case 'both':
        return 'devices';
      default:
        return 'email';
    }
  }

  NotificationSettings copyWith({
    String? newFollower,
    String? repostOfYourPost,
    String? newPostByFollowedUser,
    String? likesAndPlaysOnYourPost,
    String? commentOnYourPost,
    String? recommendedContent,
    String? updatesFromSoundcloud,
    String? soundcloudFeatureUpdatesEducation,
    String? surveysAndFeedback,
    String? promotionalPartnershipContent,
    String? soundcloudNewsletter,
    bool? newMessageEmail,
    String? newMessageDevices,
  }) => NotificationSettings(
    newFollower: newFollower ?? this.newFollower,
    repostOfYourPost: repostOfYourPost ?? this.repostOfYourPost,
    newPostByFollowedUser: newPostByFollowedUser ?? this.newPostByFollowedUser,
    likesAndPlaysOnYourPost:
        likesAndPlaysOnYourPost ?? this.likesAndPlaysOnYourPost,
    commentOnYourPost: commentOnYourPost ?? this.commentOnYourPost,
    recommendedContent: recommendedContent ?? this.recommendedContent,
    updatesFromSoundcloud: updatesFromSoundcloud ?? this.updatesFromSoundcloud,
    soundcloudFeatureUpdatesEducation:
        soundcloudFeatureUpdatesEducation ??
        this.soundcloudFeatureUpdatesEducation,
    surveysAndFeedback: surveysAndFeedback ?? this.surveysAndFeedback,
    promotionalPartnershipContent:
        promotionalPartnershipContent ?? this.promotionalPartnershipContent,
    soundcloudNewsletter: soundcloudNewsletter ?? this.soundcloudNewsletter,
    newMessageEmail: newMessageEmail ?? this.newMessageEmail,
    newMessageDevices: newMessageDevices ?? this.newMessageDevices,
  );
}