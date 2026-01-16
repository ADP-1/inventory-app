import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'bills_screen.dart';
import 'products_screen.dart';
import 'customers_screen.dart';
import 'new_bill_screen.dart';
import 'add_product_screen.dart';
import 'new_bill_customer_screen.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? "Bills"
              : _currentIndex == 1
                  ? "Products"
                  : "Customers",
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),

      // 🔄 SWIPEABLE PAGES
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          BillsScreen(isAdmin: false),
          ProductsScreen(isAdmin: false),
          CustomersScreen(isAdmin: false),
        ],
      ),

      // 🔘 PERSISTENT BOTTOM ACTION BAR
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              _BottomActionButton(
                label: "Bills",
                icon: Icons.receipt_long,
                isActive: _currentIndex == 0,
                onTap: () => _goToPage(0),
                onLongPress: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NewBillScreen(),
                    ),
                  );
                },
              ),
              _BottomActionButton(
                label: "Products",
                icon: Icons.inventory_2,
                isActive: _currentIndex == 1,
                onTap: () => _goToPage(1),
                onLongPress: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddProductScreen(),
                    ),
                  );
                },
              ),
              _BottomActionButton(
                label: "Customers",
                icon: Icons.person,
                isActive: _currentIndex == 2,
                onTap: () => _goToPage(2),
                onLongPress: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NewBillCustomerScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// 🔘 CUSTOM BOTTOM BUTTON
// ------------------------------------------------------------
class _BottomActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BottomActionButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.black : Colors.grey;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isActive ? Colors.grey.shade200 : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
