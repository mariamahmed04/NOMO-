// lib/dashboard_body.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Theme constants (import from your shared styles if you’ve extracted them)
const Color kPrimary = Color(0xFFFF8C00);
const Color kTextSecondary = Color(0xFF777777);
const Color kSurface = Colors.white;
const Color kShadow = Color(0x22000000);

class DashboardBody extends StatelessWidget {
  final String restaurantId;
  const DashboardBody({required this.restaurantId, Key? key}) : super(key: key);

  Stream<QuerySnapshot> get _ordersStream => FirebaseFirestore.instance
      .collection('orders')
      .where('restaurant_id', isEqualTo: restaurantId)
      .snapshots();

  Stream<QuerySnapshot> get _reservationsStream => FirebaseFirestore.instance
      .collection('reservations')
      .where('restaurant_id', isEqualTo: restaurantId)
      .snapshots();

  Stream<QuerySnapshot> get _tablesStream => FirebaseFirestore.instance
      .collection('tables')
      .where('restaurant_id', isEqualTo: restaurantId)
      .snapshots();

  String _formatCurrency(double amount) => 'EGP ${amount.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<QuerySnapshot>(
        stream: _ordersStream,
        builder: (context, orderSnap) {
          if (!orderSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = orderSnap.data!.docs;
          final totalRevenue = orders
              .map((d) => (d['total_price'] as num? ?? 0).toDouble())
              .fold(0.0, (a, b) => a + b);
          final pendingCount = orders.where((d) => d['status'] == 'pending').length;

          return StreamBuilder<QuerySnapshot>(
            stream: _reservationsStream,
            builder: (context, resSnap) {
              if (!resSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final resDocs = resSnap.data!.docs;
              final todayCount = resDocs.where((d) {
                final ts = (d['reservation_time'] as Timestamp).toDate();
                return ts.isAfter(startOfDay) && ts.isBefore(endOfDay);
              }).length;

              return StreamBuilder<QuerySnapshot>(
                stream: _tablesStream,
                builder: (context, tableSnap) {
                  if (!tableSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final tables = tableSnap.data!.docs;
                  final availableCount =
                      tables.where((d) => d['status'] == 'available').length;

                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _StatCard('Total Revenue', _formatCurrency(totalRevenue)),
                      _StatCard('Pending Orders', pendingCount.toString()),
                      _StatCard('Today’s Reservations', todayCount.toString()),
                      _StatCard('Available Tables', availableCount.toString()),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard(this.label, this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: kShadow, blurRadius: 8, offset: const Offset(0, 4))],
        border: Border(left: BorderSide(color: kPrimary, width: 4)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon omitted here: Shell’s AppBar shows the title
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimary),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: kTextSecondary)),
        ],
      ),
    );
  }
}


