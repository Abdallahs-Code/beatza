import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiServices {
  String? _baseUrl;

  ApiServices() {
    _baseUrl = dotenv.env['BASE_URL'] ?? "http://localhost:4123";
  }

  String get baseUrl => _baseUrl!;
}
