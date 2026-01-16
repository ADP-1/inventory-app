import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';

class NewBillItemsScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const NewBillItemsScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<NewBillItemsScreen> createState() => _NewBillItemsScreenState();
}

class _NewBillItemsScreenState extends State<NewBillItemsScreen> {
  final List<Map<String, dynamic>> items = [];
  final TextEditingController searchController = TextEditingController();

  bool isProcessingScan = false;

  // ---------- TOTAL ----------
  int get total =>
      items.fold(0, (sum, item) => sum + (item["lineTotal"] as int));

  // ---------- CORE ADD LOGIC ----------
  void addOrIncrementItem({
    required String productId,
    required String name,
    required int price,
  }) {
    final index =
        items.indexWhere((item) => item["productId"] == productId);

    setState(() {
      if (index >= 0) {
        items[index]["quantity"] += 1;
        items[index]["lineTotal"] =
            items[index]["quantity"] * items[index]["price"];
      } else {
        items.add({
          "productId": productId,
          "name": name,
          "price": price,
          "quantity": 1,
          "lineTotal": price,
        });
      }
    });

    // 🔊 Beep
    SystemSound.play(SystemSoundType.click);
  }

  // ---------- ADD BY BARCODE ----------
  Future<void> addItemByBarcode(String barcode) async {
    final query = await FirebaseFirestore.instance
        .collection("products")
        .where("barcode", isEqualTo: barcode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product not found")),
      );
      return;
    }

    final product = query.docs.first;

    addOrIncrementItem(
      productId: product.id,
      name: product["name"],
      price: product["price"],
    );
  }

  // ---------- ADD BY NAME ----------
  Future<void> addItemByName(String name) async {
    final query = await FirebaseFirestore.instance
        .collection("products")
        .where("name", isGreaterThanOrEqualTo: name)
        .where("name", isLessThanOrEqualTo: "$name\uf8ff")
        .limit(2)
        .get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product not found")),
      );
      return;
    }

    if (query.docs.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Multiple products found, refine name")),
      );
      return;
    }

    final product = query.docs.first;

    addOrIncrementItem(
      productId: product.id,
      name: product["name"],
      price: product["price"],
    );

    searchController.clear();
  }

  // ---------- SAVE BILL ----------
  Future<void> saveBill() async {
    if (items.isEmpty) return;

    await FirebaseFirestore.instance.collection("bills").add({
      "customerId": widget.customerId,
      "items": items,
      "total": total,
      "createdAt": FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  // ---------- CONTINUOUS SCANNER ----------
  Widget buildScanner() {
    return SizedBox(
      height: 240,
      child: MobileScanner(
        fit: BoxFit.cover,
        onDetect: (barcodeCapture) async {
          if (isProcessingScan) return;

          final barcode = barcodeCapture.barcodes.first.rawValue;
          if (barcode == null) return;

          isProcessingScan = true;
          await addItemByBarcode(barcode);

          await Future.delayed(const Duration(milliseconds: 700));
          isProcessingScan = false;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New Bill • ${widget.customerName}"),
      ),
      body: Column(
        children: [
          // 📷 Scanner always ON
          buildScanner(),

          // 🔍 Search by name
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: "Search product by name",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  addItemByName(value.trim());
                }
              },
            ),
          ),

          // 🧾 Items list
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text("Scan or search items"))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return ListTile(
                        title: Text(item["name"]),
                        subtitle: Text("₹ ${item["price"]}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  if (item["quantity"] > 1) {
                                    item["quantity"] -= 1;
                                    item["lineTotal"] =
                                        item["quantity"] *
                                            item["price"];
                                  }
                                });
                              },
                            ),
                            Text("${item["quantity"]}"),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  item["quantity"] += 1;
                                  item["lineTotal"] =
                                      item["quantity"] *
                                          item["price"];
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 💰 Total + Save
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border:
                  Border(top: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: ₹ $total",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: saveBill,
                  child: const Text("Save Bill"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
