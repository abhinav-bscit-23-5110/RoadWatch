import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';
import 'issue_detailed_screen.dart';
import 'LoginScreen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'widgets/glass_card.dart';
import 'widgets/semantic_badges.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  bool _isDemo = false;
  bool _isFetching = false;
  bool _didMutate = false;
  String? _errorMessage;
  final Set<int> _deletingIds = {};
  List<Map<String, dynamic>> _reports = [];

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
      _loadReports();
    });
  }

  Future<void> _loadReports() async {
    if (_isFetching) return;
    _isFetching = true;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final demoMode = await StorageService.isDemoMode();
      final useDemo = demoMode;
      _isDemo = useDemo;

      if (useDemo) {
        _reports = _normalizeReports(DemoDataProvider.reports);
      } else {
        final data = await ApiService.getReports();
        _reports = _normalizeReports(data);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isFetching = false;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _normalizeReports(List<dynamic> raw) {
    final List<Map<String, dynamic>> normalized = [];
    final Set<int> seenIds = {};
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final report = _normalizeReport(item);
      final int? id = _parseReportId(report['id']);
      if (id != null) {
        if (seenIds.contains(id)) continue;
        seenIds.add(id);
        report['id'] = id;
      }
      normalized.add(report);
    }
    return normalized;
  }

  int? _parseReportId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> _normalizeReport(Map<String, dynamic> report) {
    return {
      'id': report['id'],
      'title': report['issue_type'] ?? report['title'] ?? 'Issue',
      'status': report['status'] ?? 'Pending',
      'location': report['location_text'] ?? report['location'] ?? 'Unknown',
      'date': _formatTime(report['created_at'] ?? report['time']),
      'severity': report['severity'] ?? 'Medium',
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _didMutate);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _didMutate),
          ),
          title: Text(
            'My Reports',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _loadReports,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Track your submitted issues',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: isDark
                                          ? AppTheme.darkTextSecondary
                                          : AppTheme.lightTextSecondary,
                                    ),
                          ),
                          const SizedBox(height: 20),
                          if (_reports.isEmpty)
                            _buildEmptyState(context)
                          else
                            ..._reports.map((report) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildReportCard(context, report),
                              );
                            }).toList(),
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
        bottomNavigationBar: _buildBottomNavBar(context),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, Map<String, dynamic> report) {
    final status = report['status'] as String? ?? 'Pending';
    final int? reportId = _parseReportId(report['id']);
    final bool isDeleting = reportId != null && _deletingIds.contains(reportId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final issue = {
      'id': report['id'],
      'title': report['title'],
      'status': status,
      'severity': report['severity'],
      'location': report['location'],
      'time': report['date'],
      'upvotes': report['upvotes'],
      'verifies': report['verifies'],
    };

    return GlassCard(
      borderRadius: AppTheme.borderRadius16,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(0),
      onTap: () => _openIssueDetails(context, issue),
      blur: 12.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report['title'] ?? 'Issue',
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: status),
              const SizedBox(width: 6),
              Material(
                color: Colors.transparent,
                child: IconButton(
                  tooltip: 'Delete report',
                  constraints: const BoxConstraints(
                    maxWidth: 40,
                    maxHeight: 40,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: isDeleting ? null : () => _handleDeleteTap(report),
                  icon: isDeleting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.delete_outline_rounded,
                          color: AppTheme.warningRed,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                  report['location'] ?? 'Unknown',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: isDark
                    ? AppTheme.darkTextMuted
                    : AppTheme.lightTextTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                report['date'] ?? 'Unknown',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark
                    ? AppTheme.darkTextMuted
                    : AppTheme.lightTextTertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteTap(Map<String, dynamic> report) async {
    if (_isDemo) {
      _showMessage(context, 'Demo mode: deleting reports is disabled.');
      return;
    }

    final int? reportId = _parseReportId(report['id']);
    if (reportId == null) {
      _showMessage(context, 'Unable to delete this report.');
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          title: Text(
            'Delete Report',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'Are you sure you want to delete this report?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppTheme.primaryBlue),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppTheme.warningRed),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteReport(reportId);
    }
  }

  Future<void> _deleteReport(int reportId) async {
    if (_deletingIds.contains(reportId)) return;

    setState(() {
      _deletingIds.add(reportId);
    });

    try {
      await ApiService.deleteReport(reportId);
      if (!mounted) return;
      setState(() {
        _reports.removeWhere(
          (report) => _parseReportId(report['id']) == reportId,
        );
        _deletingIds.remove(reportId);
        _didMutate = true;
      });
      _showMessage(context, 'Report deleted successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deletingIds.remove(reportId);
      });
      _showMessage(context, e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _openIssueDetails(BuildContext context, Map<String, dynamic> issue) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => IssueDetailScreen(issue: issue)),
    );
  }

  Color _statusColor(String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppTheme.getStatusColor(status, isDark: isDark);
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
            'Submit your first report from the Home screen.',
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
              _errorMessage ?? 'Failed to load reports',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadReports,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNavBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BottomNavigationBar(
      currentIndex: 1,
      onTap: (index) {
        if (index == 1) {
          _showMessage(context, 'You are already on Reports');
          return;
        }
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AlertsScreen()),
          );
        } else if (index == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
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
        BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''),
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

  void _showMessage(BuildContext context, String message) {
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
