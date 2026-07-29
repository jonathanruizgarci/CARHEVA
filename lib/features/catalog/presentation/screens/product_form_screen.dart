import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/product.dart';
import '../providers/catalog_providers.dart';

/// Alta/edicion de un producto. Si [productId] es null es alta; si viene
/// con valor, precarga el producto existente para editarlo.
/// Requiere estar en linea (ver docs/plan_de_trabajo.md #3): solo el admin
/// puede llegar a esta pantalla en la practica (RLS lo exige del lado
/// servidor de todas formas).
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _unitsPerBoxController = TextEditingController();
  final _imageUrlController = TextEditingController();

  ProductType _type = ProductType.generico;
  String? _categoryId;
  bool _isSaving = false;
  bool _initialized = false;

  bool get _isEditing => widget.productId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _unitsPerBoxController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _prefillFrom(Product product) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = product.name;
    _brandController.text = product.brand ?? '';
    _priceController.text = product.price.toString();
    _stockController.text = product.stock.toString();
    _unitsPerBoxController.text = product.unitsPerBox?.toString() ?? '';
    _imageUrlController.text = product.imageUrl ?? '';
    _type = product.type;
    _categoryId = product.categoryId;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repository = ref.read(productRepositoryProvider);
      final name = _nameController.text.trim();
      final price = double.parse(_priceController.text);
      final stock = int.parse(_stockController.text);
      final unitsPerBox = _unitsPerBoxController.text.trim().isEmpty
          ? null
          : int.parse(_unitsPerBoxController.text);
      final brand =
          _brandController.text.trim().isEmpty ? null : _brandController.text.trim();
      final imageUrl = _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim();

      if (_isEditing) {
        await repository.updateProduct(
          id: widget.productId!,
          name: name,
          type: _type,
          price: price,
          stock: stock,
          categoryId: _categoryId,
          brand: brand,
          unitsPerBox: unitsPerBox,
          imageUrl: imageUrl,
        );
      } else {
        await repository.createProduct(
          name: name,
          type: _type,
          price: price,
          stock: stock,
          categoryId: _categoryId,
          brand: brand,
          unitsPerBox: unitsPerBox,
          imageUrl: imageUrl,
        );
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar (¿sin conexion?): $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    if (_isEditing) {
      final productsAsync = ref.watch(filteredProductsProvider);
      productsAsync.whenData((products) {
        final match = products.where((p) => p.id == widget.productId);
        if (match.isNotEmpty) _prefillFrom(match.first);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar producto' : 'Nuevo producto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(labelText: 'Marca (opcional)'),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ProductType>(
              segments: const [
                ButtonSegment(
                  value: ProductType.generico,
                  label: Text('Generico'),
                ),
                ButtonSegment(
                  value: ProductType.formula,
                  label: Text('De formula'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) =>
                  setState(() => _type = selection.first),
            ),
            const SizedBox(height: 12),
            categoriesAsync.when(
              data: (categories) => DropdownButtonFormField<String>(
                value: _categoryId,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Sin categoria')),
                  ...categories.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error cargando categorias: $e'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Precio'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  double.tryParse(v ?? '') == null ? 'Precio invalido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(labelText: 'Stock'),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  int.tryParse(v ?? '') == null ? 'Stock invalido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unitsPerBoxController,
              decoration:
                  const InputDecoration(labelText: 'Unidades por caja (opcional)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageUrlController,
              decoration:
                  const InputDecoration(labelText: 'URL de imagen (opcional)'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
