import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  final int userId;
  final String email;

  const SetupScreen({
    super.key,
    required this.userId,
    required this.email,
  });

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _genderController =
      TextEditingController();

  final TextEditingController _ageController =
      TextEditingController();

  final TextEditingController _mobileNumberController =
      TextEditingController();

  final TextEditingController _emergencyNameController =
      TextEditingController();

  final TextEditingController _emergencyNumberController =
      TextEditingController();

  bool _isLoading = false;
  int _currentStep = 0;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Color get _accent => Colors.tealAccent.shade400;

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

    _nameController.dispose();
    _genderController.dispose();
    _ageController.dispose();
    _mobileNumberController.dispose();
    _emergencyNameController.dispose();
    _emergencyNumberController.dispose();

    super.dispose();
  }

  // ============================================================
  // SUBMIT SETUP
  // ============================================================

  Future<void> _submitSetup() async {
    final int? age =
        int.tryParse(_ageController.text.trim());

    if (age == null) {
      _showError('Please enter a valid age');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result =
          await ApiService.updateProfile(
        widget.userId,
        _mobileNumberController.text.trim(),
        _genderController.text.trim(),
        age,
        _emergencyNameController.text.trim(),
        _emergencyNumberController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userId: widget.userId,
              email: widget.email,
              name: _nameController.text.trim().isNotEmpty
                  ? _nameController.text.trim()
                  : widget.email,
            ),
          ),
        );
      } else {
        _showError(
          result['message'] ??
              'Failed to complete profile setup',
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Setup error: $e');
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
  // CONTINUE
  // ============================================================

  void _continue() {
    bool isValid = true;

    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().isEmpty ||
            _genderController.text.trim().isEmpty ||
            _ageController.text.trim().isEmpty ||
            int.tryParse(
                  _ageController.text.trim(),
                ) ==
                null) {
          isValid = false;
        }
        break;

      case 1:
        if (_mobileNumberController.text.trim().length !=
                10 ||
            _emergencyNameController.text
                .trim()
                .isEmpty ||
            _emergencyNumberController.text
                    .trim()
                    .length !=
                10) {
          isValid = false;
        }
        break;
    }

    if (!isValid) {
      _showError(
        'Please fill all required fields correctly',
      );
      return;
    }

    if (_currentStep < 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _submitSetup();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
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
            colors: [
              Color(0xFF0E1A24),
              Color(0xFF162534),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -size.width * 0.25,
              left: -size.width * 0.25,
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal.withOpacity(0.08),
                ),
              ),
            ),

            Positioned(
              bottom: -size.width * 0.25,
              right: -size.width * 0.25,
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal.withOpacity(0.08),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          _buildHeader(),

                          const SizedBox(height: 30),

                          _buildProgressIndicator(),

                          const SizedBox(height: 30),

                          AnimatedSwitcher(
                            duration: const Duration(
                              milliseconds: 300,
                            ),
                            child: _currentStep == 0
                                ? _buildPersonalInfo()
                                : _buildContactInfo(),
                          ),

                          const SizedBox(height: 30),

                          _buildButtons(),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
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
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.15),
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color:
                      Colors.teal.withOpacity(0.4),
                ),
              ),
              child: Icon(
                Icons.person_add_alt_1,
                color: _accent,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Complete Your Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Help us keep your journey safer',
                    style: TextStyle(
                      color: Colors.white
                          .withOpacity(0.65),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Text(
          widget.email,
          style: TextStyle(
            color:
                Colors.tealAccent.shade100,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          children: [
            _buildStepDot(0),
            Expanded(
              child: Container(
                height: 2,
                color: _currentStep >= 1
                    ? _accent
                    : Colors.white24,
              ),
            ),
            _buildStepDot(1),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Personal Info',
              style: TextStyle(
                color: _currentStep == 0
                    ? Colors.white
                    : Colors.white54,
                fontSize: 12,
              ),
            ),
            Text(
              'Emergency Contact',
              style: TextStyle(
                color: _currentStep == 1
                    ? Colors.white
                    : Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepDot(int step) {
    final bool active =
        step <= _currentStep;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? _accent
            : const Color(0xFF223346),
      ),
      child: Center(
        child: active && step < _currentStep
            ? const Icon(
                Icons.check,
                color: Colors.black,
                size: 18,
              )
            : Text(
                '${step + 1}',
                style: TextStyle(
                  color: active
                      ? Colors.black
                      : Colors.white,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // ============================================================
  // STEP 1
  // ============================================================

  Widget _buildPersonalInfo() {
    return Container(
      key: const ValueKey('personal'),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Tell us a little about yourself',
            style: TextStyle(
              color:
                  Colors.white.withOpacity(0.6),
            ),
          ),

          const SizedBox(height: 24),

          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline,
          ),

          const SizedBox(height: 18),

          _buildDropdownField(
            controller: _genderController,
            label: 'Gender',
            icon: Icons.person_outline,
            items: const [
              'Male',
              'Female',
              'Other',
              'Prefer not to say',
            ],
          ),

          const SizedBox(height: 18),

          _buildTextField(
            controller: _ageController,
            label: 'Age',
            icon: Icons.cake_outlined,
            keyboardType:
                TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter
                  .digitsOnly,
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 2
  // ============================================================

  Widget _buildContactInfo() {
    return Container(
      key: const ValueKey('contact'),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact & Emergency Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'These details can help during emergencies',
            style: TextStyle(
              color:
                  Colors.white.withOpacity(0.6),
            ),
          ),

          const SizedBox(height: 24),

          _buildTextField(
            controller: _mobileNumberController,
            label: 'Mobile Number',
            icon: Icons.phone_outlined,
            keyboardType:
                TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter
                  .digitsOnly,
              LengthLimitingTextInputFormatter(
                10,
              ),
            ],
          ),

          const SizedBox(height: 18),

          _buildTextField(
            controller: _emergencyNameController,
            label: 'Emergency Contact Name',
            icon: Icons.contact_emergency_outlined,
          ),

          const SizedBox(height: 18),

          _buildTextField(
            controller:
                _emergencyNumberController,
            label: 'Emergency Contact Number',
            icon: Icons.phone_in_talk_outlined,
            keyboardType:
                TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter
                  .digitsOnly,
              LengthLimitingTextInputFormatter(
                10,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUTTONS
  // ============================================================

  Widget _buildButtons() {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: OutlinedButton(
              onPressed:
                  _isLoading ? null : _back,
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                side: BorderSide(
                  color:
                      Colors.white.withOpacity(0.3),
                ),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back'),
            ),
          ),

          const SizedBox(width: 12),
        ],

        Expanded(
          child: ElevatedButton(
            onPressed:
                _isLoading ? null : _continue,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Text(
                    _currentStep == 1
                        ? 'Complete Setup'
                        : 'Continue',
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DECORATION
  // ============================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF1C2A3A)
          .withOpacity(0.9),
      borderRadius:
          BorderRadius.circular(20),
      border: Border.all(
        color:
            Colors.white.withOpacity(0.08),
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
    List<TextInputFormatter>?
        inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15.5,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color:
              Colors.white.withOpacity(0.72),
        ),
        prefixIcon: Icon(
          icon,
          color:
              Colors.tealAccent.withOpacity(0.8),
        ),
        filled: true,
        fillColor: const Color(
          0xFF223346,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                Colors.white.withOpacity(0.08),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                Colors.white.withOpacity(0.22),
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> items,
  }) {
    return DropdownButtonFormField<String>(
      value: controller.text.isEmpty
          ? null
          : controller.text,
      dropdownColor:
          const Color(0xFF223346),
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color:
              Colors.white.withOpacity(0.72),
        ),
        prefixIcon: Icon(
          icon,
          color:
              Colors.tealAccent.withOpacity(0.8),
        ),
        filled: true,
        fillColor:
            const Color(0xFF223346),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                Colors.white.withOpacity(0.08),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                Colors.white.withOpacity(0.22),
          ),
        ),
      ),
      items: items
          .map(
            (value) =>
                DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          controller.text = value ?? '';
        });
      },
      icon: const Icon(
        Icons.arrow_drop_down,
        color: Colors.white,
      ),
    );
  }
}