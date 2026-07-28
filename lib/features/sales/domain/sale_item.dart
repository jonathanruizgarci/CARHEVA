class SaleItem {
  const SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  final String id;
  final String saleId;
  final String productId;
  final int quantity;
  final double unitPrice;

  double get subtotal => unitPrice * quantity;
}
