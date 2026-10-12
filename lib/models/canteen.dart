class CanteenModel {
  final String id;
  final String name;
  final String code;
  final String collegeName;
  final String location;
  final String status;

  CanteenModel({
    required this.id,
    required this.name,
    required this.code,
    required this.collegeName,
    required this.location,
    required this.status,
  });

  factory CanteenModel.fromJson(Map<String, dynamic> json) {
    return CanteenModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      collegeName: json['collegeName'] ?? 'Campus',
      location: json['location'] ?? 'Main Block',
      status: json['status'] ?? 'ACTIVE',
    );
  }
}
