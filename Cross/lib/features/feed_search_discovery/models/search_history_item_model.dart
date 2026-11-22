





class SearchHistoryItemModel {
  final String _id;
  final String _type;
  final String _title;
  final String? _imageUrl;
  final String? _metadata;

  SearchHistoryItemModel(
    this._id,
    this._type,
    this._title,
    this._imageUrl,
    this._metadata,
  );

  String get id => _id;
  String get type => _type;
  String get title => _title;
  String? get imageUrl => _imageUrl;
  String? get metadata => _metadata;

  factory SearchHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItemModel(
      json['id']?.toString() ?? '',
      json['type']?.toString() ?? 'track',
      json['title']?.toString() ?? '',
      json['imageUrl']?.toString(),
      json['metadata']?.toString(),
    );
  }

  static List<SearchHistoryItemModel> listFromJson(List<dynamic> list) {
    return list
        .map(
          (item) =>
              SearchHistoryItemModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
