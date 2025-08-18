class Resume {
  final String id;
  final String title;
  final String? description;
  final String? fileUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ResumeStatus status;
  final Map<String, dynamic>? parsedData;

  Resume({
    required this.id,
    required this.title,
    this.description,
    this.fileUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.parsedData,
  });

  factory Resume.fromJson(Map<String, dynamic> json) {
    return Resume(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      fileUrl: json['file_url'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      status: ResumeStatus.fromString(json['status'] ?? 'draft'),
      parsedData: json['parsed_data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status.value,
      'parsed_data': parsedData,
    };
  }

  Resume copyWith({
    String? id,
    String? title,
    String? description,
    String? fileUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    ResumeStatus? status,
    Map<String, dynamic>? parsedData,
  }) {
    return Resume(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      fileUrl: fileUrl ?? this.fileUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      parsedData: parsedData ?? this.parsedData,
    );
  }
}

enum ResumeStatus {
  draft('draft'),
  uploaded('uploaded'),
  parsed('parsed'),
  optimized('optimized'),
  published('published');

  final String value;
  const ResumeStatus(this.value);

  static ResumeStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'uploaded':
        return ResumeStatus.uploaded;
      case 'parsed':
        return ResumeStatus.parsed;
      case 'optimized':
        return ResumeStatus.optimized;
      case 'published':
        return ResumeStatus.published;
      default:
        return ResumeStatus.draft;
    }
  }
}
