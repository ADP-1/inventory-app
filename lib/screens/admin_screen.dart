import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'bills_screen.dart';
import 'products_screen.dart';
import 'customers_screen.dart';
import 'new_bill_screen.dart';
import 'add_product_screen.dart';
import 'new_bill_customer_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
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
          BillsScreen(isAdmin: true),
          ProductsScreen(isAdmin: true),
          CustomersScreen(isAdmin: true),
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomActionButton(
                label: "Bills",
                icon: Icons.receipt_long_rounded,
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
                icon: Icons.inventory_2_rounded,
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
                icon: Icons.people_alt_rounded,
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
    final theme = Theme.of(context);
    final color = isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withAlpha(100);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isActive ? theme.colorScheme.primary.withAlpha(20) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
