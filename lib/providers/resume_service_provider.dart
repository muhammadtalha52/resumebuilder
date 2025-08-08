import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/resume_service.dart';

final resumeServiceProvider = Provider<ResumeService>((ref) {
  return ResumeService();
});