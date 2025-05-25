// lib/reservations_body.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Shared theme constants
const Color kPrimary = Color(0xFFFF8C00);
const Color kSurface = Colors.white;
const Color kText = Color(0xFF333333);
const Color kTextSecondary = Color(0xFF777777);
const Color kDivider = Color(0xFFE0E0E0);
const Color kShadow = Color(0x22000000);

class ReservationsBody extends StatelessWidget {
  final String restaurantId;
  const ReservationsBody({required this.restaurantId, Key? key})
      : super(key: key);

  Stream<QuerySnapshot> get _stream => FirebaseFirestore.instance
      .collection('reservations')
      .where('restaurant_id', isEqualTo: restaurantId)
      .orderBy('reservation_time', descending: true)
      .snapshots();

  Future<void> _updateStatus(String id, String status) =>
      FirebaseFirestore.instance
          .collection('reservations')
          .doc(id)
          .update({'status': status});

  String _fmt(Timestamp ts) {
    final d = ts.toDate();
    final date = '${d.day}/${d.month}/${d.year}';
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$date  $hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // null check and fallback
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No reservations found.', style: TextStyle(color: kTextSecondary)),
            );
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final doc = docs[i];
              final data = doc.data()! as Map<String, dynamic>;
              final status = data['status'] as String? ?? 'pending';
              final tableNum = data['table_number']?.toString() ?? '-';
              final reservationTime = data['reservation_time'] as Timestamp;
              final createdAt = data['created_at'] as Timestamp;

              // Ensure proper conversion of Timestamp
              final ts = reservationTime.toDate();

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
                              'Resv #${doc.id}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: kText),
                            ),
                          ),
                          DropdownButton<String>(
                            value: status,
                            underline: const SizedBox(),
                            items: ['pending', 'confirmed', 'cancelled']
                                .map((s) {
                              final color = s == 'confirmed'
                                  ? Colors.green
                                  : s == 'cancelled'
                                  ? Colors.red
                                  : kTextSecondary;
                              return DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s[0].toUpperCase() + s.substring(1),
                                  style: TextStyle(color: color),
                                ),
                              );
                            }).toList(),
                            onChanged: (s) {
                              if (s != null) _updateStatus(doc.id, s);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Table & time
                      Row(
                        children: [
                          Icon(Icons.table_chart, color: kPrimary, size: 20),
                          const SizedBox(width: 6),
                          Text('Table $tableNum',
                              style: const TextStyle(color: kTextSecondary)),
                          const SizedBox(width: 16),
                          Icon(Icons.schedule, color: kPrimary, size: 20),
                          const SizedBox(width: 6),
                          Text(_fmt(reservationTime), style: const TextStyle(color: kTextSecondary)),
                        ],
                      ),

                      const Divider(color: kDivider, height: 24),

                      // Created at
                      Text(
                        'Created ${_fmt(createdAt)}',
                        style: const TextStyle(fontSize: 12, color: kTextSecondary),
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
