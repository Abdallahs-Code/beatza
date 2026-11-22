






class TrendingItemModel {
  final String _id;

  TrendingItemModel(this._id);

  String get id => _id;

  factory TrendingItemModel.fromJson(Map<String, dynamic> json) {
    return TrendingItemModel(json['id']?.toString() ?? '');
  }

  static List<TrendingItemModel> listFromJson(List<dynamic> list) {
    return list
        .map((item) => TrendingItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
