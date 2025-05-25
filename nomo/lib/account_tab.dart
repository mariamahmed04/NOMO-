import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final _auth = FirebaseAuth.instance;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      userData = snapshot.data();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFFF884C),
                child: Icon(Icons.person, size: 30, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userData!['name'] ?? 'No Name',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(userData!['email'] ?? '',
                      style: const TextStyle(color: Colors.grey)),
                ],
              )
            ],
          ),
          const SizedBox(height: 30),

          _buildCardTile(
            icon: Icons.edit,
            label: "Edit Profile",
            onTap: () => Navigator.pushNamed(context, '/editProfile'),
          ),
          _buildCardTile(
            icon: Icons.credit_card,
            label: "Payment Methods",
            onTap: () => Navigator.pushNamed(context, '/paymentMethods'),
          ),
          _buildCardTile(
            icon: Icons.lock_outline,
            label: "Change Password",
            onTap: () => Navigator.pushNamed(context, '/changePassword'),
          ),
          _buildCardTile(
            icon: Icons.logout,
            label: "Logout",
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Icon(icon, color: const Color(0xFFFF884C)),
        title: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
