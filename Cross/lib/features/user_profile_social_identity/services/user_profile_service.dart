// Dart imports
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Package imports
import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/core/services/logger_service.dart';
import 'package:cross_team5/features/user_profile_social_identity/models/profile_link_model.dart';
import 'package:cross_team5/features/user_profile_social_identity/models/user_profile_model.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => "ApiException($statusCode): $message";
}

class UserProfileService {
  static const bool useMockProfile = false;

  final ApiServices _apiServices = ApiServices();
  String? _servicePath;

  UserProfileService() {
    _servicePath = "${_apiServices.baseUrl}/api/profile/v1";
  }

  Future<UserProfileModel> getUserProfile(String userId, String token) async {
    if (useMockProfile) {
      await Future.delayed(const Duration(milliseconds: 500));
      return UserProfileModel(
        userId: '123',
        displayName: "Abdelrahman Kamal",
        firstName: "Abdelrahman",
        lastName: "Kamal",
        profileUrl: "https://example.com/profiles/$userId", //
        profileImgLink:
            " https://res.cloudinary.com/dexluedse/image/upload/v1744719629/mobile-app/lwvswk21xn3wpgoufqxi.jpg",
        bannerImgLink:
            "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?q=80&w=1200&auto=format&fit=crop",
        bio:
            "Creating vibes and building apps. Testing profile UI without backend.",
        city: "Cairo",
        country: "Egypt",
        links: const [
          ProfileLinkModel(
            linkId: "1",
            title: "Instagram",
            link: "https://instagram.com/testuser",
            platform: "instagram",
          ),
          ProfileLinkModel(
            linkId: "2",
            title: "Twitter / X",
            link: "https://x.com/testuser",
            platform: "twitter",
          ),
          ProfileLinkModel(
            linkId: "3",
            title: "Website",
            link: "https://example.com",
            platform: "website",
          ),
        ],
        bannerLinks: const [],
        supportLink: "https://example.com/support",
        role: "Artist",
        isPaid: true,
        favoriteGenres: const ["Electronic", "Hip-Hop", "Phonk", "Lo-fi"],
        followersCount: 14500,
        followingsCount: 320,
        trackCount: 45,
        isPrivate: true,
      );
    }

    try {
      final url = "$_servicePath/$userId";

      LoggerService.logger.i("GET PROFILE URL: $url");

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "Authorization": "Bearer $token",
              "User-Agent": "Android",
            },
          )
          .timeout(const Duration(seconds: 10));

      LoggerService.logger.i(
        "GET PROFILE STATUS: ${response.statusCode}\nGET PROFILE BODY: ${response.body}",
      );

      final body = response.body.trim();

      if (body.startsWith("<!DOCTYPE html") || body.startsWith("<html")) {
        throw ApiException(
          response.statusCode,
          "Profile endpoint returned HTML instead of JSON.",
        );
      }

      final data = jsonDecode(body);

      if (response.statusCode == 200) {
        return UserProfileModel.fromJson(data);
      }

