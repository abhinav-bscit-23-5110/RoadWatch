import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:roadwatch/services/api_service.dart';
import 'package:roadwatch/services/auth_service.dart';
import 'package:roadwatch/services/storage_service.dart';
import 'package:roadwatch/utils/pdf_utils.dart';
import 'widgets/report_details_widget.dart';
import 'LoginScreen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<dynamic> _reports = [];
  List<dynamic> _users = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  // Report filtering
  String _statusFilter = 'All';
  static const List<String> _statusOptions = [
    'All',
    'Pending',
    'Verified',
    'Resolved',
    'Rejected',
    'In Progress',
  ];

  // Selection for printing
  bool _isSelectionMode = false;
  Set<dynamic> _selectedReports = {};

  // Real-time monitoring
  Timer? _refreshTimer;

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

      final role = await AuthService.getRole();
      if (role != 'admin') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }

      _loadData();

      // Real-time refresh every 30 seconds
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _loadData();
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }
    try {
      final reportsResponse =
          await ApiService.request('/admin/reports/', auth: true);
      final usersResponse =
          await ApiService.request('/admin/users/', auth: true);

      if (reportsResponse.statusCode == 200 &&
          usersResponse.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _reports = jsonDecode(reportsResponse.body);
          _users = jsonDecode(usersResponse.body);
          if (showLoading) _isLoading = false;
        });
        return;
      }

      // If we reach here, the server returned an unexpected status.
      String message = 'Failed to load data';
      if (reportsResponse.statusCode != 200) {
        message =
            'Failed to load reports: ${reportsResponse.statusCode} ${reportsResponse.reasonPhrase}';
      } else if (usersResponse.statusCode != 200) {
        message =
            'Failed to load users: ${usersResponse.statusCode} ${usersResponse.reasonPhrase}';
      }

      if (!mounted) return;
      if (showLoading) {
        setState(() => _isLoading = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      if (showLoading) {
        setState(() => _isLoading = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  void _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildReportsView(),
                _buildUsersView(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
        ],
      ),
    );
  }

  Widget _buildReportsView() {
    final pendingReports =
        _reports.where((r) => r['status'] == 'Pending').length;
    final verifiedReports =
        _reports.where((r) => r['status'] == 'Verified').length;
    final resolvedReports =
        _reports.where((r) => r['status'] == 'Resolved').length;
    final rejectedReports =
        _reports.where((r) => r['status'] == 'Rejected').length;

    final filteredReports = _statusFilter == 'All'
        ? _reports
        : _reports.where((r) => r['status'] == _statusFilter).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats Cards
          Row(
            children: [
              _buildStatCard('Total', _reports.length.toString(), Colors.blue),
              const SizedBox(width: 8),
              _buildStatCard(
                  'Pending', pendingReports.toString(), Colors.orange),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatCard(
                  'Verified', verifiedReports.toString(), Colors.green),
              const SizedBox(width: 8),
              _buildStatCard(
                  'Resolved', resolvedReports.toString(), Colors.purple),
              const SizedBox(width: 8),
              _buildStatCard(
                  'Rejected', rejectedReports.toString(), Colors.red),
            ],
          ),
          const SizedBox(height: 20),

          // Filter controls
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  items: _statusOptions
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _statusFilter = value);
                  },
                  decoration: InputDecoration(
                    labelText: 'Filter by status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Reports List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reports (${filteredReports.length})',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = !_isSelectionMode;
                        if (!_isSelectionMode) {
                          _selectedReports.clear();
                        }
                      });
                    },
                    icon:
                        Icon(_isSelectionMode ? Icons.cancel : Icons.check_box),
                    label: Text(_isSelectionMode ? 'Cancel' : 'Select'),
                  ),
                  if (_isSelectionMode && _selectedReports.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _generatePDF,
                      icon: const Icon(Icons.print),
                      label: const Text('Print Selected'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...filteredReports.map((report) => _buildReportCard(report)),
        ],
      ),
    );
  }

  Widget _buildUsersView() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'All Users (${_users.length})',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ..._users.map((user) => _buildUserCard(user)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(dynamic report) {
    final reporterName = (report['user']?['name'] as String?)?.trim() ?? '';

    return GestureDetector(
      onTap: _isSelectionMode
          ? () => _toggleReportSelection(report)
          : () => _showReportDetails(report),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSelectionMode)
                Row(
                  children: [
                    Checkbox(
                      value: _selectedReports.contains(report['id']),
                      onChanged: (bool? value) =>
                          _toggleReportSelection(report),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report['issue_type'] ?? 'Unknown Issue',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildStatusChip(report['status']),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report['description'] ?? '',
                style:
                    GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'By: ${reporterName.isEmpty ? 'Unknown' : reporterName}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showReportActions(report),
                    child: Text(
                      'Actions',
                      style: GoogleFonts.poppins(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleReportSelection(dynamic report) {
    setState(() {
      final reportId = report['id'];
      if (_selectedReports.contains(reportId)) {
        _selectedReports.remove(reportId);
      } else {
        _selectedReports.add(reportId);
      }
    });
  }

  Widget _buildUserCard(dynamic user) {
    return GestureDetector(
      onTap: () => _showUserReports(user),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue,
            child: Text(
              () {
                final name = (user['name'] as String?)?.trim() ?? '';
                if (name.isEmpty) return '?';
                return name[0].toUpperCase();
              }(),
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
          title: Text(
            user['name'],
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user['email'],
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Chip(
                label: Text(
                  user['role'].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color:
                        user['role'] == 'admin' ? Colors.white : Colors.black,
                  ),
                ),
                backgroundColor:
                    user['role'] == 'admin' ? Colors.red : Colors.green,
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                tooltip: 'Rename user',
                onPressed: () => _showRenameUserDialog(user),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Delete user',
                onPressed: () => _deleteUser(user['id']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRenameUserDialog(dynamic user) async {
    final controller =
        TextEditingController(text: user['name'] as String? ?? '');
    final updated = await showDialog<String?>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: Text('Rename User', style: GoogleFonts.poppins()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text('Save', style: GoogleFonts.poppins(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (updated == null) return;
    if (updated.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    await _renameUser(user['id'] as int, updated);
  }

  Future<void> _renameUser(int userId, String name) async {
    try {
      final response = await ApiService.request(
        '/admin/users/$userId/',
        method: 'PATCH',
        auth: true,
        body: {'name': name},
      );

      if (response.statusCode == 200) {
        // Use silent reload to avoid freezing
        await _loadData(showLoading: false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User name updated successfully')),
        );
      } else {
        final msg =
            response.body.isNotEmpty ? response.body : 'Failed to update user';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user: $e')),
      );
    }
  }

  Future<void> _deleteUser(int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete User', style: GoogleFonts.poppins()),
        content: Text(
          'Are you sure you want to delete this user? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiService.request(
        '/admin/users/$userId/delete/',
        method: 'DELETE',
        auth: true,
      );

      if (response.statusCode == 204) {
        // Use silent reload to avoid freezing
        await _loadData(showLoading: false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      } else {
        final msg =
            response.body.isNotEmpty ? response.body : 'Failed to delete user';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e')),
      );
    }
  }

  IconData getStatusIcon(String? status) {
    switch (status?.toLowerCase() ?? '') {
      case 'pending':
        return Icons.hourglass_empty; // ⏳
      case 'verified':
        return Icons.verified; // ✔
      case 'resolved':
        return Icons.check_circle; // ✔✔
      case 'rejected':
        return Icons.cancel; // ❌
      default:
        return Icons.help;
    }
  }

  int getStatusStep(String? status) {
    switch (status?.toLowerCase() ?? '') {
      case 'pending':
        return 1;
      case 'verified':
        return 2;
      case 'resolved':
        return 3;
      case 'rejected':
        return -1;
      default:
        return 0;
    }
  }

  Widget buildStep(String label, int stepNumber, int currentStep,
      Color activeColor, Color inactiveColor) {
    final bool isActive = currentStep >= stepNumber;

    return Column(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: isActive ? activeColor : inactiveColor,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? activeColor : inactiveColor,
          ),
        ),
      ],
    );
  }

  Widget buildProgressTracker(String? status) {
    if (status?.toLowerCase() == 'rejected') {
      return const Text(
        'Rejected',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      );
    }

    final int step = getStatusStep(status);
    const activeColor = Colors.green;
    const inactiveColor = Colors.grey;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        buildStep('Pending', 1, step, activeColor, inactiveColor),
        buildStep('Verified', 2, step, activeColor, inactiveColor),
        buildStep('Resolved', 3, step, activeColor, inactiveColor),
      ],
    );
  }

  Widget _buildStatusChip(String? status) {
    final String display = (status ?? 'Unknown').toString();
    final String normalized = display.toLowerCase();
    final Color color;
    switch (normalized) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'verified':
        color = Colors.green;
        break;
      case 'resolved':
        color = Colors.blue;
        break;
      case 'in progress':
        color = Colors.purple;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getStatusIcon(display),
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            display.toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showReportActions(dynamic report) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Report Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildActionButton(
              'View Details',
              Icons.info,
              Colors.blueGrey,
              () async => await _showReportDetails(report),
            ),
            _buildActionButton(
              'Mark as Verified',
              Icons.verified,
              Colors.green,
              () async => await _updateReportStatus(report['id'], 'Verified'),
            ),
            _buildActionButton(
              'Mark as Resolved',
              Icons.check_circle,
              Colors.blue,
              () async => await _updateReportStatus(report['id'], 'Resolved'),
            ),
            _buildActionButton(
              'Mark as Rejected',
              Icons.close,
              Colors.red,
              () async => await _updateReportStatus(report['id'], 'Rejected'),
            ),
            _buildActionButton(
              'Delete Report',
              Icons.delete,
              Colors.redAccent,
              () async => await _deleteReport(report['id']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color,
      Future<void> Function() onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton.icon(
        onPressed: () async {
          Navigator.pop(context);
          await onPressed();
        },
        icon: Icon(icon, color: Colors.white),
        label: Text(text, style: GoogleFonts.poppins(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(double.infinity, 45),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _updateReportStatus(int reportId, String status) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.put(
        Uri.parse("http://127.0.0.1:8000/api/reports/$reportId/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "status": status.toLowerCase(),
        }),
      );

      if (response.statusCode == 200) {
        await _loadData(showLoading: false); // refresh list
        if (!mounted) return;
        setState(() {}); // update UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report status updated to $status')),
        );
      } else {
        print("API ERROR: ${response.body}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update report status')),
        );
      }
    } catch (e) {
      print("ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update report status')),
      );
    }
  }

  Future<void> _showReportDetails(dynamic report) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          child: ReportDetailsWidget(
            report: report,
            onClose: () {
              Navigator.of(dialogContext).pop(); // FIX
            },
          ),
        );
      },
    );
  }

  Future<String?> _prepareImageUrl(String imageUrl) async {
    try {
      final base = await ApiService.baseUrl;
      return '$base/${imageUrl.replaceFirst(RegExp(r'^/'), '')}';
    } catch (e) {
      return null;
    }
  }

  Future<void> _deleteReport(int reportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete Report', style: GoogleFonts.poppins()),
        content: Text(
          'Are you sure you want to delete this report?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiService.request(
        '/api/reports/$reportId',
        method: 'DELETE',
        auth: true,
      );

      if (response.statusCode == 204) {
        // Use silent reload (showLoading: false) to avoid freezing
        await _loadData(showLoading: false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report deleted successfully')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete report')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete report: $e')),
      );
    }
  }

  Future<void> _showUserReports(dynamic user) async {
    final userId = user['id'];
    final userName = user['name'] ?? 'User';
    final userReports =
        _reports.where((r) => r['user']?['id'] == userId).toList();

    final totalReports = userReports.length;
    final pendingReports =
        userReports.where((r) => r['status'] == 'Pending').length;
    final verifiedReports =
        userReports.where((r) => r['status'] == 'Verified').length;
    final resolvedReports =
        userReports.where((r) => r['status'] == 'Resolved').length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$userName's Reports",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: $totalReports reports',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stats Row
              if (totalReports > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniStatCard('Pending', pendingReports.toString(),
                        Colors.orange, 80),
                    _buildMiniStatCard('Verified', verifiedReports.toString(),
                        Colors.green, 80),
                    _buildMiniStatCard('Resolved', resolvedReports.toString(),
                        Colors.blue, 80),
                  ],
                ),
              if (totalReports > 0) const SizedBox(height: 20),

              // Reports List
              if (totalReports > 0)
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: userReports.length,
                    itemBuilder: (context, index) {
                      final report = userReports[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _showReportDetails(report);
                          },
                          child: Card(
                            key:
                                ValueKey('${report['id']}-${report['status']}'),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          report['issue_type'] ??
                                              'Unknown Issue',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      _buildStatusChip(report['status']),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  buildProgressTracker(report['status']),
                                  const SizedBox(height: 8),
                                  Text(
                                    report['description'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '📍 ${report['location_text'] ?? 'Unknown'}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '📅 ${report['created_at']?.toString().split('T').first ?? 'Unknown'}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No reports from this user',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
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
    );
  }

  Widget _buildMiniStatCard(
      String title, String value, Color color, double width) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generatePDF() async {
    if (_selectedReports.isEmpty) return;

    final selectedReports = _reports
        .where((r) => _selectedReports.contains(r['id']))
        .map((r) => r as Map<String, dynamic>)
        .toList();

    try {
      await PdfUtils.generateReportPdf(selectedReports, isAdmin: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF generated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    }
  }
}
