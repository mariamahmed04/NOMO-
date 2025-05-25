import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final _firestore = FirebaseFirestore.instance;

  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  bool loading = false;

  Future<void> addPaymentMethod() async {
    final cardNumber = _cardNumberController.text.trim();
    final expiry = _expiryController.text.trim();

    if (cardNumber.isEmpty || expiry.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    setState(() => loading = true);

    final collection = _firestore.collection('users').doc(uid).collection('payment_methods');
    final isFirst = (await collection.get()).docs.isEmpty;

    await collection.add({
      'card_number': cardNumber,
      'expiry': expiry,
      'is_default': isFirst,
      'created_at': FieldValue.serverTimestamp(),
    });

    _cardNumberController.clear();
    _expiryController.clear();
    setState(() => loading = false);
  }

  Future<void> deleteCard(String id) async {
    await _firestore.collection('users').doc(uid).collection('payment_methods').doc(id).delete();
  }

  Future<void> makeDefault(String id) async {
    final ref = _firestore.collection('users').doc(uid).collection('payment_methods');
    final snapshot = await ref.get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'is_default': doc.id == id});
    }
  }

  Widget _inputCard({required String label, required TextEditingController controller}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF884C).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCardTile({
    required Map<String, dynamic> card,
    required String docId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF884C).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card, color: Color(0xFFFF884C)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "**** **** **** ${card['card_number'].toString().substring(card['card_number'].length - 4)}",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text("Exp: ${card['expiry']}", style: const TextStyle(color: Colors.grey)),
                if (card['is_default'] == true)
                  const Text("Default", style: TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ),
          ),
          if (card['is_default'] != true)
            IconButton(
              icon: const Icon(Icons.star_border, color: Color(0xFFFF884C)),
              onPressed: () => makeDefault(docId),
              tooltip: "Set as default",
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => deleteCard(docId),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Payment Methods", style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _inputCard(label: "Card Number", controller: _cardNumberController),
            _inputCard(label: "Expiry Date (MM/YY)", controller: _expiryController),
            ElevatedButton(
              onPressed: loading ? null : addPaymentMethod,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF884C),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: loading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text("Add Card", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Saved Cards",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(uid)
                    .collection('payment_methods')
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final cards = snapshot.data!.docs;

                  if (cards.isEmpty) {
                    return const Center(child: Text("No payment methods yet."));
                  }

                  return ListView.builder(
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index].data() as Map<String, dynamic>;
                      final docId = cards[index].id;
                      return _buildCardTile(card: card, docId: docId);
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
