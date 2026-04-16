import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';
import 'reports_screen.dart';
import 'alerts_screen.dart';
import 'LoginScreen.dart';
import 'admin_dashboard.dart';

import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'User';
  String _email = '';
  String _mobile = '';
  String _role = 'user';
  bool _isDemo = false;
  Map<String, int> _stats = {
    'reports': 0,
    'verified': 0,
    'upvotes': 0,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authOk = await AuthService.isAuthenticatedOrDemo();
      if (!authOk) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        return;
      }
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    final demoMode = await StorageService.isDemoMode();
    final token = await StorageService.getToken();
    final useDemo = demoMode || token == null || token.isEmpty;

    if (useDemo) {
      if (!mounted) return;
      setState(() {
        _isDemo = true;
        _role = 'demo';
        _name = DemoDataProvider.demoUser['name'] ?? 'Guest User';
        _email = DemoDataProvider.demoUser['email'] ?? 'guest@roadwatch.demo';
        _mobile = DemoDataProvider.demoUser['mobile'] ?? '';
        _stats = Map<String, int>.from(DemoDataProvider.stats);
      });
      return;
    }

    var name = await StorageService.getName();
    var email = await StorageService.getEmail();
    var role = await StorageService.getRole();

    // Load mobile from AuthService
    var mobile = AuthService.currentUser?.mobile ?? '';

    if ((name == null || name.isEmpty)) {
      if (token != null) {
        try {
          final profile = await ApiService.getProfile();
          if (profile != null) {
            name = profile['name'];
            email = profile['email'];
            await StorageService.saveLoginData(
              token: token,
              name: name ?? '',
              email: email ?? '',
            );
          }
        } catch (e) {
          // ignore, we'll fall back to saved values
        }
      }
    }

    try {
      final dashboard = await ApiService.getDashboard();
      _stats = {
        'reports': dashboard['reports'] ?? 0,
        'verified': dashboard['verified'] ?? 0,
        'upvotes': dashboard['upvotes'] ?? 0,
      };
    } catch (_) {
      // ignore dashboard errors
    }

    if (!mounted) return;

    setState(() {
      _isDemo = false;
      _role = role ?? 'user';
      _name = name ?? 'User';
      _email = email ?? '';
      _mobile = mobile;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // Profile Header Card
            _buildProfileHeader(context),
            const SizedBox(height: 28),

            // Stats Section
            _buildStatsSection(context),
            const SizedBox(height: 28),

            // Theme Selector
            _buildThemeSelector(context),
            const SizedBox(height: 20),

            // Settings Items
            _buildActionItem(
              context,
              'Edit Profile',
              Icons.edit_rounded,
              () => _editProfile(),
            ),
            _buildActionItem(
              context,
              'Settings',
              Icons.settings_rounded,
              () => _openPlaceholder(
                title: 'Settings',
                message: 'Settings screen is under construction.',
              ),
            ),
            _buildActionItem(
              context,
              'Help & Support',
              Icons.help_outline_rounded,
              () => _openPlaceholder(
                title: 'Help & Support',
                message: 'Support resources will be available soon.',
              ),
            ),

            if (_role == 'admin')
              _buildActionItem(
                context,
                'Admin Panel',
                Icons.admin_panel_settings_rounded,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminDashboard()),
                ),
              ),

            // Logout
            _buildActionItem(
              context,
              'Logout',
              Icons.logout_rounded,
              () async {
                await AuthService.logout();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              isLogout: true,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue,
            AppTheme.primaryBlueDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.25),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          // Avatar with gradient background
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Name
          Text(
            _name,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),

          // Email
          Text(
            _email,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),

          // Mobile
          Text(
            _mobile.isNotEmpty ? '+91 $_mobile' : '',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.8),
            ),
          ),

          if (_isDemo)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Demo mode',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatPill(
          context,
          '${_stats['reports'] ?? 0}',
          'Reports',
          Icons.assessment_outlined,
        ),
        _buildStatPill(
          context,
          '${_stats['verified'] ?? 0}',
          'Verified',
          Icons.verified_user_outlined,
        ),
        _buildStatPill(
          context,
          '${_stats['upvotes'] ?? 0}',
          'Upvotes',
          Icons.thumb_up_outlined,
        ),
      ],
    );
  }

  Widget _buildStatPill(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkElevatedSurface : AppTheme.lightCardBg,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
          border: Border.all(
            color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkElevatedSurface : AppTheme.lightCardBg,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
            border: Border.all(
              color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.dark_mode_rounded,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildThemeOption(
                    context,
                    themeProvider,
                    'Light',
                    Icons.light_mode_rounded,
                    ThemeMode.light,
                  ),
                  const SizedBox(width: 12),
                  _buildThemeOption(
                    context,
                    themeProvider,
                    'Dark',
                    Icons.dark_mode_rounded,
                    ThemeMode.dark,
                  ),
                  const SizedBox(width: 12),
                  _buildThemeOption(
                    context,
                    themeProvider,
                    'System',
                    Icons.settings_suggest_rounded,
                    ThemeMode.system,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider themeProvider,
    String label,
    IconData icon,
    ThemeMode mode,
  ) {
    final isSelected = themeProvider.themeMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
          onTap: () => themeProvider.setThemeMode(mode),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryBlue.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryBlue
                    : isDark
                        ? AppTheme.darkDivider
                        : AppTheme.lightDivider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color:
                      isSelected ? AppTheme.primaryBlue : AppTheme.primaryBlue,
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? AppTheme.primaryBlue
                            : isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        ),
      ),
    );
  }

  void _openPlaceholder({required String title, required String message}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _PlaceholderScreen(title: title, message: message),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isLogout ? AppTheme.warningRed : AppTheme.primaryBlue,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isLogout
                            ? AppTheme.warningRed
                            : isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark
                    ? AppTheme.darkTextMuted
                    : AppTheme.lightTextTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNavBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BottomNavigationBar(
      currentIndex: 4,
      onTap: (index) {
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportsScreen()),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AlertsScreen()),
          );
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryBlue,
      unselectedItemColor:
          isDark ? AppTheme.darkTextMuted : AppTheme.lightTextTertiary,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt_outlined),
          activeIcon: Icon(Icons.list_alt_rounded),
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: SizedBox.shrink(),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          activeIcon: Icon(Icons.notifications_rounded),
          label: 'Alerts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outlined),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }

  void _editProfile() {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    final mobileController = TextEditingController(text: _mobile);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: mobileController,
              decoration: const InputDecoration(labelText: 'Mobile Number'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmPasswordAndUpdate(
                nameController.text.trim(),
                emailController.text.trim(),
                mobileController.text.trim(),
              );
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmPasswordAndUpdate(String name, String email, String mobile) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter your password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text ==
                  AuthService.currentUser?.password) {
                Navigator.pop(context);
                _updateProfile(name, email, mobile);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect password')),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _updateProfile(String name, String email, String mobile) {
    if (AuthService.currentUser != null) {
      AuthService.currentUser!.email = email;
      AuthService.currentUser!.mobile = mobile;
      // Note: Name is not in UserModel, but we can update it in state
    }

    setState(() {
      _name = name;
      _email = email;
      _mobile = mobile;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String message;

  const _PlaceholderScreen({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 48,
                color: AppTheme.lightTextTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
