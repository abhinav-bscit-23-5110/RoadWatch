import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roadwatch/reports_screen.dart';
import 'package:roadwatch/report_screen.dart';
import 'package:roadwatch/alerts_screen.dart';
import 'package:roadwatch/profile_screen.dart';
import 'package:roadwatch/issue_detailed_screen.dart';
import 'package:roadwatch/report_print_screen.dart';
import 'package:roadwatch/main.dart';
import 'package:roadwatch/services/api_service.dart';
import 'package:roadwatch/services/auth_service.dart';
import 'package:roadwatch/services/storage_service.dart';
import 'LoginScreen.dart';
import 'package:roadwatch/theme/app_theme.dart';
import 'package:roadwatch/widgets/glass_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final TextEditingController _searchTextController = TextEditingController();
  bool _isLoading = true;
  bool _isDemo = false;
  String? _errorMessage;
  Map<String, int> _stats = {'reports': 0, 'verified': 0, 'upvotes': 0};
  List<Map<String, dynamic>> _recentReports = [];

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
      _loadDashboard();
    });
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final demoMode = await StorageService.isDemoMode();
      final useDemo = demoMode;

      _isDemo = useDemo;
      if (useDemo) {
        _stats = Map<String, int>.from(DemoDataProvider.stats);
        _recentReports = DemoDataProvider.reports
            .take(4)
            .map((report) => _normalizeReport(report))
            .toList();
      } else {
        final statsData = await ApiService.getDashboard();
        _stats = {
          'reports': statsData['reports'] ?? 0,
          'verified': statsData['verified'] ?? 0,
          'upvotes': statsData['upvotes'] ?? 0,
        };

        final reportsData = await ApiService.getReports();
        _recentReports = reportsData
            .map((report) => _normalizeReport(report as Map<String, dynamic>))
            .take(4)
            .toList();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  void _navigateToScreen(int index) {
    if (index == 2) return; // Middle button is FAB
    if (index == 0) {
      _showMessage('You are already on Home');
      return;
    }
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          slideFromRightRoute(const ReportsScreen()),
        ).then((value) {
          if (value == true) {
            _loadDashboard();
          }
        });
        break;
      case 3:
        Navigator.push(context, scaleAndFadeRoute(const AlertsScreen()));
        break;
      case 4:
        Navigator.push(
          context,
          slideFromBottomWithScaleRoute(const ProfileScreen()),
        );
        break;
    }
  }

  Map<String, dynamic> _normalizeReport(Map<String, dynamic> report) {
    return {
      'id': report['id'],
      'title': report['issue_type'] ?? report['title'] ?? 'Issue',
      'location': report['location_text'] ?? report['location'] ?? 'Unknown',
      'severity': report['severity'] ?? 'Unknown',
      'status': report['status'] ?? 'Pending',
      'time': _formatTime(report['created_at'] ?? report['time']),
      'upvotes': report['upvotes'] ?? 0,
      'verifies': report['verifies'] ?? 0,
    };
  }

  String _formatTime(dynamic value) {
    if (value == null) return 'Unknown';
    final text = value.toString();
    if (text.contains('T')) {
      return text.split('T').first;
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RoadWatch',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _navigateToScreen(3),
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Bar
                          _buildSearchBar(context),
                          const SizedBox(height: 28),

                          // Dashboard Overview Title
                          Text(
                            'Dashboard Overview',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 18),

                          // Dashboard Stats Cards (Gradient)
                          _buildDashboardStats(context),
                          const SizedBox(height: 16),

                          // Print Reports Button
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ReportPrintScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.print),
                            label: const Text("Print Reports"),
                          ),
                          const SizedBox(height: 32),

                          // Recent Reports Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Reports',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                              GestureDetector(
                                onTap: () => _navigateToScreen(1),
                                child: Text(
                                  'View All',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(color: AppTheme.primaryBlue),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildRecentReports(context),
                          if (_isDemo)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'Demo Mode – Static Data',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isDark
                                          ? AppTheme.darkTextMuted
                                          : AppTheme.lightTextTertiary,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkElevatedSurface2 : AppTheme.lightCardBg,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
              size: 20,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchTextController,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search location or issue...',
                border: InputBorder.none,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextMuted
                          : AppTheme.lightTextTertiary,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStats(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCardGradient(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      margin: const EdgeInsets.symmetric(horizontal: 0),
      blur: 14.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(
            '${_stats['reports'] ?? 0}',
            'Reports',
            Icons.assessment_outlined,
          ),
          _buildStatItem(
            '${_stats['verified'] ?? 0}',
            'Verified',
            Icons.verified_user_outlined,
          ),
          _buildStatItem(
            '${_stats['upvotes'] ?? 0}',
            'Upvotes',
            Icons.thumb_up_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentReports(BuildContext context) {
    if (_recentReports.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: _recentReports.map((report) {
        final severity = report['severity'] as String? ?? 'Unknown';
        final color = _severityColor(severity);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildReportCard(context, report, color),
        );
      }).toList(),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    Map<String, dynamic> report,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      borderRadius: AppTheme.borderRadius16,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(0),
      onTap: () => _openIssueDetails(report),
      blur: 12.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Severity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  (report['title'] as String? ?? 'Issue'),
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                ),
                child: Text(
                  (report['severity'] as String? ?? 'Unknown'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Location
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  (report['location'] as String? ?? 'Unknown'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Time
          Row(
            children: [
              Icon(
                Icons.access_time_outlined,
                size: 16,
                color: isDark
                    ? AppTheme.darkTextMuted
                    : AppTheme.lightTextTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                (report['time'] as String? ?? 'Unknown'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkElevatedSurface : AppTheme.lightCardBg,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextTertiary,
          ),
          const SizedBox(height: 16),
          Text('No reports yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Submit your first report using the + button.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_outlined,
              size: 48,
              color: AppTheme.lightTextTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load data',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      height: 64,
      width: 64,
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.35),
            blurRadius: 16,
            spreadRadius: 3,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const ReportScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                var scaleAnimation =
                    Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                );

                var rotateAnimation =
                    Tween<double>(begin: -0.3, end: 0.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );

                return ScaleTransition(
                  scale: scaleAnimation,
                  child: Transform.rotate(
                    angle: rotateAnimation.value,
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          ).then((value) {
            if (value == true) {
              _loadDashboard();
            }
          });
        },
        backgroundColor: AppTheme.primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
        ),
        child: const Icon(Icons.add, size: 28, color: Colors.white),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.12),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.borderRadius20),
          topRight: Radius.circular(AppTheme.borderRadius20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(context, Icons.home_rounded, 'Home', 0),
          _buildBottomNavItem(context, Icons.list_alt_rounded, 'Reports', 1),
          const SizedBox(width: 64),
          _buildBottomNavItem(
            context,
            Icons.notifications_rounded,
            'Alerts',
            3,
          ),
          _buildBottomNavItem(context, Icons.person_rounded, 'Profile', 4),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    bool isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppTheme.primaryBlue;
    final inactiveColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextTertiary;

    return GestureDetector(
      onTap: () => _navigateToScreen(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: isSelected ? activeColor : inactiveColor),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected ? activeColor : inactiveColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  void _openIssueDetails(Map<String, dynamic> report) {
    final issue = {
      'id': report['id'],
      'title': report['title'],
      'status': report['status'] ?? 'Pending',
      'severity': report['severity'] ?? 'Unknown',
      'location': report['location'] ?? 'Unknown',
      'time': report['time'] ?? 'Unknown',
      'upvotes': report['upvotes'] ?? 0,
      'verifies': report['verifies'] ?? 0,
    };

    Navigator.push(
      context,
      slideFromRightRoute(IssueDetailScreen(issue: issue)),
    );
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return AppTheme.warningRed;
      case 'medium':
        return AppTheme.warningOrange;
      case 'low':
        return AppTheme.successGreen;
      default:
        return AppTheme.lightTextTertiary;
    }
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
}
