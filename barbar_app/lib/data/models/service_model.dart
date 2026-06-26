class ServiceModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int durationMinutes;

  ServiceModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.durationMinutes,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'duration_minutes': durationMinutes,
    };
  }
}
