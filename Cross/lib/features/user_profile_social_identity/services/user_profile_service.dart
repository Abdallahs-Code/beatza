// Dart imports
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cross_team5/core/services/api_services.dart';
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

  // Public base path used for GET profile lookups (no auth required by backend).
  // PATCH operations (updateUserProfile, updateProfileImages) use _servicePath (authenticated).
  String get _publicServicePath =>
      "${_apiServices.baseUrl}/api/public/profile/v1";

  String _extractErrorMessage(Map<String, dynamic> data, String defaultMsg) {
    String msg = data["message"] ?? defaultMsg;
    if (data.containsKey("errors") && data["errors"] != null) {
      if (data["errors"] is List) {
        msg +=
            ": ${(data["errors"] as List).map((e) => e.toString()).join(", ")}";
      } else {
        msg += ": ${data["errors"]}";
      }
    }
    return msg;
  }

  Future<UserProfileModel> getUserProfile(String userId, String token) async {
    try {
      final url = "$_publicServicePath/$userId";
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

      final body = response.body.trim();
      if (body.startsWith("<!DOCTYPE html") || body.startsWith("<html")) {
        throw ApiException(
          response.statusCode,
          "Profile endpoint returned HTML.",
        );
      }

      final data = jsonDecode(body);
      if (response.statusCode == 200) {
        return UserProfileModel.fromJson(data);
      }

      throw ApiException(
        response.statusCode,
        data is Map<String, dynamic>
            ? _extractErrorMessage(data, "Failed to load profile")
            : "Failed to load profile",
      );
    } catch (err) {
      if (err is ApiException) rethrow;
      throw ApiException(500, "Network error: $err");
    }
  }

  Future<UserProfileModel> updateUserProfile(
    UserProfileModel updatedProfile,
    String token,
  ) async {
    try {
      final payload = updatedProfile.toUpdatePayload();

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

      final body = response.body.trim();
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
            ? _extractErrorMessage(data, "Text update failed")
            : "Text update failed",
      );
    } catch (err) {
      if (err is ApiException) rethrow;
      throw ApiException(500, "Network error: $err");
    }
  }

  Future<UserProfileModel> updateProfileImages({
    required String token,
    File? profileImg,
    File? bannerImg,
    bool removeProfileImg = false,
    bool removeBannerImg = false,
  }) async {
    try {
      final url = Uri.parse("$_servicePath/images");
      var request = http.MultipartRequest('PATCH', url);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'User-Agent': 'Android',
      });

      request.fields['removeProfileImg'] = removeProfileImg ? "true" : "false";
      request.fields['removeBannerImg'] = removeBannerImg ? "true" : "false";

      if (profileImg != null && profileImg.existsSync() && !removeProfileImg) {
        request.files.add(
          await http.MultipartFile.fromPath('profileImg', profileImg.path),
        );
      }

      if (bannerImg != null && bannerImg.existsSync() && !removeBannerImg) {
        request.files.add(
          await http.MultipartFile.fromPath('bannerImg', bannerImg.path),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 45),
      );
      final response = await http.Response.fromStream(streamedResponse);
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return UserProfileModel.fromJson(data);
      }

      throw ApiException(
        response.statusCode,
        data is Map<String, dynamic>
            ? (data["message"] ?? "Image update failed")
            : "Image update failed",
      );
    } catch (err) {
      if (err is ApiException) rethrow;
      throw ApiException(500, "Network error: $err");
    }
  }
}
