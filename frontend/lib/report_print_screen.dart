import 'package:flutter/material.dart';
import 'package:roadwatch/services/api_service.dart';
import 'package:roadwatch/services/storage_service.dart';
import 'package:roadwatch/main.dart';
import 'package:roadwatch/utils/pdf_utils.dart';

class ReportPrintScreen extends StatefulWidget {
  const ReportPrintScreen({super.key});

  @override
  State<ReportPrintScreen> createState() => _ReportPrintScreenState();
}

class _ReportPrintScreenState extends State<ReportPrintScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];
  Set<Map<String, dynamic>> _selectedReports = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      final demoMode = await StorageService.isDemoMode();
      if (demoMode) {
        _reports = DemoDataProvider.reports
            .map((report) => _normalizeReport(report))
            .toList();
      } else {
        final reportsData = await ApiService.getReports();
        _reports = reportsData
            .map((report) => _normalizeReport(report as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reports: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  Map<String, dynamic> _normalizeReport(Map<String, dynamic> report) {
    final createdAt = report['created_at'] ??
        report['createdAt'] ??
        report['time'] ??
        report['date'];
    final dateTime = _parseDateTime(createdAt);
    return {
      'id': report['id'],
      'title': report['issue_type'] ?? report['title'] ?? 'Issue',
      'location': report['location_text'] ?? report['location'] ?? 'N/A',
      'severity': report['severity'] ?? 'N/A',
      'status': report['status'] ?? 'N/A',
      'date': dateTime['date'] ?? 'N/A',
      'time': dateTime['time'] ?? 'N/A',
      'upvotes': report['upvotes'] ?? 0,
    };
  }

  Map<String, String> _parseDateTime(dynamic value) {
    if (value == null) return {'date': 'N/A', 'time': 'N/A'};
    final rawValue = value.toString().trim();
    try {
      var dateTime = DateTime.tryParse(rawValue);
      if (dateTime == null && rawValue.contains(' ')) {
        dateTime = DateTime.tryParse(rawValue.replaceFirst(' ', 'T'));
      }
      if (dateTime == null) {
        return {'date': rawValue, 'time': 'N/A'};
      }
      final date =
          '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
      final time =
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      return {'date': date, 'time': time};
    } catch (_) {
      return {'date': rawValue, 'time': 'N/A'};
    }
  }

  void _generatePDF() async {
    if (_selectedReports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one report')),
      );
      return;
    }

    setState(() => _isLoading = true);

    for (final report in _selectedReports) {
      print('PDF report row: $report');
    }

    await PdfUtils.generateReportPdf(_selectedReports.toList());

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF generated successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Reports'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final report = _reports[index];
                      return CheckboxListTile(
                        title: Text(report['location']),
                        subtitle:
                            Text("${report['time']} • ${report['status']}"),
                        value: _selectedReports.contains(report),
                        onChanged: (value) {
                          setState(() {
                            if (value!) {
                              _selectedReports.add(report);
                            } else {
                              _selectedReports.remove(report);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _generatePDF,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Generate PDF'),
                  ),
                ),
              ],
            ),
    );
  }
}
