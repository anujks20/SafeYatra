import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  final String email;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.email,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  final TextEditingController _fullNameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _genderController =
      TextEditingController();

  final TextEditingController _ageController =
      TextEditingController();

  final TextEditingController _emergencyNameController =
      TextEditingController();

  final TextEditingController _emergencyPhoneController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    _emailController.text = widget.email;

    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    _ageController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result =
          await ApiService.getProfile(widget.userId);

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];

        if (data != null) {
          _fullNameController.text =
              data['full_name']?.toString() ?? '';

          _emailController.text =
              data['email']?.toString() ?? widget.email;

          _phoneController.text =
              data['phone']?.toString() ?? '';

          _genderController.text =
              data['gender']?.toString() ?? '';

          _ageController.text =
              data['age']?.toString() ?? '';

          _emergencyNameController.text =
              data['emergency_contact_name']?.toString() ?? '';

          _emergencyPhoneController.text =
              data['emergency_contact_phone']?.toString() ?? '';
        }
      } else {
        _showError(
          result['message'] ??
              'Failed to load profile',
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Error loading profile: $e');
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
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    final age =
        int.tryParse(_ageController.text.trim());

    setState(() {
      _isSaving = true;
    });

    try {
      final result =
          await ApiService.updateProfile(
        widget.userId,
        _phoneController.text.trim(),
        _genderController.text.trim(),
        age,
        _emergencyNameController.text.trim(),
        _emergencyPhoneController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _isEditing = false;
        });

        _showSuccess(
          'Profile updated successfully',
        );
      } else {
        _showError(
          result['message'] ??
              'Failed to update profile',
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Error updating profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // SNACKBARS
  // ============================================================

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeader(),

          const SizedBox(height: 24),

          _buildPersonalInformation(),

          const SizedBox(height: 20),

          _buildEmergencyContact(),

          const SizedBox(height: 30),

          _buildBottomButton(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildHeader() {
    final displayName =
        _fullNameController.text.isEmpty
            ? 'TravelBuddy User'
            : _fullNameController.text;

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.teal.withOpacity(0.2),
            border: Border.all(
              color: Colors.tealAccent,
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.person,
            size: 55,
            color: Colors.tealAccent,
          ),
        ),

        const SizedBox(height: 14),

        Text(
          displayName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          _emailController.text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PERSONAL INFORMATION
  // ============================================================

  Widget _buildPersonalInformation() {
    return _buildCard(
      title: 'Personal Information',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _buildTextField(
            controller: _fullNameController,
            label: 'Full Name',
            icon: Icons.person_outline,
            enabled: false,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            enabled: false,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            enabled: _isEditing,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _genderController,
            label: 'Gender',
            icon: Icons.person_outline,
            enabled: _isEditing,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _ageController,
            label: 'Age',
            icon: Icons.cake_outlined,
            keyboardType: TextInputType.number,
            enabled: _isEditing,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMERGENCY CONTACT
  // ============================================================

  Widget _buildEmergencyContact() {
    return _buildCard(
      title: 'Emergency Contact',
      icon: Icons.contact_emergency_outlined,
      child: Column(
        children: [
          _buildTextField(
            controller: _emergencyNameController,
            label: 'Emergency Contact Name',
            icon: Icons.person_outline,
            enabled: _isEditing,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _emergencyPhoneController,
            label: 'Emergency Contact Number',
            icon: Icons.phone_in_talk_outlined,
            keyboardType: TextInputType.phone,
            enabled: _isEditing,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2A3A)
            .withOpacity(0.92),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.tealAccent,
              ),

              const SizedBox(width: 10),

              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          child,
        ],
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
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(
        color: enabled
            ? Colors.white
            : Colors.white.withOpacity(0.65),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color:
              Colors.white.withOpacity(0.6),
        ),

        prefixIcon: Icon(
          icon,
          color: enabled
              ? Colors.tealAccent
              : Colors.grey,
        ),

        filled: true,

        fillColor: enabled
            ? const Color(0xFF223346)
            : Colors.black.withOpacity(0.12),

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

        disabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                Colors.white.withOpacity(0.04),
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.tealAccent,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EDIT / SAVE BUTTON
  // ============================================================

  Widget _buildBottomButton() {
    if (_isEditing) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      setState(() {
                        _isEditing = false;
                      });

                      _loadProfile();
                    },
              style:
                  OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                foregroundColor:
                    Colors.white,
                side: BorderSide(
                  color: Colors.white
                      .withOpacity(0.3),
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: ElevatedButton(
              onPressed:
                  _isSaving ? null : _saveProfile,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.tealAccent,
                foregroundColor:
                    Colors.black,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _isEditing = true;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              Colors.tealAccent,
          foregroundColor:
              Colors.black,
          padding:
              const EdgeInsets.symmetric(
            vertical: 16,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.edit),
        label: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }
}