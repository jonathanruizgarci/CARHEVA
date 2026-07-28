import 'sale_item.dart';

class Sale {
  const Sale({
    required this.id,
    required this.sellerId,
    required this.total,
    required this.createdAt,
    required this.items,
    this.clientId,
  });

  final String id;
  final String? clientId;
  final String sellerId;
  final double total;
  final DateTime createdAt;
  final List<SaleItem> items;
}
