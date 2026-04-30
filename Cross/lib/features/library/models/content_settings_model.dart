class ContentSettings {
  final String? rssFeedLink;
  final String? rssEmailDisplayed;
  final String? customFieldTitle;
  final String? category;
  final String? statsServiceUrlPrefix;
  final String? customAuthorName;
  final String? language;
  final String? subscriberRedirect;
  final bool containsExplicitContent;
  final bool includeInRssFeed;
  final bool creativeCommonsLicense;

  const ContentSettings({
    this.rssFeedLink,
    this.rssEmailDisplayed,
    this.customFieldTitle,
    this.category,
    this.statsServiceUrlPrefix,
    this.customAuthorName,
    this.language,
    this.subscriberRedirect,
    required this.containsExplicitContent,
    required this.includeInRssFeed,
    required this.creativeCommonsLicense,
  });

  factory ContentSettings.fromJson(Map<String, dynamic> json) {
    return ContentSettings(
      rssFeedLink: json['rssFeedLink'] as String?,
      rssEmailDisplayed: json['rssEmailDisplayed'] as String?,
      customFieldTitle: json['customFieldTitle'] as String?,
      category: json['category'] as String?,
      statsServiceUrlPrefix: json['statsServiceUrlPrefix'] as String?,
      customAuthorName: json['customAuthorName'] as String?,
      language: json['language'] as String?,
      subscriberRedirect: json['subscriberRedirect'] as String?,
      containsExplicitContent: json['containsExplicitContent'] == true,
      includeInRssFeed: json['includeInRssFeed'] == true,
      creativeCommonsLicense: json['creativeCommonsLicense'] == true,
    );
  }

  // Only includes string fields that have a value — the backend rejects empty
  // strings and invalid URLs, so omitting them lets the server keep its value.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'containsExplicitContent': containsExplicitContent,
      'includeInRssFeed': includeInRssFeed,
      'creativeCommonsLicense': creativeCommonsLicense,
    };
    void addIfPresent(String key, String? value) {
      if (value != null && value.isNotEmpty) map[key] = value;
    }
    addIfPresent('rssFeedLink', rssFeedLink);
    addIfPresent('rssEmailDisplayed', rssEmailDisplayed);
    addIfPresent('customFieldTitle', customFieldTitle);
    addIfPresent('category', category);
    addIfPresent('statsServiceUrlPrefix', statsServiceUrlPrefix);
    addIfPresent('customAuthorName', customAuthorName);
    addIfPresent('language', language);
    addIfPresent('subscriberRedirect', subscriberRedirect);
    return map;
  }
}
