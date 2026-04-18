import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Handles avatar uploads via Cloudinary's unsigned upload API.
/// No SDK needed — just a multipart HTTP POST.
///
/// Free tier: 25 GB storage + 25 GB bandwidth/month.
/// Returns a secure CDN URL stored as a simple string in Firestore.
class UploadRepository {
  static const String _cloudName = 'daez9rfrd';
  static const String _uploadPreset = 'Eagle_Esports';
  static const String _avatarFolder = 'avatar';
  static const String _bannerFolder = 'banner';

  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Uploads [bytes] to Cloudinary and returns the secure CDN URL.
  Future<String> uploadAvatarBytes(String userId, Uint8List bytes) async {
    debugPrint('═══ CLOUDINARY UPLOAD START ═══');
    debugPrint('  UserId: $userId');
    debugPrint('  Bytes: ${bytes.length}');

    if (bytes.isEmpty) {
      throw Exception('Image data is empty (0 bytes).');
    }

    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
      ..fields['upload_preset'] = _uploadPreset
      ..fields['asset_folder'] = _avatarFolder
      ..fields['public_id'] = 'avatar_$userId' // deterministic ID → overwrites on re-upload
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'avatar_$userId.jpg',
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('  Status: ${response.statusCode}');

    if (response.statusCode != 200) {
      debugPrint('  Body: ${response.body}');
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = json['secure_url'] as String?;

    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary returned no URL. Response: ${response.body}');
    }

    debugPrint('  ✓ CDN URL: $secureUrl');
    debugPrint('═══ CLOUDINARY UPLOAD DONE ═══');

    return secureUrl;
  }

  /// Uploads a tournament banner image to Cloudinary's `banner` folder.
  /// Returns the secure CDN URL.
  Future<String> uploadBannerBytes(String bannerId, Uint8List bytes) async {
    debugPrint('═══ CLOUDINARY BANNER UPLOAD START ═══');
    debugPrint('  BannerId: $bannerId');
    debugPrint('  Bytes: ${bytes.length}');

    if (bytes.isEmpty) {
      throw Exception('Image data is empty (0 bytes).');
    }

    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
      ..fields['upload_preset'] = _uploadPreset
      ..fields['asset_folder'] = _bannerFolder
      ..fields['public_id'] = 'banner_$bannerId'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'banner_$bannerId.jpg',
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('  Status: ${response.statusCode}');

    if (response.statusCode != 200) {
      debugPrint('  Body: ${response.body}');
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = json['secure_url'] as String?;

    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary returned no URL. Response: ${response.body}');
    }

    debugPrint('  ✓ CDN URL: $secureUrl');
    debugPrint('═══ CLOUDINARY BANNER UPLOAD DONE ═══');

    return secureUrl;
  }

  // ── Backward-compatibility helpers for any existing base64 avatars ──────────

  /// Returns true if [url] is a legacy base64 data URI (not a CDN URL).
  static bool isBase64Avatar(String url) => url.startsWith('data:image');

  /// Decodes a legacy base64 data URI back to raw bytes for display.
  static Uint8List decodeBase64Avatar(String dataUri) {
    final raw = dataUri.split(',').last;
    return base64Decode(raw);
  }
}
