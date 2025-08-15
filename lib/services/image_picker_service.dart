import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_colors.dart';

enum ImageSourceType { camera, gallery }

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickAndCropImage(BuildContext context) async {
    try {
      // Show image source selection dialog
      final ImageSourceType? sourceType = await _showImageSourceDialog(context);
      if (sourceType == null) return null;

      // Request permission
      bool hasPermission = await _requestPermission(sourceType);
      if (!hasPermission) {
        throw Exception(
          'Permission denied for ${sourceType == ImageSourceType.camera ? 'camera' : 'gallery'}',
        );
      }

      // Pick image
      final XFile? pickedFile = await _pickImage(sourceType);
      if (pickedFile == null) return null;

      // Crop image
      final CroppedFile? croppedFile = await _cropImage(pickedFile.path);
      if (croppedFile == null) return null;

      return File(croppedFile.path);
    } catch (e) {
      // Debug: Error in pickAndCropImage: $e
      rethrow;
    }
  }

  Future<ImageSourceType?> _showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSourceType>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_a_photo,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Buttons
                Row(
                  children: [
                    // Gallery button
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            Navigator.of(context).pop(ImageSourceType.gallery),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_library,
                                color: Color(0xFF6B7280),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Gallery',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Camera button
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            Navigator.of(context).pop(ImageSourceType.camera),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Camera',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Cancel button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _requestPermission(ImageSourceType sourceType) async {
    if (sourceType == ImageSourceType.camera) {
      // Request camera permission
      PermissionStatus cameraStatus = await Permission.camera.status;
      // Debug: Camera permission status: $cameraStatus
      if (cameraStatus.isDenied) {
        cameraStatus = await Permission.camera.request();
        // Debug: Camera permission after request: $cameraStatus
      }
      return cameraStatus.isGranted;
    } else {
      // Request gallery/photo permission
      // For Android 13+, use photos permission, for older versions use storage
      PermissionStatus photosStatus = await Permission.photos.status;
      // Debug: Photos permission status: $photosStatus
      if (photosStatus.isDenied) {
        photosStatus = await Permission.photos.request();
        // Debug: Photos permission after request: $photosStatus
      }

      if (photosStatus.isGranted) {
        return true;
      }

      // Fallback to storage permission for older Android versions
      PermissionStatus storageStatus = await Permission.storage.status;
      // Debug: Storage permission status: $storageStatus
      if (storageStatus.isDenied) {
        storageStatus = await Permission.storage.request();
        // Debug: Storage permission after request: $storageStatus
      }

      final hasPermission = storageStatus.isGranted || photosStatus.isGranted;
      // Debug: Final permission result: $hasPermission
      return hasPermission;
    }
  }

  Future<XFile?> _pickImage(ImageSourceType sourceType) async {
    try {
      final ImageSource source = sourceType == ImageSourceType.camera
          ? ImageSource.camera
          : ImageSource.gallery;

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      // Debug: Picked image: ${pickedFile?.path}
      return pickedFile;
    } catch (e) {
      // Debug: Error picking image: $e
      throw Exception('Failed to pick image: $e');
    }
  }

  Future<CroppedFile?> _cropImage(String imagePath) async {
    return await ImageCropper().cropImage(
      sourcePath: imagePath,
      aspectRatio: const CropAspectRatio(
        ratioX: 1,
        ratioY: 1,
      ), // Square aspect ratio for profile image
      aspectRatioPresets: [CropAspectRatioPreset.square],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Image',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: AppColors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          backgroundColor: AppColors.white,
          activeControlsWidgetColor: AppColors.primary,
          cropGridColor: AppColors.primary.withValues(alpha: 0.5),
          cropFrameColor: AppColors.primary,
          statusBarColor: AppColors.primary,
        ),
        IOSUiSettings(
          title: 'Crop Profile Image',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
          rotateButtonsHidden: false,
          rotateClockwiseButtonHidden: false,
        ),
      ],
    );
  }
}
