// Model: SearchSuggestionModel
// Shape from GET /api/public/feed/v1/search/suggestions
// Response:
// [ { "id": "string", "type": "track", "title": "string",
//     "imgLink": "string", "isPersonalized": true } ]

class SearchSuggestionModel {
  final String _id;
  final String _type;
  final String _title;
  final String? _imgLink;
  final bool _isPersonalized;

  SearchSuggestionModel(
    this._id,
    this._type,
    this._title,
    this._imgLink,
    this._isPersonalized,
  );

  String get id => _id;
  String get type => _type;
  String get title => _title;
  String? get imgLink => _imgLink;
  bool get isPersonalized => _isPersonalized;

  factory SearchSuggestionModel.fromJson(Map<String, dynamic> json) {
    return SearchSuggestionModel(
      json['id']?.toString() ?? '',
      json['type']?.toString() ?? 'track',
      json['title']?.toString() ?? '',
      json['imgLink']?.toString(),
      json['isPersonalized'] as bool? ?? false,
    );
  }

  static List<SearchSuggestionModel> listFromJson(List<dynamic> list) {
    return list
        .map(
          (item) =>
              SearchSuggestionModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
