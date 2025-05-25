import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Helper to format a DateTime as "DD/MM/YYYY • hh:mm AM/PM"
String formatDateTime(DateTime dateTime) {
  final datePart = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  final tod = TimeOfDay.fromDateTime(dateTime);
  final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
  final minute = tod.minute.toString().padLeft(2, '0');
  final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
  return '$datePart • $hour:$minute $period';
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F7F4),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text("My Orders", style: TextStyle(color: Colors.black)),
          bottom: const TabBar(
            indicatorColor: Color(0xFFFF884C),
            labelColor: Color(0xFFFF884C),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Dine-In"),
              Tab(text: "Grab & Go"),
              Tab(text: "Reservations"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OrderTabView(type: 'dine-in'),
            OrderTabView(type: 'grab-go'),
            OrderTabView(type: 'reservation'),
          ],
        ),
      ),
    );
  }
}

class OrderTabView extends StatefulWidget {
  final String type;
  const OrderTabView({required this.type, Key? key}) : super(key: key);

  @override
  _OrderTabViewState createState() => _OrderTabViewState();
}

class _OrderTabViewState extends State<OrderTabView>
    with AutomaticKeepAliveClientMixin<OrderTabView> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<User?>(
      future: Future.value(FirebaseAuth.instance.currentUser),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final uid = snapshot.data!.uid;
        print("✅ UID: $uid");

        final collection = widget.type == 'reservation' ? 'reservations' : 'orders';
        final orderField = widget.type == 'reservation' ? 'created_at' : 'timestamp';

        final query = FirebaseFirestore.instance
            .collection(collection)
            .where('customer_id', isEqualTo: uid)
            .orderBy(orderField, descending: true);

        final fullQuery = widget.type == 'reservation'
            ? query
            : query.where('type', isEqualTo: widget.type);

        // Optional debug: manual get to confirm results
        fullQuery.get().then((snap) {
          print("🔥 Manual fetch: ${snap.docs.length} docs for '${widget.type}'");
        }).catchError((e) {
          print("❌ Firestore fetch error: $e");
        });

        return StreamBuilder<QuerySnapshot>(
          stream: fullQuery.snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Text("Error loading orders: ${snap.error}"),
              );
            }

            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data?.docs ?? [];
            print("📦 Stream result: ${docs.length} docs for '${widget.type}'");

            if (docs.isEmpty) {
              return const Center(
                child: Text("No records yet.", style: TextStyle(color: Colors.grey)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: docs.length,
              itemBuilder: (ctx, i) => _buildOrderCard(docs[i]),
            );
          },
        );
      },
    );
  }

  Widget _buildOrderCard(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    DateTime time = DateTime.now();

    if (widget.type == 'reservation') {
      final ts = data['created_at'] as Timestamp?;
      if (ts != null) time = ts.toDate();
    } else {
      final ts = data['timestamp'] as Timestamp?;
      if (ts != null) time = ts.toDate();
    }

    final formattedTime = formatDateTime(time);
    final total = (data['total_price'] as num?)?.toDouble() ?? 0.0;
    final status = (data['status'] as String?)?.toLowerCase() ?? 'unknown';

    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = const Color(0xFFFF884C);
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    final label = widget.type == 'reservation'
        ? "Reservation"
        : widget.type.replaceAll('-', ' ').toUpperCase();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF884C).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label • $formattedTime",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Total: ${total.toStringAsFixed(2)} EGP",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            "Status: ${status[0].toUpperCase()}${status.substring(1)}",
            style: TextStyle(color: statusColor),
          ),
        ],
      ),
    );
  }
}
