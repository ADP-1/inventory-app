import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../widgets/receipt_container.dart';

import 'add_product_screen.dart';

class ProductsScreen extends StatelessWidget {
  final bool isAdmin;
  const ProductsScreen({super.key, this.isAdmin = false});

  void _showEditBottomSheet(BuildContext context, DocumentSnapshot product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _EditProductBottomSheet(product: product, isAdmin: isAdmin),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: "New Product",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("products")
            .orderBy("name")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!.docs;

          if (products.isEmpty) {
            return const Center(child: Text("No products found"));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              return GestureDetector(
                onTap: () => _showEditBottomSheet(context, product),
                child: ReceiptContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product["name"],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "₹ ${product["price"]}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Barcode: ${product["barcode"]}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EditProductBottomSheet extends StatefulWidget {
  final DocumentSnapshot product;

  final bool isAdmin;

  const _EditProductBottomSheet({required this.product, required this.isAdmin});

  @override
  State<_EditProductBottomSheet> createState() => _EditProductBottomSheetState();
}

class _EditProductBottomSheetState extends State<_EditProductBottomSheet> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController barcodeController;
  MobileScannerController? cameraController;
  
  bool isSaving = false;
  bool showScanner = false;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product["name"]);
    priceController = TextEditingController(text: widget.product["price"].toString());
    barcodeController = TextEditingController(text: widget.product["barcode"]);
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    barcodeController.dispose();
    cameraController?.dispose();
    super.dispose();
  }

  void _toggleScanner() {
    setState(() {
      showScanner = !showScanner;
      if (showScanner) {
        cameraController = MobileScannerController();
      } else {
        cameraController?.dispose();
        cameraController = null;
      }
    });
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product?"),
        content: Text("Are you sure you want to delete '${widget.product["name"]}'? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              setState(() => isSaving = true);
              try {
                await FirebaseFirestore.instance
                    .collection("products")
                    .doc(widget.product.id)
                    .delete();
                if (mounted) {
                  Navigator.pop(context); // Close bottom sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Product deleted successfully")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() => isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error deleting: $e")),
                  );
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 📷 SCANNER WIDGET
          if (showScanner && cameraController != null)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).primaryColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  controller: cameraController!,
                  onDetect: (capture) {
                    if (isProcessing) return;
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                      setState(() {
                        isProcessing = true;
                        barcodeController.text = barcodes.first.rawValue!;
                        showScanner = false; // Hide scanner after scan
                        cameraController?.dispose();
                        cameraController = null;
                      });
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          setState(() => isProcessing = false);
                        }
                      });
                    }
                  },
                ),
              ),
            ),

          Text(
            "Edit Product",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "Product Name",
              prefixIcon: Icon(Icons.shopping_bag_outlined),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: "Price",
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: barcodeController,
                  decoration: InputDecoration(
                    labelText: "Barcode",
                    prefixIcon: const Icon(Icons.qr_code),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showScanner ? Icons.close : Icons.qr_code_scanner,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: _toggleScanner,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameController.text.isEmpty || priceController.text.isEmpty) return;

                      setState(() => isSaving = true);

                      try {
                        // Check for duplicate barcode
                        final barcode = barcodeController.text.trim();
                        if (barcode.isNotEmpty && barcode != widget.product["barcode"]) {
                          final query = await FirebaseFirestore.instance
                              .collection("products")
                              .where("barcode", isEqualTo: barcode)
                              .limit(1)
                              .get();

                          if (query.docs.isNotEmpty) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Error: This barcode already exists for another product."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              setState(() => isSaving = false);
                            }
                            return;
                          }
                        }

                        await FirebaseFirestore.instance
                            .collection("products")
                            .doc(widget.product.id)
                            .update({
                          "name": nameController.text.trim(),
                          "price": int.parse(priceController.text.trim()),
                          "barcode": barcode,
                          "updatedAt": FieldValue.serverTimestamp(),
                        });

                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                          setState(() => isSaving = false);
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text("Save Changes"),
            ),
          ),
          const SizedBox(height: 24),
          
          if (widget.isAdmin)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: TextButton.icon(
                onPressed: isSaving ? null : () => _confirmDelete(),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  "Delete Product",
                  style: TextStyle(color: Colors.red),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade100),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
