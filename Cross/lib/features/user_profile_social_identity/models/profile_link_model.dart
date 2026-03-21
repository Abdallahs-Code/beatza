class ProfileLinkModel {
  final String linkId;
  final String title;
  final String link;
  final String platform;

  const ProfileLinkModel({
    required this.linkId,
    required this.title,
    required this.link,
    required this.platform,
  });

  factory ProfileLinkModel.fromJson(Map<String, dynamic> json) {
    final rawTitle = (json['name'] ?? json['title'] ?? '').toString().trim();

    return ProfileLinkModel(
      linkId: (json['linkId'] ?? json['link_id'] ?? '').toString(),
      title: rawTitle,
      link: (json['link'] ?? '').toString().trim(),
      platform: _normalizePlatform(rawTitle),
    );
  }

  Map<String, dynamic> toJson() {
  final map = <String, dynamic>{
    'name': title,
    'link': normalizedUrl,
  };

  if (linkId.trim().isNotEmpty) {
    map['linkId'] = linkId.trim();
  }

  return map;
}

  ProfileLinkModel copyWith({
    String? linkId,
    String? title,
    String? link,
    String? platform,
  }) {
    return ProfileLinkModel(
      linkId: linkId ?? this.linkId,
      title: title ?? this.title,
      link: link ?? this.link,
      platform: platform ?? this.platform,
    );
  }

  bool get isEmpty => link.trim().isEmpty;

  bool get isNotEmpty => !isEmpty;

  String get normalizedUrl {
    final trimmed = link.trim();
    if (trimmed.isEmpty) return '';

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return trimmed;
    }

    return 'https://$trimmed';
  }

  static String _normalizePlatform(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized.contains('instagram')) return 'instagram';
    if (normalized == 'x' || normalized.contains('twitter')) return 'twitter';
    if (normalized.contains('website') || normalized.contains('site')) return 'website';
    if (normalized.contains('facebook')) return 'facebook';
    if (normalized.contains('youtube')) return 'youtube';
    if (normalized.contains('tiktok')) return 'tiktok';

    return normalized.isEmpty ? 'link' : normalized;
  }
}