/// Model representing a plan from the backend API
class BackendPlanModel {
  final int id;
  final String name;
  final String planType;
  final String productId;
  final String price;
  final int resumeCount;
  final int interviewCount;
  final int quizCount;
  final int documentUploadCount;
  final bool isActive;

  const BackendPlanModel({
    required this.id,
    required this.name,
    required this.planType,
    required this.productId,
    required this.price,
    required this.resumeCount,
    required this.interviewCount,
    required this.quizCount,
    required this.documentUploadCount,
    required this.isActive,
  });

  factory BackendPlanModel.fromJson(Map<String, dynamic> json) {
    return BackendPlanModel(
      id: json['id'] as int,
      name: json['name'] as String,
      planType: json['plan_type'] as String,
      productId: json['product_id'] as String,
      price: json['price'] as String,
      resumeCount: json['resume_count'] as int,
      interviewCount: json['interview_count'] as int,
      quizCount: json['quiz_count'] as int,
      documentUploadCount: json['document_upload_count'] as int,
      isActive: json['is_active'] as bool,
    );
  }

  @override
  String toString() {
    return 'BackendPlanModel(id: $id, name: $name, productId: $productId)';
  }
}

/// Response model for plans list API
class PlansListResponse {
  final String status;
  final String message;
  final List<BackendPlanModel> data;

  const PlansListResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory PlansListResponse.fromJson(Map<String, dynamic> json) {
    return PlansListResponse(
      status: json['status'] as String,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => BackendPlanModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
