import 'endpoint_headers.dart';

class S3Utils {
  /// Constructs the full S3 asset URL from the filename
  static String constructAssetUrl(String s3FileName) {
    return '${ApiEndpoints.baseUrl}/auth/view-s3-assets/?filename=$s3FileName';
  }

  /// Checks if a given string is an S3 filename (contains forward slashes)
  static bool isS3FileName(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.contains('/') && !value.startsWith('http');
  }

  /// Gets the display URL for profile images
  /// If it's already a full URL, returns as-is
  /// If it's an S3 filename, constructs the asset URL
  static String getProfileImageUrl(String? profileImage) {
    if (profileImage == null || profileImage.isEmpty) return '';

    // If it's already a full URL, return as-is
    if (profileImage.startsWith('http')) {
      return profileImage;
    }

    // If it's an S3 filename, construct the asset URL
    if (isS3FileName(profileImage)) {
      return constructAssetUrl(profileImage);
    }

    // If it's neither, assume it's an S3 filename
    return constructAssetUrl(profileImage);
  }
}
