import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GrabGoMenuPage extends StatefulWidget {
  final String restaurantId;

  const GrabGoMenuPage({super.key, required this.restaurantId});

  @override
  State<GrabGoMenuPage> createState() => _GrabGoMenuPageState();
}

class _GrabGoMenuPageState extends State<GrabGoMenuPage> with SingleTickerProviderStateMixin {
  late AnimationController _cartController;

  @override
  void initState() {
    super.initState();
    _cartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      lowerBound: 1.0,
      upperBound: 1.3,
    );
  }

  @override
  void dispose() {
    _cartController.dispose();
    super.dispose();
  }

  void triggerCartAnimation() {
    _cartController.forward(from: 0.9).then((_) => _cartController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Grab & Go Menu', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          ScaleTransition(
            scale: _cartController,
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.pushNamed(context, '/cart', arguments: {'type': 'grab-go'});
              },
            ),
          )
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).get(),
        builder: (context, restaurantSnapshot) {
          if (restaurantSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final restaurantData = restaurantSnapshot.data?.data() as Map<String, dynamic>?;

          return Column(
            children: [
              if (restaurantData != null) ...[
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: Image.network(
                    restaurantData['image_url'] ?? '',
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurantData['name'] ?? 'Unnamed Restaurant',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        restaurantData['cuisine'] ?? 'Cuisine not specified',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFF884C), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            (restaurantData['rating'] ?? 'N/A').toString(),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            "Status: ${restaurantData['status'] ?? 'unknown'}",
                            style: TextStyle(
                              color: (restaurantData['status'] == 'available') ? Colors.green : Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('menu_items')
                      .where('restaurant_id', isEqualTo: widget.restaurantId)
                      .where('available', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final items = snapshot.data!.docs;
                    if (items.isEmpty) {
                      return const Center(child: Text("No items available."));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index].data() as Map<String, dynamic>;
                        final itemId = items[index].id;
                        return _MenuItemCard(
                          item: item,
                          itemId: itemId,
                          restaurantId: widget.restaurantId,
                          onAdded: triggerCartAnimation,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final String itemId;
  final String restaurantId;
  final VoidCallback onAdded;

  const _MenuItemCard({
    required this.item,
    required this.itemId,
    required this.restaurantId,
    required this.onAdded,
  });

  @override
  State<_MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<_MenuItemCard> {
  int quantity = 1;

  Future<void> addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('carts')
        .doc('${user.uid}_dine-in')
        .delete()
        .catchError((_) {});

    final cartId = '${user.uid}_grab-go';
    final cartRef = FirebaseFirestore.instance.collection('carts').doc(cartId);
    final cartSnap = await cartRef.get();

    final itemToAdd = {
      'item_id': widget.itemId,
      'name': widget.item['name'],
      'price': widget.item['price'],
      'qty': quantity,
      'image_url': widget.item['image_url']
    };

    if (!cartSnap.exists) {
      await cartRef.set({
        'user_id': user.uid,
        'restaurant_id': widget.restaurantId,
        'type': 'grab-go',
        'items': [itemToAdd],
        'total_price': widget.item['price'] * quantity,
        'status': 'active',
        'created_at': FieldValue.serverTimestamp(),
      });
    } else {
      final cartData = cartSnap.data()!;
      List<dynamic> itemsList = List.from(cartData['items']);

      bool itemExists = false;
      for (int i = 0; i < itemsList.length; i++) {
        if (itemsList[i]['item_id'] == widget.itemId) {
          itemsList[i]['qty'] += quantity;
          itemExists = true;
          break;
        }
      }

      if (!itemExists) {
        itemsList.add(itemToAdd);
      }

      double newTotal = 0;
      for (var i in itemsList) {
        newTotal += i['price'] * i['qty'];
      }

      await cartRef.update({
        'items': itemsList,
        'total_price': newTotal,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.item['name']} added to cart')),
    );

    widget.onAdded();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF884C).withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.item['image_url'],
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item['name'],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.item['price']} EGP',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _quantityButton(Icons.remove, () {
                if (quantity > 1) setState(() => quantity--);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$quantity', style: const TextStyle(fontSize: 16)),
              ),
              _quantityButton(Icons.add, () => setState(() => quantity++)),
              const Spacer(),
              ElevatedButton(
                onPressed: addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF884C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  "Add",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              )
            ],
          )
        ],
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
