import 'profile_link_model.dart';

class UserProfileModel {
  final String userId;
  final String displayName;
  final String firstName;
  final String lastName;
  final String profileUrl;
  final String profileImgLink;
  final String bannerImgLink;
  final String bio;
  final String city;
  final String country;
  final List<ProfileLinkModel> links;
  final List<ProfileLinkModel> bannerLinks;
  final String supportLink;
  final String role;
  final bool isPaid;
  final List<String> favoriteGenres;
  final int followersCount;
  final int followingsCount;
  final int trackCount;
  final bool isPrivate;

  const UserProfileModel({
    required this.userId,
    this.displayName = '',
    this.firstName = '',
    this.lastName = '',
    this.profileUrl = '',
    this.profileImgLink = '',
    this.bannerImgLink = '',
    this.bio = '',
    this.city = '',
    this.country = '',
    this.links = const [],
    this.bannerLinks = const [],
    this.supportLink = '',
    this.role = 'Listener',
    this.isPaid = false,
    this.favoriteGenres = const [],
    this.followersCount = 0,
    this.followingsCount = 0,
    this.trackCount = 0,
    this.isPrivate = false,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: (json['userId'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      profileUrl: (json['profileLink'] ?? '').toString(),
      profileImgLink: (json['profileImgLink'] ?? '').toString(),
      bannerImgLink: (json['bannerImgLink'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      links:
      (json['links'] as List?)
          ?.map(
            (e) => ProfileLinkModel.fromJson(Map<String, dynamic>.from(e)),
      )
          .toList() ??
          const [],
      bannerLinks:
      (json['bannerLinks'] as List?)
          ?.map(
            (e) => ProfileLinkModel.fromJson(Map<String, dynamic>.from(e)),
      )
          .toList() ??
          const [],
      supportLink: (json['supportLink'] ?? '').toString(),
      role: _normalizeRole((json['role'] ?? '').toString()),
      isPaid: json['isPaid'] == true,
      favoriteGenres:
      (json['favoriteGenres'] as List?)
          ?.map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList() ??
          const [],
      followersCount: _readInt(json['followersCount']),
      followingsCount: _readInt(
        json['followingsCount'] ?? json['followedCount'],
      ),
      trackCount: _readInt(json['trackCount']),
      isPrivate: json['isPrivate'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'profileLink': profileUrl,
      'profileImgLink': profileImgLink,
      'bannerImgLink': bannerImgLink,
      'bio': bio,
      'city': city,
      'country': country,
      'links': links.map((e) => e.toJson()).toList(),
      'bannerLinks': bannerLinks.map((e) => e.toJson()).toList(),
      'supportLink': supportLink,
      'role': role,
      'isPaid': isPaid,
      'favoriteGenres': favoriteGenres,
      'followersCount': followersCount,
      'followingsCount': followingsCount,
      'trackCount': trackCount,
      'isPrivate': isPrivate,
    };
  }

  Map<String, dynamic> toUpdatePayload() {
    final Map<String, dynamic> payload = {};

    if (displayName.trim().isNotEmpty)
      payload['displayName'] = displayName.trim();
    if (firstName.trim().isNotEmpty) payload['firstName'] = firstName.trim();
    if (lastName.trim().isNotEmpty) payload['lastName'] = lastName.trim();
    if (profileUrl.trim().isNotEmpty)
      payload['profileLink'] = profileUrl.trim();
    if (bio.trim().isNotEmpty) payload['bio'] = bio.trim();
    if (city.trim().isNotEmpty) payload['city'] = city.trim();
    if (country.trim().isNotEmpty) payload['country'] = country.trim();

    if (favoriteGenres.isNotEmpty) payload['favoriteGenres'] = favoriteGenres;

    payload['isPrivate'] = isPrivate;

    final validLinks = links
        .where((e) => e.link.trim().isNotEmpty)
        .map((e) => e.toJson())
        .toList();
    payload['links'] = validLinks;

    final validBannerLinks = bannerLinks
        .where((e) => e.link.trim().isNotEmpty)
        .map((e) => e.toJson())
        .toList();
    if (validBannerLinks.isNotEmpty) payload['bannerLinks'] = validBannerLinks;

    final normalizedSupportLink = _normalizeUrl(supportLink);
    if (normalizedSupportLink != null) {
      payload['supportLink'] = normalizedSupportLink;
    }

    return payload;
  }

  UserProfileModel copyWith({
    String? userId,
    String? displayName,
    String? firstName,
    String? lastName,
    String? profileUrl,
    String? profileImgLink,
    String? bannerImgLink,
    String? bio,
    String? city,
    String? country,
    List<ProfileLinkModel>? links,
    List<ProfileLinkModel>? bannerLinks,
    String? supportLink,
    String? role,
    bool? isPaid,
    List<String>? favoriteGenres,
    int? followersCount,
    int? followingsCount,
    int? trackCount,
    bool? isPrivate,
  }) {
    return UserProfileModel(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileUrl: profileUrl ?? this.profileUrl,
      profileImgLink: profileImgLink ?? this.profileImgLink,
      bannerImgLink: bannerImgLink ?? this.bannerImgLink,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      country: country ?? this.country,
      links: links ?? this.links,
      bannerLinks: bannerLinks ?? this.bannerLinks,
      supportLink: supportLink ?? this.supportLink,
      role: role ?? this.role,
      isPaid: isPaid ?? this.isPaid,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      followersCount: followersCount ?? this.followersCount,
      followingsCount: followingsCount ?? this.followingsCount,
      trackCount: trackCount ?? this.trackCount,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }

  String get resolvedDisplayName {
    if (displayName.trim().isNotEmpty) return displayName.trim();
    final fullName = [
      firstName.trim(),
      lastName.trim(),
    ].where((e) => e.isNotEmpty).join(' ');
    if (fullName.isNotEmpty) return fullName;
    return 'Unknown User';
  }

  String get resolvedLocation {
    final parts = [
      city.trim(),
      country.trim(),
    ].where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? 'Location not added yet' : parts.join(', ');
  }

  String get resolvedBio {
    return bio.trim().isEmpty ? 'No bio added yet.' : bio.trim();
  }

  List<ProfileLinkModel> get visibleLinks {
    return links.where((e) => e.link.trim().isNotEmpty).toList();
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _normalizeRole(String value) {
    final lower = value.trim().toLowerCase();
    if (lower.contains('artist')) return 'Artist';
    if (lower.contains('listener')) return 'Listener';
    return value.trim().isEmpty ? 'Listener' : value.trim();
  }

  static String? _normalizeUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final normalized =
    trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : 'https://$trimmed';

    final uri = Uri.tryParse(normalized);
    if (uri == null) return null;
    if ((uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
      return null;
    }

    return normalized;
  }
}