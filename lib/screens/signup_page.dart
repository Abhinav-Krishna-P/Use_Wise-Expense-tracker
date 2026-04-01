import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    setState(() => _errorMessage = null);

      if (_nameController.text.isEmpty) {
         setState(() => _errorMessage = "Name is required");
         return;
      }
      
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() => _errorMessage = "Passwords do not match");
        return;
      }
      
      final success = await context.read<AuthProvider>().signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _nameController.text.trim(),
          );
          
      if (success) {
        if (mounted) {
           Navigator.of(context).pop(_emailController.text.trim()); // Prefill login email.
           shadcn.showToast(
            context: context,
            builder: (context, overlay) {
              return shadcn.SurfaceCard(
                child: shadcn.Basic(
                  title: const Text('Account Created'),
                  subtitle: const Text('Please sign in with your new account'),
                  trailing: shadcn.Button(
                    onPressed: () => overlay.close(),
                    style: const shadcn.ButtonStyle.ghost(
                        density: shadcn.ButtonDensity.icon
                    ),
                    child: const Icon(Icons.close, size: 16),
                  ),
                ),
              );
            },
          );
        }
      } else {
        if (mounted) {
           setState(() => _errorMessage = context.read<AuthProvider>().error);
        }
      }
  }
  
  @override
  Widget build(BuildContext context) {
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       // Header
                      Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 40,
                              color: Colors.white,
                            ),
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
                        ]
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
                              'Create an account',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Enter your details to get started today',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                             if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.red),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: AppTheme.red),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            const SizedBox(height: 24),
                            
                            // Form Fields
                             // Full Name
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Full Name',
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
                                        child: Icon(Icons.person_outline, size: 18, color: Colors.grey),
                                      ),
                                      Expanded(
                                        child: shadcn.TextField(
                                          controller: _nameController,
                                          placeholder: const Text('John Doe'),
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
                            const SizedBox(height: 16),

                            // Confirm Password
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Confirm Password',
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
                                          controller: _confirmPasswordController,
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
                            
                            // Sign Up Button
                            Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                return SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: shadcn.Button(
                                    style: const shadcn.ButtonStyle.primary(),
                                    onPressed: auth.isLoading ? null : _handleSignup,
                                    child: auth.isLoading
                                         ? const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            )
                                          : Center(
                                            child: Text(
                                              'Sign Up',
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      // Footer Link
                      GestureDetector(
                        onTap: () {
                          // Go back to Login
                          Navigator.of(context).pop();
                        },
                         child: RichText(
                          text: TextSpan(
                            text: 'Create a new account? ',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFA1A1AA),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign in',
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
          ),
          
          // Back Button
           Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: shadcn.Button(
                style: const shadcn.ButtonStyle.ghost(density: shadcn.ButtonDensity.icon),
                child: const Icon(Icons.arrow_back, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
