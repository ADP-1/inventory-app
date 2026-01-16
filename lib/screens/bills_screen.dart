import 'package:flutter/material.dart';
import '../widgets/bills_list.dart';
import 'new_bill_screen.dart';

class BillsScreen extends StatelessWidget {
  final bool isAdmin;
  const BillsScreen({super.key, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BillsList(isAdmin: isAdmin),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("New Bill"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NewBillScreen(),
            ),
          );
        },
      ),
    );
  }
}
