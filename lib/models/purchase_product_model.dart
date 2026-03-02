/// Model representing an in-app purchase product
class PurchaseProduct {
  final String id;
  final String name;
  final String description;
  final String price;
  final int resumeCredits;
  final int interviewCredits;
  final String tier; // 'basic', 'pro', 'premium'

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
  // Candidate product IDs
  static const String basicProductId = 'com.skillresy.candidate.basic';
  static const String proProductId = 'com.skillresy.candidate.pro';
  static const String premiumProductId = 'com.skillresy.candidate.enterprise';

  // Student product IDs
  static const String studentBasicProductId = 'com.skillresy.student.basic';
  static const String studentProProductId = 'com.skillresy.student.pro';
  static const String studentEnterpriseProductId =
      'com.skillresy.student.enterprise';

  static const PurchaseProduct basic = PurchaseProduct(
    id: basicProductId,
    name: 'Basic Plan',
    description: '3 Resume Generations + 1 Interview Session',
    price: '\$20.99',
    resumeCredits: 3,
    interviewCredits: 1,
    tier: 'basic',
  );

  static const PurchaseProduct pro = PurchaseProduct(
    id: proProductId,
    name: 'Pro Plan',
    description: '6 Resume Generations + 5 Interview Sessions',
    price: '\$30.99',
    resumeCredits: 6,
    interviewCredits: 5,
    tier: 'pro',
  );

  static const PurchaseProduct premium = PurchaseProduct(
    id: premiumProductId,
    name: 'Premium Plan',
    description: '10 Resume Generations + 10 Interview Sessions',
    price: '\$40.99',
    resumeCredits: 10,
    interviewCredits: 10,
    tier: 'premium',
  );

  static const List<PurchaseProduct> allProducts = [basic, pro, premium];

  // All product IDs including both candidate and student products
  static List<String> get allProductIds => [
    // Candidate product IDs
    basicProductId,
    proProductId,
    premiumProductId,
    // Student product IDs
    studentBasicProductId,
    studentProProductId,
    studentEnterpriseProductId,
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
