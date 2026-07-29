import 'package:flutter/material.dart';

import '../../domain/product.dart';

class ProductListTile extends StatelessWidget {
  const ProductListTile({super.key, required this.product, this.onTap});

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lowStock = product.stock <= 0;

    return ListTile(
      onTap: onTap,
      title: Text(product.name),
      subtitle: Text(
        product.type == ProductType.generico ? 'Generico' : 'De formula',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'Stock: ${product.stock}',
            style: TextStyle(
              color: lowStock ? Theme.of(context).colorScheme.error : null,
            ),
          ),
        ],
      ),
    );
  }
}
