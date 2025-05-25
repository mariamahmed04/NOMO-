import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckoutGrabGoPage extends StatefulWidget {
  const CheckoutGrabGoPage({super.key});

  @override
  State<CheckoutGrabGoPage> createState() => _CheckoutGrabGoPageState();
}

class _CheckoutGrabGoPageState extends State<CheckoutGrabGoPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _pickupTimeController = TextEditingController();

  String? selectedPaymentId;
  bool submitting = false;

  Future<void> submitOrder() async {
    final uid = _auth.currentUser!.uid;
    final pickupTime = _pickupTimeController.text.trim();
    if (pickupTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a pickup time")),
      );
      return;
    }

    setState(() => submitting = true);
    final cartId = '${uid}_grab-go';
    final cartRef = _firestore.collection('carts').doc(cartId);
    final cartSnap = await cartRef.get();
    if (!cartSnap.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cart not found")),
      );
      setState(() => submitting = false);
      return;
    }

    final cart = cartSnap.data()!;
    final orderRef = _firestore.collection('orders').doc();
    await orderRef.set({
      'order_id': orderRef.id,
      'customer_id': uid,
      'restaurant_id': cart['restaurant_id'],
      'items': cart['items'],
      'type': 'grab-go',
      'pickup_time': pickupTime,
      'total_price': cart['total_price'],
      'status': 'pending',
      'payment_method_id': selectedPaymentId ?? '',
      'paid': true,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await cartRef.delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Grab & Go order placed successfully!")),
    );
    Navigator.pushReplacementNamed(context, '/customerHome');
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
        title: const Text("Grab & Go Checkout", style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF884C).withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _pickupTimeController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: "Pickup Time (e.g. 9:30 AM)",
                ),
              ),
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
                      child: Text("No saved payment methods.", style: TextStyle(color: Colors.grey)),
                    );
                  }

                  if (selectedPaymentId == null) {
                    final defaults = docs.where((d) => (d['is_default'] ?? false) as bool);
                    selectedPaymentId = (defaults.isNotEmpty ? defaults.first : docs.first).id;
                  }

                  return ListView(
                    children: docs.map((doc) {
                      final data = doc.data()! as Map<String, dynamic>;
                      final fullNum = data['card_number'] as String? ?? '';
                      final last4 = fullNum.length >= 4
                          ? fullNum.substring(fullNum.length - 4)
                          : fullNum;
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

            ElevatedButton(
              onPressed: submitting ? null : submitOrder,
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
                  : const Text("Confirm Pickup Order", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
