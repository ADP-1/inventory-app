import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/customer_service.dart';

class CustomerSelectorSheet extends StatefulWidget {
  final Function(String id, String name) onSelect;

  const CustomerSelectorSheet({super.key, required this.onSelect});

  @override
  State<CustomerSelectorSheet> createState() =>
      _CustomerSelectorSheetState();
}

class _CustomerSelectorSheetState
    extends State<CustomerSelectorSheet> {
  final searchController = TextEditingController();
  String searchText = "";

  @override
  void initState() {
    super.initState();
    // Ensure service is initialized (safe to call multiple times)
    CustomerService.instance.init();
  }

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
              "Select Customer",
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
                  hintText: "Search name or phone",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() => searchText = value.toLowerCase());
                },
              ),
            ),

            Expanded(
              child: ValueListenableBuilder<List<QueryDocumentSnapshot>>(
                valueListenable: CustomerService.instance.customersNotifier,
                builder: (context, docs, child) {
                  if (docs.isEmpty && !CustomerService.instance.hasData) {
                     // Check if it's actually loading for the generic first time
                     // However, since we init in initState, it might be empty briefly.
                     // But ValueNotifier init with [] is safe.
                     // A better check would be handling "loading" state in service, 
                     // but immediate empty list is better than spinner for "lag" perception if data exists.
                     // Let's just show list. If empty, it shows nothing or "no customers".
                  }
                  
                  final customers = docs.where((doc) {
                    final name = doc["name"].toString().toLowerCase();
                    final phone = doc["phone"].toString().toLowerCase();
                    return name.contains(searchText) ||
                        phone.contains(searchText);
                  }).toList();

                  return ListView.builder(
                    itemCount: customers.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ListTile(
                          leading: const Icon(Icons.person_add),
                          title: const Text("Add New Customer"),
                          onTap: () => _showAddCustomerDialog(context),
                        );
                      }

                      final customer = customers[index - 1];

                      return ListTile(
                        title: Text(customer["name"]),
                        subtitle: Text(customer["phone"]),
                        onTap: () {
                          widget.onSelect(
                            customer.id,
                            customer["name"],
                          );
                        },
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

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Customer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: phoneController,
              decoration:
                  const InputDecoration(labelText: "Phone"),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  phoneController.text.isEmpty) return;

              final doc = await FirebaseFirestore.instance
                  .collection("customers")
                  .add({
                "name": nameController.text.trim(),
                "phone": phoneController.text.trim(),
                "createdAt":
                    FieldValue.serverTimestamp(),
              });

              widget.onSelect(
                doc.id,
                nameController.text.trim(),
              );

              Navigator.of(context).pop(); // dialog
              // Navigator.of(context).pop(); // bottom sheet
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
