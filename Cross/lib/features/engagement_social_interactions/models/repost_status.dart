





























class RepostStatus {
  final bool _reposted;
  final String? _caption;
  final String? _repostedAt;

  RepostStatus(this._reposted, this._caption, this._repostedAt);

  bool get reposted => _reposted;
  String? get caption => _caption;
  String? get repostedAt => _repostedAt;

  
  
  
  factory RepostStatus.fromJson(Map<String, dynamic> json) {
    return RepostStatus(
      json['reposted'] as bool? ?? false,
      json['caption']?.toString(),
      json['repostedAt']?.toString(),
    );
  }

  
  
  
  
  factory RepostStatus.notReposted() {
    return RepostStatus(false, null, null);
  }
}
