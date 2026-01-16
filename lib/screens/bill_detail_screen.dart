import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/bill_helper.dart';
import '../widgets/receipt_container.dart';

class BillDetailScreen extends StatelessWidget {
  final Map<String, dynamic> billData;
  final String customerName;

  const BillDetailScreen({
    super.key,
    required this.billData,
    required this.customerName,
  });

  void shareBill() {
    final List<dynamic> rawItems = billData["items"] ?? [];
    final List<Map<String, dynamic>> items = rawItems
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final text = BillHelper.generateBillText(
      customerName: customerName,
      items: items,
      total: billData["total"],
    );
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = billData["createdAt"] as Timestamp;
    final date = DateFormat("dd MMM yyyy, hh:mm a").format(timestamp.toDate());
    final total = billData["total"];
    final List<dynamic> items = billData["items"] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bill Details"),
        actions: [
          IconButton(
            onPressed: shareBill,
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ℹ️ INFO CARD
            ReceiptContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabelValue("Customer", customerName),
                  const SizedBox(height: 12),
                  _buildLabelValue("Date", date),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Amount",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "₹ $total",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 🛒 ITEMS LIST
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Items",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  elevation: 0,
                  color: Colors.grey.shade50,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(item["name"], style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text("${item["quantity"]} x ₹${item["price"]}"),
                    trailing: Text(
                      "₹ ${item["lineTotal"]}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
