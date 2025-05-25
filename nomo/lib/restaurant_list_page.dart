import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reservation_menu_page.dart';

class RestaurantListPage extends StatelessWidget {
  final String mode; // 'dine-in', 'grab-go', or 'reservation'
  final Function(String)? onRestaurantSelected;

  const RestaurantListPage({
    super.key,
    required this.mode,
    this.onRestaurantSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      appBar: AppBar(
        title: Text('${_getModeLabel()} Restaurants'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final restaurants = snapshot.data!.docs;

          if (restaurants.isEmpty) {
            return const Center(child: Text('No restaurants found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final data = restaurants[index].data() as Map<String, dynamic>;
              final restaurantId = restaurants[index].id;
              final imageUrl = data['image_url'] ?? '';
              final name = data['name'] ?? 'Unnamed';
              final status = data['status'] ?? 'unknown';
              final cuisine = data['cuisine'] ?? '';
              final rating = data['rating']?.toString() ?? 'N/A';

              return GestureDetector(
                onTap: () {
                  if (mode == 'reservation') {
                    if (onRestaurantSelected != null) {
                      onRestaurantSelected!(restaurantId);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReservationMenuPage(restaurantId: restaurantId),
                        ),
                      );
                    }
                  } else {
                    Navigator.pushNamed(
                      context,
                      mode == 'dine-in' ? '/dineInMenu' : '/grabGoMenu',
                      arguments: restaurantId,
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.1),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        )
                            : Container(
                          width: double.infinity,
                          height: 180,
                          color: Colors.orange.withOpacity(0.2),
                          child: const Icon(Icons.restaurant, color: Colors.orange, size: 48),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cuisine.isNotEmpty ? cuisine : 'Cuisine: Unspecified',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 18),
                          const SizedBox(width: 4),
                          Text(rating, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 16),
                          Text(
                            "Status: $status",
                            style: TextStyle(
                              fontSize: 14,
                              color: status == 'available' ? Colors.green : Colors.red,
                            ),
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

  String _getModeLabel() {
    switch (mode) {
      case 'dine-in':
        return 'Dine-In';
      case 'grab-go':
        return 'Grab & Go';
      case 'reservation':
        return 'Reservation';
      default:
        return 'Browse';
    }
  }
}
