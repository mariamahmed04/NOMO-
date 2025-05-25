import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reservation_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final user = FirebaseAuth.instance.currentUser;
  late String _cartType;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _cartType = args?['type'] ?? 'dine-in';
  }

  Future<DocumentSnapshot> getCartDoc() {
    final cartId = '${user!.uid}_$_cartType';
    return FirebaseFirestore.instance.collection('carts').doc(cartId).get();
  }

  void updateQuantity(String itemId, int newQty, List<dynamic> items, String cartId) async {
    final cartRef = FirebaseFirestore.instance.collection('carts').doc(cartId);

    for (int i = 0; i < items.length; i++) {
      if (items[i]['item_id'] == itemId) {
        items[i]['qty'] = newQty;
        break;
      }
    }
    items.removeWhere((item) => item['qty'] <= 0);

    double newTotal = 0;
    for (var i in items) {
      newTotal += i['qty'] * i['price'];
    }

    await cartRef.update({
      'items': items,
      'total_price': newTotal,
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final title = "${_cartType[0].toUpperCase()}${_cartType.substring(1)} cart";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(title, style: const TextStyle(color: Colors.black)),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: getCartDoc(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final cartSnap = snapshot.data!;
          if (!cartSnap.exists) {
            return const Center(child: Text("Your cart is empty."));
          }

          final cartData = cartSnap.data() as Map<String, dynamic>;
          final items = List.from(cartData['items'] ?? []);
          final totalPrice = cartData['total_price'] ?? 0.0;
          final cartId = cartSnap.id;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
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
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              item['image_url'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item['price']} EGP x ${item['qty']}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _quantityButton(Icons.remove, () {
                                      if (item['qty'] > 1) {
                                        updateQuantity(item['item_id'], item['qty'] - 1, items, cartId);
                                      }
                                    }),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text('${item['qty']}', style: const TextStyle(fontSize: 16)),
                                    ),
                                    _quantityButton(Icons.add, () {
                                      updateQuantity(item['item_id'], item['qty'] + 1, items, cartId);
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Total: ${totalPrice.toStringAsFixed(2)} EGP",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (_cartType == 'reservation') {
                          final doc = await getCartDoc();
                          if (!doc.exists) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Your cart is empty.")),
                            );
                            return;
                          }
                          final data = doc.data() as Map<String, dynamic>;
                          final restaurantId = data['restaurant_id'] as String;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReservationPage(restaurantId: restaurantId),
                            ),
                          );
                        } else {
                          Navigator.pushNamed(
                            context,
                            '/checkout',
                            arguments: {'type': _cartType},
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF884C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Proceed to Checkout",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
