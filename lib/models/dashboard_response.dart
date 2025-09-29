class DashboardResponse {
  DashboardResponse({String? status, String? message, Data? data}) {
    _status = status;
    _message = message;
    _data = data;
  }

  DashboardResponse.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  String? _status;
  String? _message;
  Data? _data;

  String? get status => _status;

  String? get message => _message;

  Data? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}

class Data {
  Data({ItemCount? itemCount, List<Items>? items}) {
    _itemCount = itemCount;
    _items = items;
  }

  Data.fromJson(dynamic json) {
    _itemCount = json['itemCount'] != null
        ? ItemCount.fromJson(json['itemCount'])
        : null;
    if (json['items'] != null) {
      _items = [];
      json['items'].forEach((v) {
        _items?.add(Items.fromJson(v));
      });
    }
  }

  ItemCount? _itemCount;
  List<Items>? _items;

  ItemCount? get itemCount => _itemCount;

  List<Items>? get items => _items;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_itemCount != null) {
      map['itemCount'] = _itemCount?.toJson();
    }
    if (_items != null) {
      map['items'] = _items?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Items {
  Items({
    int? id,
    String? type,
    String? title,
    String? subTitle,
    String? companyName,
    String? activityTypeDisplay,
    Metadata? metadata,
    String? createdAt,
    String? updatedAt,
    String? timestamp,
  }) {
    _id = id;
    _type = type;
    _title = title;
    _subTitle = subTitle;
    _companyName = companyName;
    _activityTypeDisplay = activityTypeDisplay;
    _metadata = metadata;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _timestamp = timestamp;
  }

  Items.fromJson(dynamic json) {
    _id = json['id'];
    _type = json['type'];
    _title = json['title'];
    _subTitle = json['sub_title'];
    _companyName = json['company_name'];
    _activityTypeDisplay = json['activity_type_display'];
    _metadata = json['metadata'] != null
        ? Metadata.fromJson(json['metadata'])
        : null;
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _timestamp = json['timestamp'];
  }

  int? _id;
  String? _type;
  String? _title;
  String? _subTitle;
  String? _companyName;
  String? _activityTypeDisplay;
  Metadata? _metadata;
  String? _createdAt;
  String? _updatedAt;
  String? _timestamp;

  int? get id => _id;

  String? get type => _type;

  String? get title => _title;

  String? get subTitle => _subTitle;

  String? get companyName => _companyName;

  String? get activityTypeDisplay => _activityTypeDisplay;

  Metadata? get metadata => _metadata;

  String? get createdAt => _createdAt;

  String? get updatedAt => _updatedAt;

  String? get timestamp => _timestamp;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['type'] = _type;
    map['title'] = _title;
    map['sub_title'] = _subTitle;
    map['company_name'] = _companyName;
    map['activity_type_display'] = _activityTypeDisplay;
    if (_metadata != null) {
      map['metadata'] = _metadata?.toJson();
    }
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    map['timestamp'] = _timestamp;
    return map;
  }
}

class Metadata {
  Metadata({
    String? action,
    String? status,
    String? companyName,
    int? interviewId,
    int? topicsCount,
    String? interviewDate,
    String? interviewType,
    String? positionTitle,
    int? questionsCount,
    int? strengthsCount,
    bool? signalTriggered,
    int? weaknessesCount,
    int? actionItemsCount,
  }) {
    _action = action;
    _status = status;
    _companyName = companyName;
    _interviewId = interviewId;
    _topicsCount = topicsCount;
    _interviewDate = interviewDate;
    _interviewType = interviewType;
    _positionTitle = positionTitle;
    _questionsCount = questionsCount;
    _strengthsCount = strengthsCount;
    _signalTriggered = signalTriggered;
    _weaknessesCount = weaknessesCount;
    _actionItemsCount = actionItemsCount;
  }

  Metadata.fromJson(dynamic json) {
    _action = json['action'];
    _status = json['status'];
    _companyName = json['company_name'];
    _interviewId = json['interview_id'];
    _topicsCount = json['topics_count'];
    _interviewDate = json['interview_date'];
    _interviewType = json['interview_type'];
    _positionTitle = json['position_title'];
    _questionsCount = json['questions_count'];
    _strengthsCount = json['strengths_count'];
    _signalTriggered = json['signal_triggered'];
    _weaknessesCount = json['weaknesses_count'];
    _actionItemsCount = json['action_items_count'];
  }

  String? _action;
  String? _status;
  String? _companyName;
  int? _interviewId;
  int? _topicsCount;
  String? _interviewDate;
  String? _interviewType;
  String? _positionTitle;
  int? _questionsCount;
  int? _strengthsCount;
  bool? _signalTriggered;
  int? _weaknessesCount;
  int? _actionItemsCount;

  String? get action => _action;

  String? get status => _status;

  String? get companyName => _companyName;

  int? get interviewId => _interviewId;

  int? get topicsCount => _topicsCount;

  String? get interviewDate => _interviewDate;

  String? get interviewType => _interviewType;

  String? get positionTitle => _positionTitle;

  int? get questionsCount => _questionsCount;

  int? get strengthsCount => _strengthsCount;

  bool? get signalTriggered => _signalTriggered;

  int? get weaknessesCount => _weaknessesCount;

  int? get actionItemsCount => _actionItemsCount;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['action'] = _action;
    map['status'] = _status;
    map['company_name'] = _companyName;
    map['interview_id'] = _interviewId;
    map['topics_count'] = _topicsCount;
    map['interview_date'] = _interviewDate;
    map['interview_type'] = _interviewType;
    map['position_title'] = _positionTitle;
    map['questions_count'] = _questionsCount;
    map['strengths_count'] = _strengthsCount;
    map['signal_triggered'] = _signalTriggered;
    map['weaknesses_count'] = _weaknessesCount;
    map['action_items_count'] = _actionItemsCount;
    return map;
  }
}

class ItemCount {
  ItemCount({
    int? totalResumes,
    int? totalInterviews,
    dynamic filterApplied,
    String? filterDescription,
    int? activitiesCount,
  }) {
    _totalResumes = totalResumes;
    _totalInterviews = totalInterviews;
    _filterApplied = filterApplied;
    _filterDescription = filterDescription;
    _activitiesCount = activitiesCount;
  }

  ItemCount.fromJson(dynamic json) {
    _totalResumes = json['total_resumes'];
    _totalInterviews = json['total_interviews'];
    _filterApplied = json['filter_applied'];
    _filterDescription = json['filter_description'];
    _activitiesCount = json['activities_count'];
  }

  int? _totalResumes;
  int? _totalInterviews;
  dynamic _filterApplied;
  String? _filterDescription;
  int? _activitiesCount;

  int? get totalResumes => _totalResumes;

  int? get totalInterviews => _totalInterviews;

  dynamic get filterApplied => _filterApplied;

  String? get filterDescription => _filterDescription;

  int? get activitiesCount => _activitiesCount;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['total_resumes'] = _totalResumes;
    map['total_interviews'] = _totalInterviews;
    map['filter_applied'] = _filterApplied;
    map['filter_description'] = _filterDescription;
    map['activities_count'] = _activitiesCount;
    return map;
  }
}
