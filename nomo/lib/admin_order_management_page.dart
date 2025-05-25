// lib/grabgo_orders_body.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Shared theme constants (or import from your styles.dart)
const Color kPrimary = Color(0xFFFF8C00);
const Color kSurface = Colors.white;
const Color kText = Color(0xFF333333);
const Color kTextSecondary = Color(0xFF777777);
const Color kDivider = Color(0xFFE0E0E0);
const Color kShadow = Color(0x22000000);

class GrabGoOrdersBody extends StatelessWidget {
  final String restaurantId;
  const GrabGoOrdersBody({required this.restaurantId, Key? key})
      : super(key: key);

  Stream<QuerySnapshot> get _stream => FirebaseFirestore.instance
      .collection('orders')
      .where('restaurant_id', isEqualTo: restaurantId)
      .where('type', isEqualTo: 'grab-go')
      .orderBy('timestamp', descending: true)
      .snapshots();

  Future<void> _updateStatus(String id, String status) =>
      FirebaseFirestore.instance.collection('orders').doc(id).update({'status': status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snap) {
          // loading state
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // error or no data
          if (snap.hasError) {
            return const Center(child: Text('Error loading orders.'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No Grab & Go orders.', style: TextStyle(color: kTextSecondary)),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final doc = docs[i];
              // safe cast and fallback
              final raw = doc.data();
              final data = (raw is Map<String, dynamic>) ? raw : {};
              final status = (data['status'] as String?) ?? 'pending';
              final itemsList = data['items'];
              final items = (itemsList is List)
                  ? itemsList.map<Map<String, dynamic>>((e) => (e as Map?)?.cast<String, dynamic>() ?? {}).toList()
                  : <Map<String, dynamic>>[];
              final total = (data['total_price'] as num?)?.toDouble() ?? 0.0;

              // safe timestamp parse
              DateTime ts;
              final tsRaw = data['timestamp'];
              if (tsRaw is Timestamp) {
                ts = tsRaw.toDate().toLocal();
              } else {
                ts = DateTime.now();
              }

              return Card(
                color: kSurface,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                shadowColor: kShadow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Order #${doc.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kText,
                              ),
                            ),
                          ),
                          DropdownButton<String>(
                            value: status,
                            underline: const SizedBox(),
                            items: ['pending', 'preparing', 'ready', 'completed']
                                .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s[0].toUpperCase() + s.substring(1),
                                style: TextStyle(
                                  color: s == 'completed'
                                      ? Colors.green
                                      : s == 'pending'
                                      ? kPrimary
                                      : kText,
                                ),
                              ),
                            ))
                                .toList(),
                            onChanged: (s) {
                              if (s != null) _updateStatus(doc.id, s);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Items
                      ...items.map((item) {
                        final name = item['name'] as String? ?? '';
                        final qty = (item['qty'] as num?)?.toInt() ?? 0;
                        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '$name x$qty — EGP ${(price * qty).toStringAsFixed(2)}',
                            style: const TextStyle(color: kTextSecondary),
                          ),
                        );
                      }).toList(),

                      const Divider(color: kDivider, height: 24),

                      // Total & timestamp
                      Row(
                        children: [
                          Text(
                            'Total: EGP ${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, color: kText),
                          ),
                          const Spacer(),
                          Text(
                            '${ts.hour.toString().padLeft(2, '0')}:'
                                '${ts.minute.toString().padLeft(2, '0')} '
                                '${ts.day}/${ts.month}/${ts.year}',
                            style: const TextStyle(
                                fontSize: 12, color: kTextSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
