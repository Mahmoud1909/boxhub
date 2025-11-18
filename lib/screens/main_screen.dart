// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import '../widgets/profile_app_bar.dart';
import '../widgets/custom_bottom_nav.dart';

const Color brandColor = Color(0xFFF3692F);

class MainScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MainScreen({required this.userData, Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget Function(Map<String, dynamic>)> _pages = [
        (user) => HomePage(userData: user),
        (user) => OrdersPage(userData: user),
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('MainScreen: initState -> initializing main screen.');
    debugPrint('MainScreen: User data received -> ${widget.userData}');
  }

  void _onNavTap(int index) {
    debugPrint('MainScreen: Bottom nav tapped -> index: $index');
    setState(() {
      _currentIndex = index;
    });
    debugPrint('MainScreen: Current index after setState -> $_currentIndex');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('MainScreen: build -> building UI (index=$_currentIndex).');

    return Scaffold(
      appBar: ProfileAppBar(
        userData: widget.userData,
        onProfileTap: () {
          debugPrint('MainScreen: profile avatar tapped.');
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile tapped (placeholder)')));
        },
        onNotificationsTap: () {
          debugPrint('MainScreen: notifications icon tapped.');
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications tapped (placeholder)')));
        },
        onSettingsTap: () {
          debugPrint('MainScreen: settings icon tapped.');
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings tapped (placeholder)')));
        },
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        transitionBuilder: (child, animation) {
          // Fade + small slide for a modern feel
          final offsetAnim = Tween<Offset>(begin: const Offset(0.02, 0), end: Offset.zero).animate(animation);
          return SlideTransition(position: offsetAnim, child: FadeTransition(opacity: animation, child: child));
        },
        child: _pages[_currentIndex](widget.userData),
      ),
      bottomNavigationBar: CustomBottomNav(
        initialIndex: _currentIndex,
        onTap: (i) {
          debugPrint('MainScreen: CustomBottomNav onTap -> $i');
          _onNavTap(i);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint('MainScreen: FAB pressed (placeholder action).');
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FAB pressed (placeholder)')));
        },
        backgroundColor: brandColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final Map<String, dynamic> userData;
  const HomePage({required this.userData, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('HomePage: build -> rendering Home for user ${userData['email'] ?? 'unknown'}');
    return SafeArea(
      key: const ValueKey('home_page'),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home_outlined, size: 64, color: Theme.of(context).primaryColor),
              const SizedBox(height: 12),
              const Text('Home', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Welcome, ${userData['displayName'] ?? userData['email'] ?? 'User'}', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text('This is the Home screen. Replace with your real content.', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class OrdersPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  const OrdersPage({required this.userData, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('OrdersPage: build -> rendering Orders for user ${userData['email'] ?? 'unknown'}');
    return SafeArea(
      key: const ValueKey('orders_page'),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.receipt_long_outlined, size: 64),
              SizedBox(height: 12),
              Text('Orders', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('This is the Orders screen. Replace with your real content.'),
            ],
          ),
        ),
      ),
    );
  }
}
