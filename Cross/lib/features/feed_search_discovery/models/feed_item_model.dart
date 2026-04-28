// Model: FeedItemModel
// Shape returned by GET /api/feed/v1/feed
// {
//   "id": "string",
//   "type": "track",
//   "isRepost": true,
//   "createdAt": "2026-04-27T12:41:11.123Z",
//   "actorId": "string",
//   "displayName": "string",
//   "imgLink": "string"
// }

class FeedItemModel {
  final String _id;
  final String _type;
  final bool _isRepost;
  final String _createdAt;
  final String _actorId;
  final String _displayName;
  final String? _imgLink;

  FeedItemModel(
    this._id,
    this._type,
    this._isRepost,
    this._createdAt,
    this._actorId,
    this._displayName,
    this._imgLink,
  );

  String get id => _id;
  String get type => _type;
  bool get isRepost => _isRepost;
  String get createdAt => _createdAt;
  String get actorId => _actorId;
  String get displayName => _displayName;
  String? get imgLink => _imgLink;

  factory FeedItemModel.fromJson(Map<String, dynamic> json) {
    return FeedItemModel(
      json['id']?.toString() ?? '',
      json['type']?.toString() ?? 'track',
      json['isRepost'] as bool? ?? false,
      json['createdAt']?.toString() ?? '',
      json['actorId']?.toString() ?? '',
      json['displayName']?.toString() ?? '',
      json['imgLink']?.toString(),
    );
  }

  static List<FeedItemModel> listFromJson(List<dynamic> list) {
    return list
        .map((item) => FeedItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
