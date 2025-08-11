import 'package:flutter/foundation.dart';

@immutable
class ProfileUpdateState {
  final bool isLoading;
  final String? error;
  final Map<String, String> originalValues;
  final Map<String, String> currentValues;
  final bool hasChanges;
  final String completePhoneNumber;

  const ProfileUpdateState({
    this.isLoading = false,
    this.error,
    this.originalValues = const {},
    this.currentValues = const {},
    this.hasChanges = false,
    this.completePhoneNumber = '',
  });

  ProfileUpdateState copyWith({
    bool? isLoading,
    String? error,
    Map<String, String>? originalValues,
    Map<String, String>? currentValues,
    bool? hasChanges,
    String? completePhoneNumber,
  }) {
    return ProfileUpdateState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      originalValues: originalValues ?? this.originalValues,
      currentValues: currentValues ?? this.currentValues,
      hasChanges: hasChanges ?? this.hasChanges,
      completePhoneNumber: completePhoneNumber ?? this.completePhoneNumber,
    );
  }

  // Helper method to get changed fields only
  Map<String, dynamic> getChangedFields() {
    final changes = <String, dynamic>{};

    currentValues.forEach((key, value) {
      if (originalValues[key] != value) {
        // Special handling for phone number
        if (key == 'phone_number') {
          if (completePhoneNumber.isNotEmpty &&
              completePhoneNumber != originalValues['phone_number']) {
            changes['phone_number'] = completePhoneNumber;
          }
        } else if (value.isNotEmpty ||
            originalValues[key]?.isNotEmpty == true) {
          // Only include if value is not empty or if it's being cleared (was not empty before)
          changes[key] = value.isEmpty ? null : value;
        }
      }
    });

    return changes;
  }

  // Check if there are any changes
  bool checkHasChanges() {
    return getChangedFields().isNotEmpty;
  }
}
