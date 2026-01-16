import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/customer_selector_sheet.dart';
import '../widgets/item_selector_sheet.dart';
import '../widgets/receipt_container.dart';
import '../widgets/bill_item_row.dart';
import '../utils/bill_helper.dart';

class NewBillScreen extends StatefulWidget {
  const NewBillScreen({super.key});

  @override
  State<NewBillScreen> createState() => _NewBillScreenState();
}

class _NewBillScreenState extends State<NewBillScreen> {
  // ---------------- CUSTOMER ----------------
  String? customerId;
  String? customerName;

  // ---------------- ITEMS ----------------
  final List<Map<String, dynamic>> items = [];
  bool isProcessingScan = false;

  // ---------------- SOUND ----------------
  final AudioPlayer beepPlayer = AudioPlayer();

  // ---------------- TOTAL ----------------
  int get total => items.fold(0, (sum, item) => sum + (item["lineTotal"] as int));

  void _editQuantityDialog(Map<String, dynamic> item) {
    final controller = TextEditingController(text: item["quantity"].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Quantity"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Enter quantity",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);

              if (value == null || value <= 0) return;

              setState(() {
                item["quantity"] = value;
                item["lineTotal"] = value * (item["price"] as int);
              });

              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ---------------- ADD / UPDATE ITEM ----------------
  void addOrIncrementItem({
    required String productId,
    required String name,
    required int price,
    bool vibrate = false,
  }) {
    final index = items.indexWhere((item) => item["productId"] == productId);

    setState(() {
      if (index >= 0) {
        items[index]["quantity"] += 1;
        items[index]["lineTotal"] = items[index]["quantity"] * price;
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

    if (vibrate) {
      HapticFeedback.selectionClick();
    }
  }

  void decrementOrRemoveItem(int index) {
      final item = items[index];
      setState(() {
        if (item["quantity"] > 1) {
          item["quantity"] -= 1;
          item["lineTotal"] = item["quantity"] * (item["price"] as int);
        } else {
          items.removeAt(index);
        }
      });
      HapticFeedback.selectionClick();
  }

  // ---------------- BARCODE SCAN (BEEP ONLY HERE) ----------------
  Future<void> addItemByBarcode(String barcode) async {
    try {
        final query = await FirebaseFirestore.instance
            .collection("products")
            .where("barcode", isEqualTo: barcode)
            .limit(1)
            .get();

        if (query.docs.isEmpty) return;

        final product = query.docs.first;

        addOrIncrementItem(
        productId: product.id,
        name: product["name"],
        price: product["price"],
        );

        // 🔊 Beep ONLY on successful scan
        await beepPlayer.play(AssetSource('sounds/beep.mp3'));
    } catch (e) {
        debugPrint("Scan error: $e");
    }
  }

  void shareBill() {
    final text = BillHelper.generateBillText(
        customerName: customerName,
        items: items,
        total: total,
    );
    Share.share(text);
  }

  // ---------------- SAVE BILL ----------------
  Future<void> saveBill() async {
    if (items.isEmpty || customerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please select a customer and add items.")),
        );
        return;
    }

    try {
        await FirebaseFirestore.instance.collection("bills").add({
        "customerId": customerId,
        "items": items,
        "total": total,
        "createdAt": FieldValue.serverTimestamp(),
        });

        if (mounted) Navigator.pop(context);
    } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error saving bill: $e")),
            );
        }
    }
  }

  // ---------------- CUSTOMER SELECTOR ----------------
  void openCustomerSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CustomerSelectorSheet(
        onSelect: (id, name) {
          setState(() {
            customerId = id;
            customerName = name;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  // ---------------- ITEM SELECTOR ----------------
  void openItemSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ItemSelectorSheet(
        onSelect: (product) {
          addOrIncrementItem(
            productId: product.id,
            name: product["name"],
            price: product["price"],
            vibrate: true,
          );
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    beepPlayer.dispose();
    super.dispose();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Bill")),
      body: Column(
        children: [
          // 🧾 SHOP HEADER
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              "GOYAL TRADERS",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 👤 CUSTOMER HEADER
          GestureDetector(
            onTap: openCustomerSelector,
            child: ReceiptContainer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Customer",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customerName ?? "Select customer",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ),
          ),

          // 📷 SCANNER
          SizedBox(
            height: 200,
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
           ),

          // ➕ ADD ITEM (OPENS ITEM SELECTOR)
          Padding(
            padding: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: openItemSelector,
              child: AbsorbPointer(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Search or add item",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
          ),

          // 🧾 BILL ITEMS
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text("Scan items to add"))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return BillItemRow(
                          item: item,
                          onIncrement: () => addOrIncrementItem(
                              productId: item["productId"],
                              name: item["name"],
                              price: item["price"],
                              vibrate: true,
                          ),
                          onDecrement: () => decrementOrRemoveItem(index),
                          onEditQuantity: () => _editQuantityDialog(item),
                      );
                    },
                  ),
          ),

          // 💰 TOTAL + SAVE
          ReceiptContainer(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "TOTAL",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "₹ $total",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: total > 0 && customerId != null ? saveBill : null,
                        child: const Text("SAVE"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.share),
                        label: const Text("SHARE"),
                        onPressed: items.isEmpty ? null : shareBill,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

