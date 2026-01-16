import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final barcodeController = TextEditingController();
  final nameController = TextEditingController();
  final priceController = TextEditingController();

  bool showScanner = true;
  bool isProcessingScan = false;
  bool barcodeExists = false;

  // ---------- CHECK BARCODE ----------
  Future<void> checkBarcode(String barcode) async {
    final query = await FirebaseFirestore.instance
        .collection("products")
        .where("barcode", isEqualTo: barcode)
        .limit(1)
        .get();

    setState(() {
      barcodeExists = query.docs.isNotEmpty;
    });
  }

  // ---------- SAVE PRODUCT ----------
  Future<void> saveProduct() async {
    if (barcodeExists) return;

    if (barcodeController.text.isEmpty ||
        nameController.text.isEmpty ||
        priceController.text.isEmpty) {
      return;
    }

    await FirebaseFirestore.instance.collection("products").add({
      "barcode": barcodeController.text.trim(),
      "name": nameController.text.trim(),
      "price": int.parse(priceController.text.trim()),
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  // ---------- SCANNER ----------
  Widget buildScanner() {
    return SizedBox(
      height: 220,
      child: MobileScanner(
        fit: BoxFit.cover,
        onDetect: (barcodeCapture) async {
          if (isProcessingScan) return;

          final barcode =
              barcodeCapture.barcodes.first.rawValue;
          if (barcode == null) return;

          isProcessingScan = true;

          barcodeController.text = barcode;
          await checkBarcode(barcode);

          setState(() {
            showScanner = false;
          });

          await Future.delayed(const Duration(milliseconds: 800));
          isProcessingScan = false;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Product")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📷 Scanner
            if (showScanner) buildScanner(),

            // 🔢 Barcode
            TextField(
              controller: barcodeController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Barcode",
                suffixIcon: barcodeExists
                    ? const Icon(Icons.error, color: Colors.red)
                    : const Icon(Icons.check, color: Colors.green),
              ),
            ),

            if (barcodeExists)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "Product with this barcode already exists",
                  style: TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 16),

            // 🏷 Name
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: "Product Name"),
              enabled: !barcodeExists,
            ),

            // 💰 Price
            TextField(
              controller: priceController,
              decoration:
                  const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
              enabled: !barcodeExists,
            ),

            const SizedBox(height: 24),

            // 💾 Save
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: barcodeExists ? null : saveProduct,
                child: const Text("Save Product"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
