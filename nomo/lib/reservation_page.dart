// ✅ ReservationPage - Updated Version

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservationPage extends StatefulWidget {
  final String restaurantId;

  const ReservationPage({super.key, required this.restaurantId});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedTableId;
  List<QueryDocumentSnapshot> availableTables = [];

  String? selectedPaymentId;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    fetchAvailableTables();
  }

  Future<void> fetchAvailableTables() async {
    final snapshot = await _firestore
        .collection('tables')
        .where('restaurant_id', isEqualTo: widget.restaurantId)
        .where('status', isEqualTo: 'available')
        .get();
    setState(() => availableTables = snapshot.docs);
  }

  Future<void> selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  Future<void> submitReservation() async {
    if (selectedDate == null ||
        selectedTime == null ||
        selectedTableId == null ||
        selectedPaymentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields, including payment method")),
      );
      return;
    }

    setState(() => submitting = true);

    final user = _auth.currentUser!;
    final reservationDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final cartRef = _firestore.collection('carts').doc('${user.uid}_reservation');
    final cartSnap = await cartRef.get();
    if (!cartSnap.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reservation cart is empty")),
      );
      setState(() => submitting = false);
      return;
    }

    final cartData = cartSnap.data()!;
    final selectedItems = cartData['items'];
    final totalPrice = cartData['total_price'];

    final reservationRef = _firestore.collection('reservations').doc();
    await reservationRef.set({
      'reservation_id': reservationRef.id,
      'customer_id': user.uid,
      'restaurant_id': widget.restaurantId,
      'table_number': availableTables.firstWhere((d) => d.id == selectedTableId!)['table_number'],
      'reservation_time': reservationDateTime,
      'items': selectedItems,
      'total_price': totalPrice,
      'payment_method_id': selectedPaymentId!,
      'paid': true,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('tables').doc(selectedTableId).update({'status': 'reserved'});
    await cartRef.delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reservation submitted successfully!")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser!.uid;
    final methodsStream = _firestore
        .collection('users')
        .doc(uid)
        .collection('payment_methods')
        .orderBy('created_at', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Reserve a Table", style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Choose Date & Time", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(selectedDate == null
                        ? "Select Date"
                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"),
                    onPressed: () => selectDate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFFF884C)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(selectedTime == null ? "Select Time" : selectedTime!.format(context)),
                    onPressed: () => selectTime(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFFF884C)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text("Choose a Table", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            availableTables.isEmpty
                ? const Text("No available tables", style: TextStyle(color: Colors.grey))
                : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF884C)),
              ),
              child: DropdownButton<String>(
                value: selectedTableId,
                isExpanded: true,
                underline: const SizedBox(),
                hint: const Text("Select a table"),
                items: availableTables.map((doc) {
                  final num = doc['table_number'];
                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text("Table $num"),
                  );
                }).toList(),
                onChanged: (v) => setState(() => selectedTableId = v),
              ),
            ),
            const SizedBox(height: 32),
            FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('carts').doc('${_auth.currentUser!.uid}_reservation').get(),
              builder: (context, snap) {
                if (!snap.hasData || !snap.data!.exists) return const SizedBox();
                final cart = snap.data!.data() as Map<String, dynamic>;
                final items = List<Map<String, dynamic>>.from(cart['items']);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Selected Items", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text("${item['name']} x${item['qty']}"),
                    )),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Text("Select Payment Method", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: methodsStream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                        child: Text("No saved payment methods.", style: TextStyle(color: Colors.grey)));
                  }

                  if (selectedPaymentId == null) {
                    final defaults = docs.where((d) => (d['is_default'] ?? false) as bool);
                    selectedPaymentId = (defaults.isNotEmpty ? defaults.first : docs.first).id;
                  }

                  return ListView(
                    children: docs.map((doc) {
                      final data = doc.data()! as Map<String, dynamic>;
                      final num = data['card_number'] as String? ?? '';
                      final last4 = num.length >= 4 ? num.substring(num.length - 4) : num;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF884C).withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: RadioListTile<String>(
                          value: doc.id,
                          groupValue: selectedPaymentId,
                          onChanged: (val) => setState(() => selectedPaymentId = val),
                          title: Text("**** **** **** $last4"),
                          secondary: const Icon(Icons.credit_card, color: Color(0xFFFF884C)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: submitting ? null : submitReservation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF884C),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: submitting
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text("Confirm Reservation", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
