// lib/screens/signup_screen.dart
import 'package:boxhub/screens/login_screen.dart';
import 'package:boxhub/screens/main_screen.dart';
import 'package:boxhub/services/auth_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart'; // optional if you want to read flags

class SignUpScreen extends StatefulWidget {
  final bool firebaseInitialized;
  const SignUpScreen({Key? key, required this.firebaseInitialized}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  bool _loading = false;
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    debugPrint('SignUp: initState -> building Sign Up screen.');
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _logoScale = Tween<double>(begin: 1.0, end: 1.04).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  void _setLoading(bool v) {
    if (!mounted) return;
    setState(() => _loading = v);
    if (v) {
      _logoController.repeat(reverse: true);
    } else {
      _logoController.reset();
    }
    debugPrint('SignUp: setLoading -> $_loading');
  }

  Future<void> _handleGoogle() async {
    debugPrint('SignUp: Google sign-up initiated.');
    _setLoading(true);
    try {
      debugPrint('SignUp: calling signInWithGoogle() from auth_impl.dart...');
      final cred = await signInWithGoogle(); // from your auth_impl.dart (already saved earlier)
      if (cred == null) {
        debugPrint('SignUp: Google sign-in returned null (user cancelled the flow).');
        _setLoading(false);
        return;
      }

      debugPrint('SignUp: Google credential returned user=${cred.user?.uid}');
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
      debugPrint('SignUp: Google sign-in successful. Navigating to MainScreen...');

      // Navigate to MainScreen and replace the current route (no back to signup)
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
      final cred = await signInWithApple(); // from your auth_impl.dart
      if (cred == null) {
        debugPrint('SignUp: Apple sign-in cancelled or unavailable.');
        _setLoading(false);
        return;
      }

      debugPrint('SignUp: Apple sign-in succeeded for uid=${cred.user?.uid}');
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
      debugPrint('SignUp: Apple sign-in successful. Navigating to MainScreen...');

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
    Color? bg,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : onPressed,
        icon: icon,
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg ?? Colors.white,
          foregroundColor: bg != null ? Colors.white : Colors.black87,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: bg == null ? BorderSide(color: Colors.grey.shade200) : null,
        ),
      ),
    );
  }

  Widget _googleButton() {
    const googleIconUrl = 'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg';
    return _socialButton(
      label: 'Continue with Google',
      icon: Image.network(googleIconUrl, width: 20, height: 20, errorBuilder: (c,e,s) => const Icon(Icons.g_mobiledata)),
      onPressed: _handleGoogle,
    );
  }

  Widget _appleButton() {
    final showApple = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS || kIsWeb;
    if (!showApple) return const SizedBox.shrink();
    return _socialButton(
      label: 'Continue with Apple',
      icon: const Icon(Icons.apple, size: 20),
      onPressed: _handleApple,
      bg: Colors.black87,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary; // will use #4A148C
    debugPrint('SignUp: build -> rendering SignUpScreen UI (loading=$_loading).');
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final cardWidth = w < 500 ? w : (w < 900 ? 520.0 : 640.0);

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Animated circle logo (use your asset logo or keep an icon)
                    ScaleTransition(
                      scale: _logoScale,
                      child: Hero(
                        tag: 'app-logo-hero',
                        child: CircleAvatar(
                          radius: (w < 350) ? 44 : 56,
                          backgroundColor: primary,
                          child: const Icon(Icons.local_shipping, size: 36, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Welcome to BoxHub',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create your account and start receiving deliveries',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),

                    // Card with social buttons and small info
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                        child: Column(
                          children: [
                            _googleButton(),
                            const SizedBox(height: 12),
                            _appleButton(),
                            const SizedBox(height: 18),

                            // Divider with OR text
                            Row(children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text('OR', style: TextStyle(color: Colors.grey.shade500)),
                              ),
                              const Expanded(child: Divider()),
                            ]),

                            const SizedBox(height: 18),

                            // Optional: Continue as guest (small)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _loading ? null : () {
                                  debugPrint('SignUp: Continue as guest pressed.');
                                  // navigate to login or home if you prefer guest flow
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Text('Continue as Guest', style: TextStyle(fontSize: 16)),
                                ),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bottom text: "Already have an account? Login"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ', style: TextStyle(color: Colors.grey.shade700)),
                        GestureDetector(
                          onTap: _loading ? null : () {
                            debugPrint('SignUp: Navigate to Login pressed.');
                            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('By continuing, you agree to our Terms & Privacy.', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    const SizedBox(height: 6),
                    if (_loading) ...[
                      const SizedBox(height: 12),
                      const CircularProgressIndicator()
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
