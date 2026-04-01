import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // If true, show the email/password login form.
  // If false, show the "Landing" view.
  bool _showLoginForm = false;
  int _logoTapCount = 0;
  bool _isEasterEggVisible = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await context.read<AuthProvider>().signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      if (!success && mounted) {
        final error = context.read<AuthProvider>().error;
        shadcn.showToast(
          context: context,
          builder: (context, overlay) {
            return shadcn.SurfaceCard(
              child: shadcn.Basic(
                title: const Text('Login Failed'),
                subtitle: Text(error ?? 'Unknown error occurred'),
                trailing: shadcn.Button(
                  onPressed: () => overlay.close(),
                  style: const shadcn.ButtonStyle.ghost(
                    density: shadcn.ButtonDensity.icon,
                  ),
                  child: const Icon(Icons.close, size: 16),
                ),
              ),
            );
          },
        );
      }
    }
  }

  void _handleGoogleLogin() async {
    final success = await context.read<AuthProvider>().signInWithGoogle();
    if (!success && mounted) {
      final error = context.read<AuthProvider>().error;
      shadcn.showToast(
        context: context,
        builder: (context, overlay) {
          return shadcn.SurfaceCard(
            child: shadcn.Basic(
              title: const Text('Google Sign-In Failed'),
              subtitle: Text(error ?? 'Unknown error occurred'),
              trailing: shadcn.Button(
                onPressed: () => overlay.close(),
                style: const shadcn.ButtonStyle.ghost(
                  density: shadcn.ButtonDensity.icon,
                ),
                child: const Icon(Icons.close, size: 16),
              ),
            ),
          );
        },
      );
    }
  }

  void _handleLogoTap() {
    if (_isEasterEggVisible) return;

    _logoTapCount++;
    if (_logoTapCount < 5) return;

    _logoTapCount = 0;
    _showDeveloperEasterEgg();
  }

  Future<void> _showDeveloperEasterEgg() async {
    if (!mounted || _isEasterEggVisible) return;

    _isEasterEggVisible = true;
    final navigator = Navigator.of(context, rootNavigator: true);

    Future<void>.delayed(const Duration(seconds: 4), () {
      if (_isEasterEggVisible && navigator.mounted && navigator.canPop()) {
        navigator.pop();
      }
    });

    await showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: 'Developer easter egg',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF111827).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Text(
              'Developed by abhinav krishna',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );

    _isEasterEggVisible = false;
  }

  Widget _buildLogo({
    required double size,
    required double iconSize,
    required double borderRadius,
    EdgeInsetsGeometry? margin,
    List<BoxShadow>? boxShadow,
  }) {
    return GestureDetector(
      onTap: _handleLogoTap,
      child: Container(
        width: size,
        height: size,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
          boxShadow: boxShadow,
        ),
        child: Icon(
          Icons.account_balance_wallet_outlined,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showLoginForm) {
      return _buildLoginForm(context);
    } else {
      return _buildLandingPage(context);
    }
  }

  Widget _buildLandingPage(BuildContext context) {
    // Matches the "Landing Screen" design
    return shadcn.Scaffold(
      child: Stack(
        children: [
          // Background Gradient Blobs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGradient.colors.first.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGradient.colors.last.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    _buildLogo(
                      size: 96,
                      iconSize: 48,
                      borderRadius: 24,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.05),
                          blurRadius: 24,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Title
                    Text(
                      'SpendWise',
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Hero Text
                    Text(
                      'Track expenses\neffortlessly with AI',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Just speak or snap a photo of your receipts. Let our AI handle the rest.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFA1A1AA), // text-muted-foreground
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Buttons
                    Column(
                      children: [
                        // Google Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: shadcn.Button(
                            style: const shadcn.ButtonStyle.secondary(),
                            onPressed: _handleGoogleLogin,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google Icon
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Image.network(
                                    'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.g_mobiledata, size: 24),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Continue with Google',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Email Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: shadcn.Button(
                            style: const shadcn.ButtonStyle.primary(),
                            onPressed: () async {
                              // "Continue with Email" -> Goes to Signup Page
                              final createdEmail = await Navigator.of(context).push<String>(
                                MaterialPageRoute(
                                  builder: (_) => const SignupPage(),
                                ),
                              );

                              if (!mounted) return;
                              if (createdEmail != null && createdEmail.trim().isNotEmpty) {
                                setState(() {
                                  _showLoginForm = true;
                                  _emailController.text = createdEmail.trim();
                                  _passwordController.clear();
                                });
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.mail_outline, size: 20, color: Colors.black),
                                const SizedBox(width: 12),
                                Text(
                                  'Continue with Email',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black, // Primary foreground
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Footer
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showLoginForm = true;
                        });
                      },
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFA1A1AA),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: 'Sign In',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    // Reuses the card style from Signup but for Login
    return shadcn.Scaffold(
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Header
                      Column(
                        children: [
                          _buildLogo(
                            size: 80,
                            iconSize: 40,
                            borderRadius: 20,
                            margin: const EdgeInsets.only(bottom: 24),
                          ),
                          Text(
                            'SpendWise',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Track smarter, spend wiser.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Card
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.transparent, // Glass effect
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Welcome back',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Enter your details to sign in',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Email
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(left: 12, right: 8),
                                        child: Icon(Icons.mail_outline, size: 18, color: Colors.grey),
                                      ),
                                      Expanded(
                                        child: shadcn.TextField(
                                          controller: _emailController,
                                          placeholder: const Text('m@example.com'),
                                          keyboardType: TextInputType.emailAddress,
                                          border: const Border.fromBorderSide(BorderSide.none),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Password
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Password',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(left: 12, right: 8),
                                        child: Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                                      ),
                                      Expanded(
                                        child: shadcn.TextField(
                                          controller: _passwordController,
                                          obscureText: true,
                                          placeholder: const Text('••••••••'),
                                          border: const Border.fromBorderSide(BorderSide.none),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Sign In Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return shadcn.Button(
                                    style: const shadcn.ButtonStyle.primary(),
                                    onPressed: auth.isLoading ? null : _handleLogin,
                                    child: Center(
                                      child: auth.isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.black,
                                              ),
                                            )
                                          : Text(
                                              'Sign In',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'OR',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.55),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return shadcn.Button(
                                    style: const shadcn.ButtonStyle.secondary(),
                                    onPressed: auth.isLoading ? null : _handleGoogleLogin,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Image.network(
                                            'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.g_mobiledata, size: 24),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Continue with Google',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Back Button
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: shadcn.Button(
                style: const shadcn.ButtonStyle.ghost(density: shadcn.ButtonDensity.icon),
                child: const Icon(Icons.arrow_back, size: 20),
                onPressed: () {
                   setState(() {
                     _showLoginForm = false;
                   });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

