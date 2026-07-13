class ServiceModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final double? defaultPrice;
  final int durationMinutes;
  final int? defaultDurationMin;
  final int? defaultBufferMin;

  ServiceModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.defaultPrice,
    required this.durationMinutes,
    this.defaultDurationMin,
    this.defaultBufferMin,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      defaultPrice: json['default_price'] != null ? (json['default_price'] as num).toDouble() : null,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      defaultDurationMin: (json['default_duration_minutes'] as num?)?.toInt(),
      defaultBufferMin: (json['default_buffer_minutes'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'default_price': defaultPrice,
      'duration_minutes': durationMinutes,
      'default_duration_minutes': defaultDurationMin,
      'default_buffer_minutes': defaultBufferMin,
    };
  }
}
