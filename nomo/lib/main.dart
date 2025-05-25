import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Screens
import 'signup_screen.dart';
import 'login_screen.dart';
import 'customer_shell.dart';
import 'dine_in_menu.dart';
import 'grab_go_menu.dart';
import 'cart_page.dart';
import 'checkout_dinein.dart';
import 'checkout_grabgo.dart';
import 'restaurant_list_page.dart';
import 'reservation_menu_page.dart';
import 'reservation_page.dart';
import 'edit_profile_page.dart';
import 'payment_methods_page.dart';
import 'change_password_page.dart';
import 'orders_page.dart';
import 'admin_dashboard_page.dart';  // ← Import the Admin Dashboard
import 'admin_shell.dart';  // ← Import the AdminShell for navigation

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOMO',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/signup': (_) => const SignupScreen(),
        '/login': (_) => const LoginScreen(),
        '/customerHome': (_) => const CustomerShell(),
        '/orders': (_) => const OrdersPage(),
        '/cart': (_) => const CartPage(),
        '/editProfile': (_) => const EditProfilePage(),
        '/paymentMethods': (_) => const PaymentMethodsPage(),
        '/changePassword': (_) => const ChangePasswordPage(),

        // Admin dashboard
        '/adminDashboard': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final restaurantId = args?['restaurantId'] as String?;
          if (restaurantId == null) {
            return const Scaffold(
              body: Center(child: Text("Missing restaurantId")),
            );
          }
          return AdminShell(restaurantId: restaurantId);  // Corrected line
        },

        '/dineInMenu': (context) {
          final restaurantId = ModalRoute.of(context)!.settings.arguments as String?;
          return restaurantId != null
              ? DineInMenuPage(restaurantId: restaurantId)
              : const Scaffold(body: Center(child: Text("Missing restaurant ID")));
        },

        '/grabGoMenu': (context) {
          final restaurantId = ModalRoute.of(context)!.settings.arguments as String?;
          return restaurantId != null
              ? GrabGoMenuPage(restaurantId: restaurantId)
              : const Scaffold(body: Center(child: Text("Missing restaurant ID")));
        },

        '/checkout': (context) {
          final user = FirebaseAuth.instance.currentUser;
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          final type = args?['type'];

          if (user == null || type == null) {
            return const Scaffold(body: Center(child: Text("Invalid cart type or user")));
          }

          final cartId = '${user.uid}_$type';
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('carts').doc(cartId).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              final data = snapshot.data!.data() as Map<String, dynamic>?;

              switch (data?['type']) {
                case 'dine-in':
                  return const CheckoutDineInPage();
                case 'grab-go':
                  return const CheckoutGrabGoPage();
                default:
                  return const Scaffold(body: Center(child: Text("Invalid cart type.")));
              }
            },
          );
        },

        '/restaurants': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          final mode = args?['mode'];

          if (mode == 'reservation') {
            return RestaurantListPage(
              mode: 'reservation',
              onRestaurantSelected: (restaurantId) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReservationMenuPage(restaurantId: restaurantId),
                  ),
                );
              },
            );
          }

          if (mode == 'dine-in' || mode == 'grab-go') {
            return RestaurantListPage(mode: mode);
          }

          return const Scaffold(body: Center(child: Text("Invalid restaurant list mode")));
        },

        '/reserve': (context) {
          final restaurantId = ModalRoute.of(context)!.settings.arguments as String?;
          return restaurantId != null
              ? ReservationPage(restaurantId: restaurantId)
              : const Scaffold(body: Center(child: Text("Missing restaurant ID")));
        },
      },
    );
  }
}
