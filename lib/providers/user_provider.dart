import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

// Provider to get current user from auth state
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});

// Provider to get current user's role
final userRoleProvider = Provider<int?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role;
});

// Provider to check if user is a candidate (role = 1)
final isCandidateProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 1;
});

// Provider to check if user is a student (role = 2)
final isStudentProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 2;
});
