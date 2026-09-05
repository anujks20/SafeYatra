import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/api_service.dart';
import '../utils/snackbar_utils.dart';

import 'home_screen.dart';
import 'setup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLogin = true;
  bool _isLoading = false;

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final TextEditingController _nameController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.3,
          1.0,
          curve: Curves.easeInOut,
        ),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.3,
          1.0,
          curve: Curves.easeOut,
        ),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleForm() {
    setState(() {
      _isLogin = !_isLogin;
      _controller.reset();
      _controller.forward();
    });
  }

  // ============================================================
  // SAVE FCM TOKEN FOR USER
  // ============================================================

  Future<void> _saveFCMTokenForUser(int userId) async {
    try {
      final String? fcmToken =
          await FirebaseMessaging.instance.getToken();

      if (fcmToken == null || fcmToken.isEmpty) {
        print('=================================');
        print('FCM TOKEN IS NULL OR EMPTY');
        print('USER ID: $userId');
        print('=================================');
        return;
      }

      print('=================================');
      print('SAVING FCM TOKEN FOR USER: $userId');
      print('FCM TOKEN: $fcmToken');
      print('=================================');

      final fcmResult =
          await ApiService.saveFCMToken(
        userId,
        fcmToken,
      );

      print('FCM TOKEN SAVE RESULT: $fcmResult');

      if (fcmResult['success'] == true) {
        print(
          'FCM token saved successfully '
          'for user $userId',
        );
      } else {
        print(
          'Failed to save FCM token: '
          '${fcmResult['message']}',
        );
      }
    } catch (e) {
      print(
        'ERROR GETTING/SAVING FCM TOKEN: $e',
      );
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      SnackbarUtils.showErrorSnackBar(
        context,
        'Please fill in all fields',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] != true) {
        SnackbarUtils.showErrorSnackBar(
          context,
          result['message'] ?? 'Login failed',
        );
        return;
      }

      final dynamic rawUserId = result['user_id'];

      final int userId = rawUserId is int
          ? rawUserId
          : int.tryParse(rawUserId.toString()) ?? 0;

      if (userId <= 0) {
        SnackbarUtils.showErrorSnackBar(
          context,
          'Invalid user ID received from server',
        );
        return;
      }

      // ========================================================
      // SAVE FCM TOKEN FOR THIS USER
      // ========================================================

      await _saveFCMTokenForUser(userId);

      final String email =
          result['email']?.toString() ??
              _emailController.text.trim();

      final String fullName =
          result['full_name']?.toString() ?? email;

      SnackbarUtils.showSuccessSnackBar(
        context,
        result['message'] ?? 'Login successful',
      );

      // ========================================================
      // CHECK PROFILE COMPLETION
      // ========================================================

      final profileResult =
          await ApiService.getProfile(userId);

      if (!mounted) return;

      bool isProfileCompleted = false;

      if (profileResult['success'] == true) {
        final data = profileResult['data'];

        if (data is Map<String, dynamic>) {
          isProfileCompleted =
              data['profile_completed'] == true;
        }
      }

      if (isProfileCompleted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userId: userId,
              email: email,
              name: fullName,
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => SetupScreen(
              userId: userId,
              email: email,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(
          context,
          'Login error: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> _handleRegister() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      SnackbarUtils.showErrorSnackBar(
        context,
        'Please fill in all fields',
      );
      return;
    }

    if (_passwordController.text !=
        _confirmPasswordController.text) {
      SnackbarUtils.showErrorSnackBar(
        context,
        'Passwords do not match',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _confirmPasswordController.text,
      );

      if (!mounted) return;

      if (result['success'] != true) {
        SnackbarUtils.showErrorSnackBar(
          context,
          result['message'] ?? 'Registration failed',
        );
        return;
      }

      final dynamic rawUserId = result['user_id'];

      final int userId = rawUserId is int
          ? rawUserId
          : int.tryParse(rawUserId.toString()) ?? 0;

      if (userId <= 0) {
        SnackbarUtils.showErrorSnackBar(
          context,
          'Invalid user ID received from server',
        );
        return;
      }

      // ========================================================
      // SAVE FCM TOKEN IMMEDIATELY AFTER REGISTRATION
      // ========================================================

      await _saveFCMTokenForUser(userId);

      final String email =
          result['email']?.toString() ??
              _emailController.text.trim();

      SnackbarUtils.showSuccessSnackBar(
        context,
        result['message'] ??
            'User registered successfully',
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SetupScreen(
            userId: userId,
            email: email,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(
          context,
          'Registration error: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1B263B),
              Color(0xFF415A77),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -size.width * 0.2,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -size.width * 0.3,
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal.withOpacity(0.1),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    _buildHeader(),

                    const SizedBox(height: 40),

                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: AnimatedSwitcher(
                          duration: const Duration(
                            milliseconds: 500,
                          ),
                          child: _isLogin
                              ? _buildLoginForm()
                              : _buildRegisterForm(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    _buildToggleSection(),

                    const SizedBox(height: 20),

                    _buildDivider(),

                    const SizedBox(height: 20),

                    _buildGoogleButton(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _isLogin
          ? Column(
              key: const ValueKey('login_header'),
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.teal,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: Colors.teal[100],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome To TravelBuddy',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue your journey',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            )
          : Column(
              key: const ValueKey('register_header'),
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.teal,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.person_add_alt_1,
                    size: 40,
                    color: Colors.teal[100],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join us to start your adventure',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
    );
  }

  // ============================================================
  // LOGIN FORM
  // ============================================================

  Widget _buildLoginForm() {
    return Container(
      key: const ValueKey('login_form'),
      padding: const EdgeInsets.all(20),
      decoration: _formDecoration(),
      child: Column(
        children: [
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 24),
          _buildSubmitButton(
            text: 'Sign In',
            onPressed: _handleLogin,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REGISTER FORM
  // ============================================================

  Widget _buildRegisterForm() {
    return Container(
      key: const ValueKey('register_form'),
      padding: const EdgeInsets.all(20),
      decoration: _formDecoration(),
      child: Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            icon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 24),
          _buildSubmitButton(
            text: 'Create Account',
            onPressed: _handleRegister,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORM DECORATION
  // ============================================================

  BoxDecoration _formDecoration() {
    return BoxDecoration(
      color: Colors.grey[900]!.withOpacity(0.5),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.teal.withOpacity(0.3),
      ),
    );
  }

  // ============================================================
  // SUBMIT BUTTON
  // ============================================================

  Widget _buildSubmitButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(text),
      ),
    );
  }

  // ============================================================
  // TOGGLE
  // ============================================================

  Widget _buildToggleSection() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.teal.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isLogin
                ? "Don't have an account?"
                : 'Already have an account?',
            style: TextStyle(
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoading ? null : _toggleForm,
            child: Text(
              _isLogin ? 'Sign Up' : 'Sign In',
              style: TextStyle(
                color: Colors.teal[200],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIVIDER
  // ============================================================

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey[700],
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: Text(
            'or continue with',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey[700],
            thickness: 1,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // GOOGLE BUTTON
  // ============================================================

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          SnackbarUtils.showErrorSnackBar(
            context,
            'Google Sign-In is not implemented yet',
          );
        },
        icon: Image.asset(
          'assets/google.png',
          width: 24,
          height: 24,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) =>
              Icon(
            Icons.g_mobiledata,
            size: 24,
            color: Colors.grey[300],
          ),
        ),
        label: Text(
          'Sign in with Google',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[900],
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          padding: const EdgeInsets.symmetric(
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        color: Colors.grey[100],
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[400],
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.teal[200],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[700]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[700]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.teal,
          ),
        ),
        filled: true,
        fillColor:
            Colors.grey[800]!.withOpacity(0.3),
      ),
    );
  }
}