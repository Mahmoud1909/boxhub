// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lottie/lottie.dart';
import 'firebase_options.dart';
import 'screens/signup_screen.dart';

const Color brandColor = Color(0xFFF47622);
//const Color brandColor = Color(f47622);
//const Color brandColor = Color(0xFFF47622);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: brandColor,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

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
        // Brand color seed
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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool _navigated = false;

  static const Duration fallbackDuration = Duration(seconds: 8);

  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    debugPrint('Splash: initState -> starting splash screen.');

    // Entrance / subtle breathing animation for the Lottie
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _scaleAnim = Tween<double>(begin: 0.90, end: 1.06).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Start with a single pop then gentle repeat
    _scaleController.forward().whenComplete(() {
      if (mounted && !_scaleController.isAnimating) {
        _scaleController.repeat(reverse: true);
      }
    });

    // Safety fallback in case the animation or navigation gets stuck
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

    // stop animations cleanly before navigating
    try {
      _scaleController.stop();
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SignUpScreen(firebaseInitialized: widget.firebaseInitialized),
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;

    // Responsive size calculation:
    // Increase the Lottie size slightly compared to the previous implementation.
    // Use a bit larger multipliers and allow larger max size.
    final double base = width * 0.96;
    final double alt = height * 0.62;
    double size = (base < alt ? base : alt);
    size = size.clamp(200.0, 640.0); // min 200, max 640 (bigger animation)

    // small top padding on tall screens so text remains visible on shorter phones
    final topPadding = (height > 750) ? 48.0 : 20.0;

    return Scaffold(
      backgroundColor: brandColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // prevent scroll flicker but allow layout to shrink on very small screens
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(top: topPadding, left: 20, right: 20, bottom: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated scale wrapper for the Lottie animation
                  SizedBox(
                    width: size,
                    height: size,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: _buildLottieAnimation(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tagline — keep accessible & responsive
                  const Text(
                    'Fast • Secure • Reliable',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Small loading indicator (dots) — remains visible on all devices
                  const SizedBox(
                    height: 28,
                    child: Center(child: _DotLoader()),
                  ),
                ],
              ),
            ),
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
      // When Lottie loads we wait its duration then navigate
      onLoaded: (composition) {
        final dur = composition.duration;
        debugPrint('Splash: Animation loaded. Duration = ${dur.inSeconds}s.');

        // Safety: if duration is zero or odd, use a fallback short wait
        final wait = (dur.inMilliseconds > 0) ? dur + const Duration(milliseconds: 500) : const Duration(seconds: 2);

        Future.delayed(wait, () {
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
        return const Center(child: Icon(Icons.local_shipping, size: 112, color: Colors.white70));
      },
    );
  }
}

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
