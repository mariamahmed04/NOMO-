import 'package:flutter/material.dart';

class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F1),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Choose your dining experience",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF884C), // Updated color
                  fontFamily: 'Orbitron',
                ),
              ),
              const SizedBox(height: 48),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSquareCard(
                    icon: Icons.restaurant,
                    label: "Reservation",
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/restaurants',
                      arguments: {'mode': 'reservation'},
                    ),
                  ),
                  const SizedBox(width: 32),
                  _buildSquareCard(
                    icon: Icons.shopping_bag,
                    label: "Grab & Go",
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/restaurants',
                      arguments: {'mode': 'grab-go'},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              _buildSquareCard(
                icon: Icons.room_service,
                label: "Dine-In",
                onTap: () => Navigator.pushNamed(
                  context,
                  '/restaurants',
                  arguments: {'mode': 'dine-in'},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquareCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 160,
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFF884C).withOpacity(0.2), // Updated shadow color
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Color(0xFFFF884C), size: 48), // Updated icon color
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black, // Button text color set to black
              ),
            ),
          ],
        ),
      ),
    );
  }
}
