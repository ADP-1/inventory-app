import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerService {
  // Singleton pattern
  static final CustomerService _instance = CustomerService._internal();
  static CustomerService get instance => _instance;

  CustomerService._internal();

  final ValueNotifier<List<QueryDocumentSnapshot>> customersNotifier = ValueNotifier([]);
  bool _initialized = false;
  bool hasData = false;

  void init() {
    if (_initialized) return;
    _initialized = true;

    FirebaseFirestore.instance
        .collection("customers")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .listen((snapshot) {
      hasData = true;
      customersNotifier.value = snapshot.docs;
    });
  }
}
