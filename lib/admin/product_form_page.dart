import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/store_data.dart';
import '../models/product.dart';
import '../shared/app_theme.dart';
import '../shared/widgets.dart';
import 'barcode_scanner_page.dart';

class ProductFormPage extends StatefulWidget {
  final Product? product;

  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController brandController;
  late final TextEditingController priceController;
  late final TextEditingController stockController;
  late final TextEditingController barcodeController;
  late final TextEditingController descriptionController;
  late final TextEditingController categoryController;
  final ImagePicker imagePicker = ImagePicker();

  Uint8List? selectedImageBytes;
  String existingImageData = '';

  bool saving = false;

  @override
  void initState() {
    super.initState();

    final product = widget.product;
    existingImageData = product?.imageUrl ?? '';
    nameController = TextEditingController(text: product?.name ?? '');
    brandController = TextEditingController(text: product?.brand ?? '');
    priceController = TextEditingController(
      text: product == null ? '' : product.price.toString(),
    );
    stockController = TextEditingController(
      text: product == null ? '' : product.stock.toString(),
    );
    barcodeController = TextEditingController(text: product?.barcode ?? '');
    descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    categoryController = TextEditingController(
      text: product?.category ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    brandController.dispose();
    priceController.dispose();
    stockController.dispose();
    barcodeController.dispose();
    descriptionController.dispose();
    categoryController.dispose();

    super.dispose();
  }

  Future<void> saveProduct() async {
    if (saving || !mounted) return;

    FocusManager.instance.primaryFocus?.unfocus();

    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() => saving = true);

    final existing = widget.product;

    try {
      final product = Product(
        id: existing?.id ?? 'P${DateTime.now().microsecondsSinceEpoch}',
        name: nameController.text.trim(),
        brand: brandController.text.trim(),
        price: double.parse(priceController.text.trim()),
        stock: int.parse(stockController.text.trim()),
        barcode: barcodeController.text.trim(),
        description: descriptionController.text.trim(),
        category: categoryController.text.trim(),
        imageUrl: selectedImageBytes != null
            ? 'data:image/jpeg;base64,${base64Encode(selectedImageBytes!)}'
            : (existing?.imageUrl ?? ''),
      );

      if (existing == null) {
        await StoreData.instance.addProduct(product);
      } else {
        await StoreData.instance.updateProduct(product);
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      debugPrint('Error saving product: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() => saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save product: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> pickProductImage() async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 60,
      );

      if (image == null) return;

      final Uint8List bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        selectedImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to select image: $e')),
      );
    }
  }

  Future<void> scanBarcode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );

    if (code == null || !mounted) return;

    setState(() => barcodeController.text = code);
  }

  Widget buildImagePreview() {
    final String savedImage = existingImageData;

    Widget imageContent;

    if (selectedImageBytes != null) {
      imageContent = Image.memory(
        selectedImageBytes!,
        fit: BoxFit.contain,
        width: double.infinity,
        height: 170,
      );
    } else if (savedImage.startsWith('data:image/')) {
      try {
        final String encodedImage = savedImage.split(',').last;

        imageContent = Image.memory(
          base64Decode(encodedImage),
          fit: BoxFit.contain,
          width: double.infinity,
          height: 170,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image_outlined, size: 55);
          },
        );
      } catch (_) {
        imageContent = const Icon(
          Icons.add_photo_alternate_outlined,
          size: 55,
        );
      }
    } else {
      imageContent = const Icon(
        Icons.add_photo_alternate_outlined,
        size: 55,
      );
    }

    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Add Product' : 'Edit Product',
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            buildImagePreview(),

            const SizedBox(height: 14),

            OutlinedButton.icon(
              onPressed: pickProductImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose Image from Gallery'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            if (selectedImageBytes != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      selectedImageBytes = null;
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove Selected Image'),
                ),
              ),

            const SizedBox(height: 20),

            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                hintText: 'e.g. Bottled Water',
                prefixIcon: Icon(Icons.inventory_2_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a product name';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: brandController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Brand',
                hintText: 'e.g. Nature Spring',
                prefixIcon: Icon(Icons.business_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: categoryController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'e.g. Beverages, Snacks, Canned Goods',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a product category';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Product Description',
                hintText: 'Enter product details',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: priceController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price (₱)',
                prefixIcon: Icon(Icons.payments_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final price = double.tryParse(value ?? '');

                if (price == null || !price.isFinite || price < 0) {
                  return 'Enter a valid price';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock Quantity',
                prefixIcon: Icon(Icons.warehouse_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final stock = int.tryParse(value ?? '');

                if (stock == null || stock < 0) {
                  return 'Enter a valid whole number';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // BARCODE (type it or scan it)
            TextFormField(
              controller: barcodeController,
              decoration: InputDecoration(
                labelText: 'Barcode (optional)',
                hintText: 'Type or scan a barcode',
                prefixIcon: const Icon(Icons.qr_code_scanner),
                suffixIcon: IconButton(
                  tooltip: 'Scan barcode',
                  icon: const Icon(Icons.camera_alt_outlined),
                  onPressed: scanBarcode,
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                final code = value?.trim() ?? '';
                if (code.isEmpty) return null;

                final found = StoreData.instance.findByBarcode(code);
                if (found != null && found.id != widget.product?.id) {
                  return 'Barcode already used by "${found.name}"';
                }
                return null;
              },
            ),

            const SizedBox(height: 25),

            AppButton(
              text: saving ? 'Saving...' : 'Save Product',
              icon: Icons.save_outlined,
              onPressed: saving ? () {} : saveProduct,
            ),
          ],
        ),
      ),
    );
  }
}