import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'new_bill_items_screen.dart';


class NewBillCustomerScreen extends StatefulWidget {
  const NewBillCustomerScreen({super.key});

  @override
  State<NewBillCustomerScreen> createState() =>
      _NewBillCustomerScreenState();
}

class _NewBillCustomerScreenState
    extends State<NewBillCustomerScreen> {
  final searchController = TextEditingController();

  String searchText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Customer"),
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search customer name or phone",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => searchText = value.toLowerCase());
              },
            ),
          ),

          // 👥 Customer List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("customers")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }

                final customers = snapshot.data!.docs.where((doc) {
                  final name =
                      doc["name"].toString().toLowerCase();
                  final phone =
                      doc["phone"].toString().toLowerCase();

                  return name.contains(searchText) ||
                      phone.contains(searchText);
                }).toList();

                if (customers.isEmpty) {
                  return const Center(
                    child: Text("No customers found"),
                  );
                }

                return ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];

                    return ListTile(
                      leading:
                          const Icon(Icons.person_outline),
                      title: Text(customer["name"]),
                      subtitle: Text(customer["phone"]),
                      onTap: () {
                        // 🔜 Next screen: items
                        Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => NewBillItemsScreen(
      customerId: customer.id,
      customerName: customer["name"],
    ),
  ),
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

      // ➕ Add Customer
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddCustomerDialog(context);
        },
        icon: const Icon(Icons.person_add),
        label: const Text("Add Customer"),
      ),
    );
  }

  // ---------- ADD CUSTOMER DIALOG ----------

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New Customer"),
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
                    phoneController.text.isEmpty) {
                  return;
                }

                final doc = await FirebaseFirestore.instance
                    .collection("customers")
                    .add({
                  "name": nameController.text.trim(),
                  "phone": phoneController.text.trim(),
                  "createdAt":
                      FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);

                // auto-select new customer
                Navigator.pop(context, {
                  "customerId": doc.id,
                  "customerName":
                      nameController.text.trim(),
                });
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
