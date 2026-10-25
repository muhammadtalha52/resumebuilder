/// Model representing an in-app purchase product
class PurchaseProduct {
  final String id;
  final String name;
  final String description;
  final String price;
  final int resumeCredits;
  final int interviewCredits;
  final String tier; // 'weekend_warrior', 'just_scouting', etc.

  const PurchaseProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.resumeCredits,
    required this.interviewCredits,
    required this.tier,
  });

  factory PurchaseProduct.fromJson(Map<String, dynamic> json) {
    return PurchaseProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as String,
      resumeCredits: json['resume_credits'] as int,
      interviewCredits: json['interview_credits'] as int,
      tier: json['tier'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'resume_credits': resumeCredits,
      'interview_credits': interviewCredits,
      'tier': tier,
    };
  }

  PurchaseProduct copyWith({
    String? id,
    String? name,
    String? description,
    String? price,
    int? resumeCredits,
    int? interviewCredits,
    String? tier,
  }) {
    return PurchaseProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      resumeCredits: resumeCredits ?? this.resumeCredits,
      interviewCredits: interviewCredits ?? this.interviewCredits,
      tier: tier ?? this.tier,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PurchaseProduct &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.price == price &&
        other.resumeCredits == resumeCredits &&
        other.interviewCredits == interviewCredits &&
        other.tier == tier;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        price.hashCode ^
        resumeCredits.hashCode ^
        interviewCredits.hashCode ^
        tier.hashCode;
  }

  @override
  String toString() {
    return 'PurchaseProduct(id: $id, name: $name, tier: $tier, resumeCredits: $resumeCredits, interviewCredits: $interviewCredits, price: $price)';
  }
}

/// Predefined product configurations
class PurchaseProducts {
  // Candidate product IDs (New 8-tier plans)
  static const String weekendWarriorProductId =
      'com.skillresy.candidate.weekend_warrior';
  static const String justScoutingProductId =
      'com.skillresy.candidate.just_scouting';
  static const String seriousSeekerProductId =
      'com.skillresy.candidate.serious_seeker';
  static const String jobHunterProductId =
      'com.skillresy.candidate.job_hunter';

  // Student product IDs (New 8-tier plans)
  static const String cramSessionProductId =
      'com.skillresy.student.cram_session';
  static const String basicStudentProductId =
      'com.skillresy.student.basic_student';
  static const String midStudentProductId =
      'com.skillresy.student.mid_student';
  static const String nerdOutProductId =
      'com.skillresy.student.nerd_out';

  // Candidate Purchase Products
  static const PurchaseProduct weekendWarrior = PurchaseProduct(
    id: weekendWarriorProductId,
    name: 'Weekend Warrior',
    description: '3 Resumes, 3 Interviews, 10 Ask Scout',
    price: '\$10.99',
    resumeCredits: 3,
    interviewCredits: 3,
    tier: 'weekend_warrior',
  );

  static const PurchaseProduct justScouting = PurchaseProduct(
    id: justScoutingProductId,
    name: 'Just Scouting',
    description: '5 Resumes, 3 Interviews, 20 Ask Scout',
    price: '\$14.99',
    resumeCredits: 5,
    interviewCredits: 3,
    tier: 'just_scouting',
  );

  static const PurchaseProduct seriousSeeker = PurchaseProduct(
    id: seriousSeekerProductId,
    name: 'Serious Seeker',
    description: '12 Resumes, 8 Interviews, 45 Ask Scout',
    price: '\$24.99',
    resumeCredits: 12,
    interviewCredits: 8,
    tier: 'serious_seeker',
  );

  static const PurchaseProduct jobHunter = PurchaseProduct(
    id: jobHunterProductId,
    name: 'Job Hunter',
    description: '25 Resumes, 15 Interviews, 100 Ask Scout',
    price: '\$49.99',
    resumeCredits: 25,
    interviewCredits: 15,
    tier: 'job_hunter',
  );

  // Student Purchase Products
  static const PurchaseProduct cramSession = PurchaseProduct(
    id: cramSessionProductId,
    name: 'Cram Session',
    description: '12 Quizzes, 25 Document Uploads',
    price: '\$3.99',
    resumeCredits: 0,
    interviewCredits: 0,
    tier: 'cram_session',
  );

  static const PurchaseProduct basicStudent = PurchaseProduct(
    id: basicStudentProductId,
    name: 'Basic Student',
    description: '10 Quizzes, 20 Document Uploads',
    price: '\$5.00',
    resumeCredits: 0,
    interviewCredits: 0,
    tier: 'basic_student',
  );

  static const PurchaseProduct midStudent = PurchaseProduct(
    id: midStudentProductId,
    name: 'Mid Student',
    description: '25 Quizzes, 50 Document Uploads',
    price: '\$10.00',
    resumeCredits: 0,
    interviewCredits: 0,
    tier: 'mid_student',
  );

  static const PurchaseProduct nerdOut = PurchaseProduct(
    id: nerdOutProductId,
    name: 'Nerd Out',
    description: '50 Quizzes, 100 Document Uploads',
    price: '\$15.00',
    resumeCredits: 0,
    interviewCredits: 0,
    tier: 'nerd_out',
  );

  // All 8 Active Products for iOS StoreKit
  static const List<PurchaseProduct> allProducts = [
    weekendWarrior,
    justScouting,
    seriousSeeker,
    jobHunter,
    cramSession,
    basicStudent,
    midStudent,
    nerdOut,
  ];

  // Active product IDs for StoreKit query
  static List<String> get allProductIds => [
    weekendWarriorProductId,
    justScoutingProductId,
    seriousSeekerProductId,
    jobHunterProductId,
    cramSessionProductId,
    basicStudentProductId,
    midStudentProductId,
    nerdOutProductId,
  ];

  static PurchaseProduct? getProductById(String id) {
    try {
      return allProducts.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  static PurchaseProduct? getProductByTier(String tier) {
    try {
      return allProducts.firstWhere((product) => product.tier == tier);
    } catch (e) {
      return null;
    }
  }
}
