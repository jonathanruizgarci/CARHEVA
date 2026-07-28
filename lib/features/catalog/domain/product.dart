enum ProductType { generico, formula }

enum ProductStatus { activo, descontinuado }

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.stock,
    this.categoryId,
    this.brand,
    this.unitsPerBox,
    this.status = ProductStatus.activo,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? categoryId;
  final ProductType type;
  final String? brand;
  final double price;
  final int stock;
  final int? unitsPerBox;
  final ProductStatus status;
  final String? imageUrl;
}
