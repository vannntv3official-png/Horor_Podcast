class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? iconName;
  final int sortOrder;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.iconName,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      iconName: json['icon_name'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon_name': iconName,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}
