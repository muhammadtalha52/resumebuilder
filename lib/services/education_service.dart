import 'package:dio/dio.dart';
import '../models/education_model.dart';
import '../utils/endpoint_headers.dart';
import 'api_client.dart';

class EducationService {
  final APIClient _apiClient = APIClient();

  Future<EducationModel> getEducationData() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.educationData);

      if (response.statusCode == 200 && response.data != null) {
        return EducationModel.fromJson(response.data);
      } else {
        throw Exception(
          response.data?['message'] ?? 'Failed to fetch education data',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Failed to fetch education data';

        if (responseData is Map) {
          if (responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          } else if (responseData.containsKey('error')) {
            errorMessage = responseData['error'].toString();
          }
        }

        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to fetch education data: $e');
    }
  }
}
