// lib/screens/signup_screen.dart
import 'package:boxhub/screens/login_screen.dart';
import 'package:boxhub/screens/main_screen.dart';
import 'package:boxhub/services/auth_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignUpScreen extends StatefulWidget {
  final bool firebaseInitialized;
  const SignUpScreen({Key? key, required this.firebaseInitialized}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  // Primary brand color requested
  static const Color brandColor = Color(0xFFF47622); // #F3692F

  bool _loading = false;
  late final AnimationController _animController;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    debugPrint('SignUp: initState -> building Sign Up screen.');

    // Status bar -> white since background is white
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack)),
    );

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic)),
    );

    _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.4, 1.0, curve: Curves.easeIn)),
    );

    // Start the entrance animation
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _setLoading(bool value) {
    if (!mounted) return;
    setState(() => _loading = value);
    debugPrint('SignUp: setLoading -> $_loading');
  }

  Future<void> _handleGoogle() async {
    debugPrint('SignUp: Google sign-up initiated.');
    _setLoading(true);
    try {
      debugPrint('SignUp: calling signInWithGoogle() from auth_impl.dart...');
      final cred = await signInWithGoogle(); // implement in auth_impl.dart
      if (cred == null) {
        debugPrint('SignUp: Google sign-in returned null (user cancelled).');
        _setLoading(false);
        return;
      }

      final user = cred.user;
      final displayName = user?.displayName ?? '';
      final email = user?.email ?? '';
      final photo = user?.photoURL ?? '';
      final split = displayName.split(' ');
      final first = split.isNotEmpty ? split.first : '';
      final last = split.length > 1 ? split.sublist(1).join(' ') : '';

      final Map<String, dynamic> userData = {
        'first_name': first,
        'last_name': last,
        'email': email,
        'photo_url': photo,
        'displayName': displayName,
        'uid': user?.uid ?? '',
      };

      debugPrint('SignUp: userData prepared -> $userData');

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen(userData: userData)),
      );
      debugPrint('SignUp: Navigation to MainScreen completed.');
    } catch (e, st) {
      debugPrint('SignUp: Google sign-in error: $e');
      debugPrint(st.toString());
    } finally {
      if (mounted) _setLoading(false);
      debugPrint('SignUp: Google flow finished -> loading: $_loading');
    }
  }

  Future<void> _handleApple() async {
    debugPrint('SignUp: Apple sign-up initiated.');
    _setLoading(true);
    try {
      debugPrint('SignUp: calling signInWithApple() from auth_impl.dart...');
      final cred = await signInWithApple(); // implement in auth_impl.dart
      if (cred == null) {
        debugPrint('SignUp: Apple sign-in returned null (cancelled / unavailable).');
        _setLoading(false);
        return;
      }

      final user = cred.user;
      final displayName = user?.displayName ?? '';
      final email = user?.email ?? '';
      final photo = user?.photoURL ?? '';
      final split = displayName.split(' ');
      final first = split.isNotEmpty ? split.first : '';
      final last = split.length > 1 ? split.sublist(1).join(' ') : '';

      final Map<String, dynamic> userData = {
        'first_name': first,
        'last_name': last,
        'email': email,
        'photo_url': photo,
        'displayName': displayName,
        'uid': user?.uid ?? '',
      };

      debugPrint('SignUp: userData prepared -> $userData');

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen(userData: userData)),
      );
      debugPrint('SignUp: Navigation to MainScreen completed.');
    } catch (e, st) {
      debugPrint('SignUp: Apple sign-in error: $e');
      debugPrint(st.toString());
    } finally {
      if (mounted) _setLoading(false);
      debugPrint('SignUp: Apple flow finished -> loading: $_loading');
    }
  }

  Widget _socialButton({
    required String label,
    required Widget icon,
    required VoidCallback onPressed,
    Color? background,
    Color? foreground,
    BorderSide? side,
    double elevation = 6,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : onPressed,
        icon: icon,
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: background ?? Colors.white,
          foregroundColor: foreground ?? Colors.black87,
          elevation: elevation,
          shadowColor: brandColor.withOpacity(0.18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: side ?? BorderSide(color: brandColor.withOpacity(0.12)),
        ),
      ),
    );
  }

  Widget _googleButton() {
    const googleIconUrl = 'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg';
    return _socialButton(
      label: 'Continue with Google',
      icon: Image.network(
        googleIconUrl,
        width: 22,
        height: 22,
        errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata),
      ),
      onPressed: _handleGoogle,
      background: Colors.white,
      foreground: Colors.black87,
      side: BorderSide(color: brandColor.withOpacity(0.14)),
      elevation: 6,
    );
  }

  Widget _appleButton() {
    final showApple = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS || kIsWeb;
    if (!showApple) return const SizedBox.shrink();
    return _socialButton(
      label: 'Continue with Apple',
      icon: const Icon(Icons.apple, size: 20),
      onPressed: _handleApple,
      background: Colors.black87,
      foreground: Colors.white,
      side: BorderSide(color: brandColor.withOpacity(0.10)),
      elevation: 6,
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('SignUp: build -> rendering SignUpScreen UI (loading=$_loading).');

    return Scaffold(
      backgroundColor: Colors.white, // user asked: background back to white
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final cardWidth = w < 500 ? w - 36 : (w < 900 ? 520.0 : 640.0);

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Animated logo / avatar area (logo fills the circle)
                    ScaleTransition(
                      scale: _logoScale,
                      child: Hero(
                        tag: 'app-logo-hero',
                        child: Container(
                          width: (w < 350) ? 88 : 112,
                          height: (w < 350) ? 88 : 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(color: brandColor.withOpacity(0.14), blurRadius: 18, offset: const Offset(0, 8)),
                              BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 4)),
                            ],
                            border: Border.all(color: brandColor, width: 3),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/Logo.png',
                              fit: BoxFit.cover, // make the image fill the avatar area
                              // If the image has transparency and you want a white background inside:
                              // color: Colors.white, colorBlendMode: BlendMode.dstOver,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Title / subtitle (dark since bg is white)
                    Text(
                      'Welcome to BoxHub',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.grey.shade900),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fast deliveries. Smart tracking. Local support.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 15, fontWeight: FontWeight.w500),
                    ),

                    const SizedBox(height: 20),

                    // Animated card with buttons (white card on white screen, but with shadow & rounded border)
                    SlideTransition(
                      position: _cardSlide,
                      child: FadeTransition(
                        opacity: _cardFade,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: brandColor.withOpacity(0.06)), // subtle border using brand color
                            boxShadow: [
                              BoxShadow(color: brandColor.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10)),
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                            child: Column(
                              children: [
                                _googleButton(),
                                const SizedBox(height: 12),
                                _appleButton(),
                                const SizedBox(height: 18),

                                // Divider with OR (OR color = brandColor)
                                Row(children: [
                                  Expanded(child: Divider(color: Colors.grey.shade300)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text('OR', style: TextStyle(color: brandColor, fontWeight: FontWeight.w800)),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey.shade300)),
                                ]),

                                const SizedBox(height: 18),

                                // Continue as guest -> updated style (not traditional)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _loading
                                        ? null
                                        : () {
                                      debugPrint('SignUp: Continue as guest pressed.');
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: brandColor.withOpacity(0.12),
                                      foregroundColor: brandColor,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      side: BorderSide(color: brandColor.withOpacity(0.06)),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 14),
                                      child: Text('Continue as Guest', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Already have account? Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ', style: TextStyle(color: Colors.grey.shade800)),
                        GestureDetector(
                          onTap: _loading
                              ? null
                              : () {
                            debugPrint('SignUp: Navigate to Login pressed.');
                            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: brandColor.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 6))],
                              border: Border.all(color: brandColor.withOpacity(0.10)),
                            ),
                            child: Text('Login', style: TextStyle(color: brandColor, fontWeight: FontWeight.w800)),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text('By continuing, you agree to our Terms & Privacy.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),

                    const SizedBox(height: 16),

                    // Loading overlay indicator (subtle)
                    if (_loading) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 44,
                        width: 44,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.6,
                          valueColor: AlwaysStoppedAnimation<Color>(brandColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
