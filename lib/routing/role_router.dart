import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/admin_screen.dart';
import '../screens/cashier_screen.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  Future<String> getRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    if (!doc.exists) {
      throw Exception("User document does not exist for UID: $uid");
    }

    if (!doc.data()!.containsKey("role")) {
      throw Exception("Role field missing in user document");
    }

    return doc["role"];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getRole(),
      builder: (context, snapshot) {
        // ⏳ Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Verifying role...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        // ❌ ERROR
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      "Access Error",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // ✅ SUCCESS
        final role = snapshot.data;

        if (role == "admin") {
          return const AdminScreen();
        } else if (role == "cashier") {
          return const CashierScreen();
        } else {
          return const Scaffold(
            body: Center(child: Text("Unknown role")),
          );
        }
      },
    );
  }
}
