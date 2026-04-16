import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'main.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'LoginScreen.dart'; // Add this import

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _idealController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final RegExp _passwordAllowedPattern =
      RegExp(r'^[a-zA-Z0-9!@#$%^&*(),.?":{}|<>]*$');
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isEmailChecking = false;
  bool _isEmailAvailable = false;
  bool _acceptedTerms = false;
  Timer? _emailDebounce;

  // Password validation state
  bool _hasMinLength = false;
  bool _hasValidChars = false;
  bool _passwordsMatch = false;
  String _passwordStrength = "Weak";

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordValidation);
    _confirmPasswordController.addListener(_updatePasswordValidation);
  }

  String _sanitizeNameInput(String value) {
    return value
        .replaceFirst(RegExp(r'^[^a-zA-Z]+'), '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');
  }

  bool _hasAllowedPasswordCharacters(String value) {
    return _passwordAllowedPattern.hasMatch(value);
  }

  void _updatePasswordValidation() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final hasMinLength = password.length >= 6;
    final hasValidChars =
        password.isNotEmpty && _hasAllowedPasswordCharacters(password);
    final passwordStrength = !hasMinLength || !hasValidChars
        ? "Weak"
        : password.length < 10
            ? "Medium"
            : "Strong";
    final passwordsMatch =
        confirmPassword.isNotEmpty && password == confirmPassword;

    if (_hasMinLength == hasMinLength &&
        _hasValidChars == hasValidChars &&
        _passwordStrength == passwordStrength &&
        _passwordsMatch == passwordsMatch) {
      return;
    }

    setState(() {
      _hasMinLength = hasMinLength;
      _hasValidChars = hasValidChars;
      _passwordStrength = passwordStrength;
      _passwordsMatch = passwordsMatch;
    });
  }

  Widget _buildValidationStatus(bool isValid, String text) {
    return Row(
      children: [
        Text(
          isValid ? '\u2713' : '\u2717',
          style: TextStyle(
            color: isValid ? Colors.green : Colors.red,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skip Button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    _skipRegistration();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Welcome Text
              Text(
                'Create Account',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join RoadWatch community to report road issues',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Registration Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Full Name Field
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: GoogleFonts.poppins(),
                        hintText: 'Enter your full name',
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          final sanitizedValue =
                              _sanitizeNameInput(newValue.text);
                          final selectionOffset =
                              sanitizedValue.length < newValue.selection.end
                                  ? sanitizedValue.length
                                  : newValue.selection.end;

                          return newValue.copyWith(
                            text: sanitizedValue,
                            selection: TextSelection.collapsed(
                              offset: selectionOffset,
                            ),
                            composing: TextRange.empty,
                          );
                        }),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }

                        final trimmed = value.trim();

                        if (!RegExp(r'^[a-zA-Z]').hasMatch(trimmed)) {
                          return 'Name must start with a letter';
                        }

                        if (_sanitizeNameInput(trimmed) != trimmed) {
                          return 'Invalid characters in name';
                        }

                        if (trimmed.length < 3) {
                          return 'Name must be at least 3 characters';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Email Field with availability check
                    Stack(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          style: GoogleFonts.poppins(),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) {
                            // reset availability while editing
                            setState(() {
                              _isEmailAvailable = false;
                            });

                            // debounce the check
                            _emailDebounce?.cancel();
                            // only check when the email looks valid (simple regex)
                            final emailPattern =
                                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                            if (emailPattern.hasMatch(value.trim())) {
                              _emailDebounce =
                                  Timer(const Duration(milliseconds: 500), () {
                                _checkEmailAvailability(value.trim());
                              });
                            } else {
                              // reset availability while still typing
                              setState(() => _isEmailAvailable = false);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: GoogleFonts.poppins(),
                            hintText: 'you@example.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            suffixIcon: _isEmailChecking
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : _isEmailAvailable
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                    : null,
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Mobile Number Field
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          child: const Text('+91'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _mobileController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              hintText: "Mobile Number",
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 18),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Mobile number is required';
                              }
                              if (value.length != 10) {
                                return 'Enter valid 10-digit mobile number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      style: GoogleFonts.poppins(),
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: GoogleFonts.poppins(),
                        hintText: 'At least 6 characters',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }

                        if (value.length < 6) {
                          return 'Minimum 6 characters required';
                        }

                        if (!_hasAllowedPasswordCharacters(value)) {
                          return 'Invalid characters in password';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Security Questions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Security Questions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        const Text('What is your first school name?'),
                        TextFormField(
                          controller: _schoolController,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Required'
                              : null,
                          decoration: const InputDecoration(
                            hintText: 'School Name',
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('Who is your ideal?'),
                        TextFormField(
                          controller: _idealController,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Required'
                              : null,
                          decoration: const InputDecoration(
                            hintText: 'Ideal Person',
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('What is your favorite place?'),
                        TextFormField(
                          controller: _placeController,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Required'
                              : null,
                          decoration: const InputDecoration(
                            hintText: 'Favorite Place',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Live Password Validation UI
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildValidationStatus(
                          _hasMinLength,
                          "At least 6 characters",
                        ),
                        _buildValidationStatus(
                          _hasValidChars,
                          "Valid characters only",
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Strength: $_passwordStrength",
                          style: TextStyle(
                            color: _passwordStrength == "Strong"
                                ? Colors.green
                                : _passwordStrength == "Medium"
                                    ? Colors.orange
                                    : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildValidationStatus(
                          _passwordsMatch,
                          "Passwords match",
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      style: GoogleFonts.poppins(),
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: GoogleFonts.poppins(),
                        hintText: 'Re-enter your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm password';
                        }

                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }

                        return null;
                      },
                    ),

                    // Terms & Conditions Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptedTerms = value ?? false;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'I agree to the ',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: GoogleFonts.poppins(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      _showMessage('Terms of Service page');
                                    },
                                ),
                                TextSpan(
                                  text: ' and ',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: GoogleFonts.poppins(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      _showMessage('Privacy Policy page');
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                'Create Account',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: Colors.grey[300], thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Or sign up with',
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: Colors.grey[300], thickness: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Social Sign Up Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                _showMessage('Google sign up coming soon'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.g_mobiledata,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Google',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                _showMessage('Facebook sign up coming soon'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.facebook,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Facebook',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Already have account - UPDATED
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: Colors.grey),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Skip option for users who don't want to register
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _skipRegistration,
                        child: const Text(
                          'Skip and continue',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptedTerms) {
        _showMessage('Please accept the Terms of Service to continue.');
        return;
      }
      setState(() => _isLoading = true);

      try {
        final response = await ApiService.register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        AuthService.currentUser = UserModel(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          mobile: _mobileController.text.trim(),
          school: _schoolController.text.trim(),
          ideal: _idealController.text.trim(),
          place: _placeController.text.trim(),
        );

        _showSuccessDialog(response['user']);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _checkEmailAvailability(String email) async {
    if (email.length < 5 || !email.contains('@') || !email.contains('.')) {
      return;
    }

    setState(() {
      _isEmailChecking = true;
      _isEmailAvailable = false;
    });

    try {
      await ApiService.checkEmail(email);

      if (!mounted) return;

      setState(() {
        _isEmailChecking = false;
        _isEmailAvailable = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEmailChecking = false;
          _isEmailAvailable = false;
        });
      }

      // show backend message if present
      final msg = e.toString().replaceAll('Exception: ', '');
      _showMessage(msg);
      // do not clear the field; user can correct it
    }
  }

  Future<void> _skipRegistration() async {
    await StorageService.setDemoMode(true);
    await StorageService.clearToken();
    if (!mounted) return;
    Navigator.pushReplacement(context, createRoute(const HomeScreen()));
  }

  void _showSuccessDialog(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              Text(
                'Account Created!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Welcome ${userData['name']} to RoadWatch community!',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Text(
                'Email: ${userData['email']}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Proceed to Login',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            const Text(
              'Registration Failed',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle()),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updatePasswordValidation);
    _confirmPasswordController.removeListener(_updatePasswordValidation);
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _schoolController.dispose();
    _idealController.dispose();
    _placeController.dispose();
    _emailDebounce?.cancel();
    super.dispose();
  }
}
