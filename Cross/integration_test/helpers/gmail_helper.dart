import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
      final searchResponse = await http.get(
        Uri.parse('$_gmailApiBase/messages?q=to:$toEmail+subject:$subjectContains'),
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

  static Future<void> openVerificationLink(String link) async {
    final uri = Uri.parse(link);
    if (!await canLaunchUrl(uri)) {
      throw Exception('Cannot launch URL: $link');
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> verifyEmail({
    required String email,
    String subjectContains = 'Welcome to BeatZa!',
  }) async {
    final link = await getVerificationLink(
      toEmail: email,
      subjectContains: subjectContains,
    );
    await openVerificationLink(link);
  }

  static Future<void> deleteVerificationEmail({
    required String toEmail,
    String subjectContains = 'Welcome to BeatZa!',
  }) async {
    final accessToken = await _getAccessToken();

    final searchResponse = await http.get(
      Uri.parse('$_gmailApiBase/messages?q=to:$toEmail+subject:$subjectContains'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final messages =(jsonDecode(searchResponse.body)['messages'] as List?) ?? [];

    for (final msg in messages) {
      await http.delete(
        Uri.parse('$_gmailApiBase/messages/${msg['id']}'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
    }
  }
}