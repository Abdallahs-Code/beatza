class PrivacySettings {
  final bool allowMessagesAnyone;
  final bool showActivityDiscovery;
  final bool showFirstTopFan;
  final bool showTrackTopFans;

  const PrivacySettings({
    required this.allowMessagesAnyone,
    required this.showActivityDiscovery,
    required this.showFirstTopFan,
    required this.showTrackTopFans,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      allowMessagesAnyone: json['allowMessagesAnyone'] == true,
      showActivityDiscovery: json['showActivityDiscovery'] == true,
      showFirstTopFan: json['showFirstTopFan'] == true,
      showTrackTopFans: json['showTrackTopFans'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'allowMessagesAnyone': allowMessagesAnyone,
        'showActivityDiscovery': showActivityDiscovery,
        'showFirstTopFan': showFirstTopFan,
        'showTrackTopFans': showTrackTopFans,
      };

  PrivacySettings copyWith({
    bool? allowMessagesAnyone,
    bool? showActivityDiscovery,
    bool? showFirstTopFan,
    bool? showTrackTopFans,
  }) =>
      PrivacySettings(
        allowMessagesAnyone: allowMessagesAnyone ?? this.allowMessagesAnyone,
        showActivityDiscovery:
            showActivityDiscovery ?? this.showActivityDiscovery,
        showFirstTopFan: showFirstTopFan ?? this.showFirstTopFan,
        showTrackTopFans: showTrackTopFans ?? this.showTrackTopFans,
      );
}