      throw ApiException(
        response.statusCode,
        data is Map<String, dynamic>
            ? (data["message"] ?? "Failed to load profile")
            : "Failed to load profile",
      );
    } on TimeoutException {
      throw ApiException(408, "Connection timed out while loading profile");
    } on FormatException {
      throw ApiException(500, "Invalid JSON response from profile API");
    } catch (err) {
      if (err is ApiException) rethrow;
      throw ApiException(500, "Network error: $err");
    }
  }

  Future<UserProfileModel> updateUserProfile(
    UserProfileModel updatedProfile,
    String token,
  ) async {
    if (useMockProfile) {
      await Future.delayed(const Duration(milliseconds: 500));
      return updatedProfile;
    }

    try {
      final payload = updatedProfile.toUpdatePayload();
      LoggerService.logger.i("UPDATE PROFILE PAYLOAD: ${jsonEncode(payload)}");

      final response = await http
          .patch(
            Uri.parse(_servicePath!),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "Authorization": "Bearer $token",
              "User-Agent": "Android",
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      LoggerService.logger.i(
        "UPDATE PROFILE STATUS: ${response.statusCode}\nUPDATE PROFILE BODY: ${response.body}",
      );

      final body = response.body.trim();

      if (body.startsWith("<!DOCTYPE html") || body.startsWith("<html")) {
        throw ApiException(
          response.statusCode,
          "Profile update endpoint returned HTML instead of JSON.",
        );
      }

      final data = body.isNotEmpty ? jsonDecode(body) : {};

      if (response.statusCode == 200) {
        if (data is Map<String, dynamic> && data.isNotEmpty) {
          return UserProfileModel.fromJson(data);
        }
        return getUserProfile(updatedProfile.userId, token);
      }

      throw ApiException(
        response.statusCode,
        data is Map<String, dynamic>
            ? (data["message"] ?? "Failed to update profile")
            : "Failed to update profile",
      );
    } on TimeoutException {
      throw ApiException(408, "Connection timed out while updating profile");
    } on FormatException {
      throw ApiException(500, "Invalid JSON response from profile update API");
    } catch (err) {
      if (err is ApiException) rethrow;
      throw ApiException(500, "Network error: $err");
    }
  }

  Future<Map<String, dynamic>> getPrivacySettings(String token) async {
    if (useMockProfile) {
      await Future.delayed(const Duration(milliseconds: 300));
      return {
        "allow_messages_anyone": true,
        "show_activity_discovery": true,
        "show_first_top_fan": true,
        "show_track_top_fans": true,
      };
    }

    try {
      final response = await http
          .get(
            Uri.parse("${_apiServices.baseUrl}/api/settings/privacy"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "Authorization": "Bearer $token",
              "User-Agent": "Android",
            },
          )
          .timeout(const Duration(seconds: 10));

      LoggerService.logger.i(
        "GET PRIVACY STATUS: ${response.statusCode}\nGET PRIVACY BODY: ${response.body}",
      );

      final body = response.body.trim();

      if (body.startsWith("<!DOCTYPE html") || body.startsWith("<html")) {
        throw ApiException(
          response.statusCode,
          "Privacy endpoint returned HTML instead of JSON.",
        );
      }

      final data = jsonDecode(body);

      if (response.statusCode == 200) {
        return data is Map<String, dynamic> ? data : <String, dynamic>{};
      }

      throw ApiException(
        response.statusCode,
        data is Map<String, dynamic>
            ? (data["message"] ?? "Failed to load privacy settings")
            : "Failed to load privacy settings",
      );
    } on TimeoutException {
      throw ApiException(
        408,
        "Connection timed out while loading privacy settings",
      );
    } on FormatException {
      throw ApiException(500, "Invalid JSON response from privacy API");
    } catch (err) {
      if (err is ApiException) rethrow;
      throw ApiException(500, "Network error: $err");
    }
  }

  Future<void> updatePrivacySettings({
    required String token,
    required bool allowMessagesAnyone,
    required bool showActivityDiscovery,
    required bool showFirstTopFan,
    required bool showTrackTopFans,
  }) async {
    if (useMockProfile) {
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    }

    try {
      final response = await http
          .patch(
            Uri.parse("${_apiServices.baseUrl}/api/settings/privacy"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "Authorization": "Bearer $token",
              "User-Agent": "Android",
            },
            body: jsonEncode({
              "allow_messages_anyone": allowMessagesAnyone,
              "show_activity_discovery": showActivityDiscovery,
              "show_first_top_fan": showFirstTopFan,
              "show_track_top_fans": showTrackTopFans,
            }),
          )
          .timeout(const Duration(seconds: 10));

      LoggerService.logger.i(
        "UPDATE PRIVACY STATUS: ${response.statusCode}\nUPDATE PRIVACY BODY: ${response.body}",
      );

      final body = response.body.trim();

      if (body.startsWith("<!DOCTYPE html") || body.startsWith("<html")) {
        throw ApiException(
          response.statusCode,
          "Privacy update endpoint returned HTML instead of JSON.",
        );
      }

      if (response.statusCode == 200) {
        return;
      }

      final data = body.isNotEmpty ? jsonDecode(body) : {};

      throw ApiException(
        response.statusCode,
        data is Map<String, dynamic>
            ? (data["message"] ?? "Failed to update privacy settings")
            : "Failed to update privacy settings",
      );
    } on TimeoutException {
      throw ApiException(
        408,
        "Connection timed out while updating privacy settings",
      );
    } on FormatException {
      throw ApiException(500, "Invalid JSON response from privacy update API");
    } catch (err) {
      if (err is ApiException) rethrow;
      throw ApiException(500, "Network error: $err");
    }
  }
}
