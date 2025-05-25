// lib/admin_shell.dart

import 'package:flutter/material.dart';
import 'admin_dashboard_page.dart';           // provides DashboardBody
import 'admin_menu_management_page.dart';    // provides MenuBody
import 'admin_order_management_page.dart';   // provides GrabGoOrdersBody
import 'admin_reservation_management_page.dart'; // provides ReservationsBody

const Color _navBg = Colors.white;
const Color _navActive = Color(0xFFFF8C00);
const Color _navInactive = Colors.grey;

class AdminShell extends StatefulWidget {
  /// Pass the restaurantId once, then all child pages share it.
  final String restaurantId;
  const AdminShell({required this.restaurantId, Key? key}) : super(key: key);

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  /// These are your **body** widgets, not full Scaffolds
  late final List<Widget> _pages = [
    DashboardBody(restaurantId: widget.restaurantId),
    MenuBody(restaurantId: widget.restaurantId),
    GrabGoOrdersBody(restaurantId: widget.restaurantId),
    ReservationsBody(restaurantId: widget.restaurantId),
  ];

  final _labels = ['Dashboard', 'Menu', 'Grab & Go', 'Reservations'];
  final _icons = [
    Icons.dashboard,
    Icons.restaurant_menu,
    Icons.shopping_bag,
    Icons.event
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      appBar: AppBar(
        title: Text(_labels[_currentIndex],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _navActive,
        elevation: 0,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: _navBg,
        currentIndex: _currentIndex,
        selectedItemColor: _navActive,
        unselectedItemColor: _navInactive,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: List.generate(_pages.length, (i) {
          return BottomNavigationBarItem(
            icon: Icon(_icons[i]),
            label: _labels[i],
          );
        }),
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
