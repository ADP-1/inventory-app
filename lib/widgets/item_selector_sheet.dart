import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemSelectorSheet extends StatefulWidget {
  final Function(QueryDocumentSnapshot product) onSelect;

  const ItemSelectorSheet({super.key, required this.onSelect});

  @override
  State<ItemSelectorSheet> createState() =>
      _ItemSelectorSheetState();
}

class _ItemSelectorSheetState extends State<ItemSelectorSheet> {
  final searchController = TextEditingController();
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              "Select Item",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: "Search item name",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() => searchText = value.toLowerCase());
                },
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("products")
                    .orderBy("name")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final products = snapshot.data!.docs.where((doc) {
                    final name =
                        doc["name"].toString().toLowerCase();
                    return name.contains(searchText);
                  }).toList();

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];

                      return ListTile(
                        title: Text(product["name"]),
                        subtitle: Text("₹ ${product["price"]}"),
                        onTap: () => widget.onSelect(product),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
