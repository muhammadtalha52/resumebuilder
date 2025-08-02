import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_logic.dart';

final appLogicProvider = Provider<AppLogic>((ref) {
  return AppLogic();
});