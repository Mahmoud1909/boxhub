// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lottie/lottie.dart';
import 'firebase_options.dart';
import 'screens/signup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('=== App Launch ===');
  debugPrint('Step 1/3: Starting Firebase initialization...');

  var firebaseReady = false;
  try {
    debugPrint('Step 2/3: Calling Firebase.initializeApp()...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
    debugPrint('Step 3/3: Firebase initialized successfully.');
    debugPrint('Info: Registered Firebase apps: ${Firebase.apps.map((a) => a.name).join(', ')}');
  } catch (err, st) {
    debugPrint('ERROR: Firebase failed to initialize: $err');
    debugPrint(st.toString());
  }

  debugPrint('Firebase initialization status => $firebaseReady');
  debugPrint('=== End App Launch ===');

  runApp(MyApp(firebaseInitialized: firebaseReady));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  const MyApp({Key? key, required this.firebaseInitialized}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BoxHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Brand color #4A148C
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A148C)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: SplashScreen(firebaseInitialized: firebaseInitialized),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final bool firebaseInitialized;
  const SplashScreen({Key? key, required this.firebaseInitialized}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  // fallback to avoid stuck splash (longer to let animation play)
  static const Duration fallbackDuration = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    debugPrint('Splash: initState -> starting splash screen.');

    // safety fallback
    Future.delayed(fallbackDuration, () {
      if (!_navigated) {
        debugPrint('Splash: Fallback timeout reached (${fallbackDuration.inSeconds}s). Navigating to SignUp.');
        _goToSignUp(reason: 'fallback_timeout');
      }
    });
  }

  void _goToSignUp({required String reason}) {
    if (_navigated) return;
    _navigated = true;
    debugPrint('Splash: Navigating to SignUp. Reason: $reason');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SignUpScreen(firebaseInitialized: widget.firebaseInitialized),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF4A148C);

    return Scaffold(
      backgroundColor: brandColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bigger Lottie animation (dominant)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.78, // responsive large size
                height: MediaQuery.of(context).size.width * 0.78,
                child: _buildLottieAnimation(),
              ),
              const SizedBox(height: 20),
              const Text(
                'Fast • Secure • Reliable',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              // small loading indicator (dots)
              const SizedBox(height: 6),
              const SizedBox(
                height: 28,
                child: Center(child: _DotLoader()), // simple dot loader
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLottieAnimation() {
    final assetPath = 'assets/animations/delivery.json';
    debugPrint('Splash: Preparing Lottie.asset("$assetPath")...');

    return Lottie.asset(
      assetPath,
      fit: BoxFit.contain,
      onLoaded: (composition) {
        final dur = composition.duration;
        debugPrint('Splash: Animation loaded. Duration = ${dur.inSeconds}s.');
        debugPrint('Splash: Playing animation now.');

        // wait animation then navigate (small buffer)
        Future.delayed(dur + const Duration(milliseconds: 500), () {
          if (!_navigated) {
            debugPrint('Splash: Animation completed. Navigating to SignUp.');
            _goToSignUp(reason: 'animation_completed');
          }
        });
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Splash: Lottie load error: $error');
        // short fallback before navigating
        Future.delayed(const Duration(seconds: 1), () {
          if (!_navigated) _goToSignUp(reason: 'animation_error');
        });
        return const Center(child: Icon(Icons.local_shipping, size: 92, color: Colors.white70));
      },
    );
  }
}

/// Small dot loader widget
class _DotLoader extends StatefulWidget {
  const _DotLoader({Key? key}) : super(key: key);

  @override
  State<_DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<_DotLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<int> _step;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _step = IntTween(begin: 0, end: 2).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _step,
      builder: (context, child) {
        final s = _step.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final active = i <= s;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Container(
                width: active ? 8 : 6,
                height: active ? 8 : 6,
                decoration: BoxDecoration(
                  color: active ? Colors.white70 : Colors.white24,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
