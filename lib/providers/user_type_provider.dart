import 'package:flutter_riverpod/flutter_riverpod.dart';

final userTypeProvider = StateProvider<String?>((ref) => null);

enum UserType { candidate, student }

extension UserTypeExtension on UserType {
  String get value {
    switch (this) {
      case UserType.candidate:
        return 'candidate';
      case UserType.student:
        return 'student';
    }
  }

  String get displayName {
    switch (this) {
      case UserType.candidate:
        return 'Job Candidate';
      case UserType.student:
        return 'Student';
    }
  }
}

UserType? userTypeFromString(String? value) {
  if (value == null) return null;

  switch (value.toLowerCase()) {
    case 'candidate':
      return UserType.candidate;
    case 'student':
      return UserType.student;
    default:
      return null;
  }
}
