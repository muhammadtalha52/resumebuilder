import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

final apiClientProvider = Provider<APIClient>((ref) {
  final apiClient = APIClient();
  apiClient.init();
  return apiClient;
});