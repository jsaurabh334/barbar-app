class CategoryModel {
  final String id;
  final String name;
  final String? slug;
  final String? description;
  final String? image;
  final String? icon;

  CategoryModel({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.image,
    this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      image: json['image'] as String?,
      icon: json['icon'] as String?,
    );
  }
}
