class AccountSettings {
  final String theme;
  final String dateOfBirth;
  final String gender;

  const AccountSettings({
    required this.theme,
    required this.dateOfBirth,
    required this.gender,
  });

  factory AccountSettings.fromJson(Map<String, dynamic> json) {
    return AccountSettings(
      theme: (json['theme'] ?? 'Dark').toString(),
      dateOfBirth: (json['dateOfBirth'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'theme': theme,
    'dateOfBirth': dateOfBirth,
    'gender': gender,
  };

  AccountSettings copyWith({
    String? theme,
    String? dateOfBirth,
    String? gender,
  }) => AccountSettings(
    theme: theme ?? this.theme,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    gender: gender ?? this.gender,
  );
}
