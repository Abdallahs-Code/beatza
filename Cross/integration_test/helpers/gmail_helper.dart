import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GmailHelper {
  static const String _tokenUrl = 'https://oauth2.googleapis.com/token';
  static const String _gmailApiBase = 'https://gmail.googleapis.com/gmail/v1/users/me';

  static Future<String> _getAccessToken() async {
    final clientId = dotenv.env['GMAIL_CLIENT_ID'];
    final clientSecret = dotenv.env['GMAIL_CLIENT_SECRET'];
    final refreshToken = dotenv.env['GMAIL_REFRESH_TOKEN'];

    assert(clientId != null, 'GMAIL_CLIENT_ID env var is not set');
    assert(clientSecret != null, 'GMAIL_CLIENT_SECRET env var is not set');
    assert(refreshToken != null, 'GMAIL_REFRESH_TOKEN env var is not set');

    final response = await http.post(
      Uri.parse(_tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': clientId!,
        'client_secret': clientSecret!,
        'refresh_token': refreshToken!,
        'grant_type': 'refresh_token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get access token: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['access_token'] as String;
  }

  static Future<String> getVerificationLink({
    required String toEmail,
    String subjectContains = 'Welcome to BeatZa!',
    int maxRetries = 5,
    Duration retryDelay = const Duration(seconds: 3),
  }) async {
    final accessToken = await _getAccessToken();

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final query = 'to:$toEmail subject:$subjectContains';
      final searchUrl = Uri.parse('$_gmailApiBase/messages').replace(
        queryParameters: {'q': query},
      );
      final searchResponse = await http.get(
        searchUrl,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (searchResponse.statusCode != 200) {
        throw Exception('Gmail search failed: ${searchResponse.statusCode} ${searchResponse.body}');
      }

      final searchData = jsonDecode(searchResponse.body);
      final messages = searchData['messages'] as List?;

      if (messages != null && messages.isNotEmpty) {
        final messageId = messages.first['id'] as String;
        final link = await _extractLinkFromMessage(messageId, accessToken);
        if (link != null) return link;
      }

      if (attempt < maxRetries) {
        await Future.delayed(retryDelay);
      }
    }

    throw Exception('Verification email not found for $toEmail after $maxRetries attempts');
  }

  static Future<String?> _extractLinkFromMessage(String messageId, String accessToken) async {
    final msgResponse = await http.get(
      Uri.parse('$_gmailApiBase/messages/$messageId?format=full'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (msgResponse.statusCode != 200) {
      throw Exception('Failed to fetch message: ${msgResponse.statusCode} ${msgResponse.body}');
    }

    final msgData = jsonDecode(msgResponse.body);
    final bodyText = _decodeMessageBody(msgData['payload']);

    if (bodyText == null) return null;

    final linkRegex = RegExp(
      r'https?://[^\s"<>]+(?:verify|confirm|activate)[^\s"<>]*',
      caseSensitive: false,
    );

    final match = linkRegex.firstMatch(bodyText);
    return match?.group(0);
  }

  static String? _decodeMessageBody(Map<String, dynamic> payload) {
    final mimeType = payload['mimeType'] as String? ?? '';
    final body = payload['body'] as Map<String, dynamic>?;
    final parts = payload['parts'] as List?;

    if (body != null && body['data'] != null) {
      final data = body['data'] as String;
      return utf8.decode(base64Url.decode(data));
    }

    if (parts != null) {
      String? plainText;
      String? htmlText;

      for (final part in parts) {
        final partMap = part as Map<String, dynamic>;
        final partMime = partMap['mimeType'] as String? ?? '';
        final decoded = _decodeMessageBody(partMap);

        if (decoded != null) {
          if (partMime.contains('plain')) plainText = decoded;
          if (partMime.contains('html')) htmlText = decoded;
        }
      }

      return plainText ?? htmlText;
    }

    return null;
  }

  /// Extracts the token from the verification link and calls the backend
  /// API directly to verify the email (the frontend page relies on JS).
  static Future<void> verifyEmail({
    required String email,
    String subjectContains = 'Welcome to BeatZa!',
  }) async {
    final link = await getVerificationLink(
      toEmail: email,
      subjectContains: subjectContains,
    );

    final uri = Uri.parse(link);
    final token = uri.queryParameters['token'];
    if (token == null) {
      throw Exception('Could not extract token from verification link: $link');
    }

    // Call the backend API endpoint directly
    final response = await http.get(
      Uri.parse('https://beatza.me/api/auth/v1/verify-email?token=$token'),
    );

    if (response.statusCode < 200 || response.statusCode >= 400) {
      throw Exception(
        'Failed to verify email via API: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Trashes all emails matching the given subject query.
  static Future<void> _trashEmailsBySubject({
    required String toEmail,
    required String subjectContains,
  }) async {
    final accessToken = await _getAccessToken();

    final query = 'to:$toEmail subject:$subjectContains';
    final searchUrl = Uri.parse('$_gmailApiBase/messages').replace(
      queryParameters: {'q': query},
    );
    final searchResponse = await http.get(
      searchUrl,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final messages = (jsonDecode(searchResponse.body)['messages'] as List?) ?? [];

    for (final msg in messages) {
      await http.post(
        Uri.parse('$_gmailApiBase/messages/${msg['id']}/trash'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
    }
  }

  static Future<void> deleteVerificationEmail({
    required String toEmail,
  }) async {
    await _trashEmailsBySubject(
      toEmail: toEmail,
      subjectContains: 'Welcome to BeatZa!',
    );
  }

  static Future<void> deleteAccountDeletionEmail({
    required String toEmail,
  }) async {
    await _trashEmailsBySubject(
      toEmail: toEmail,
      subjectContains: 'Your account has been deleted',
    );
  }

  static Future<void> deletePasswordResetEmail({
    required String toEmail,
  }) async {
    await _trashEmailsBySubject(
      toEmail: toEmail,
      subjectContains: 'Password Reset Requested',
    );
  }
}