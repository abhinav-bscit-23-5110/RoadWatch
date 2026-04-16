import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportDetailsWidget extends StatefulWidget {
  final Map<String, dynamic> report;
  final VoidCallback onClose;

  const ReportDetailsWidget({
    super.key,
    required this.report,
    required this.onClose,
  });

  @override
  State<ReportDetailsWidget> createState() => _ReportDetailsWidgetState();
}

class _ReportDetailsWidgetState extends State<ReportDetailsWidget> {
  String? _fullImageUrl;

  @override
  void initState() {
    super.initState();
    _prepareImageUrl();
  }

  void _prepareImageUrl() {
    final imageUrl = widget.report['image'];
    final hasImage = imageUrl != null && (imageUrl as String).isNotEmpty;

    if (hasImage && (imageUrl as String).isNotEmpty) {
      if ((imageUrl as String).startsWith('http')) {
        _fullImageUrl = imageUrl;
      } else {
        _fullImageUrl = 'http://127.0.0.1:8000${imageUrl}';
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _fullImageUrl != null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _fullImageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.broken_image)),
                ),
              ),
            )
          else if (widget.report['image'] != null)
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Icon(Icons.image_outlined)),
            ),
          const SizedBox(height: 12),
          Text('Title: ${widget.report['issue_type'] ?? 'N/A'}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Description: ${widget.report['description'] ?? 'N/A'}',
              style: GoogleFonts.poppins()),
          const SizedBox(height: 8),
          Text('Status: ${widget.report['status'] ?? 'N/A'}',
              style: GoogleFonts.poppins()),
          const SizedBox(height: 8),
          Text('Severity: ${widget.report['severity'] ?? 'N/A'}',
              style: GoogleFonts.poppins()),
          const SizedBox(height: 8),
          Text('Location: ${widget.report['location_text'] ?? 'N/A'}',
              style: GoogleFonts.poppins()),
          const SizedBox(height: 8),
          Text(
              'Reported by: ${widget.report['user']?['name'] ?? widget.report['user']?['email'] ?? 'Unknown'}',
              style: GoogleFonts.poppins()),
          const SizedBox(height: 8),
          Text('Date: ${widget.report['created_at'] ?? 'N/A'}',
              style: GoogleFonts.poppins()),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop(); // FIX
                },
                child: Text("Close"),
              ),
              TextButton(
                onPressed: () {
                  // Assuming there's a way to show actions, but since it's in dialog, perhaps close and call callback
                  widget.onClose();
                  // Then show actions, but since onClose is pop, and actions are separate
                  // For now, just close
                },
                child: Text("Actions", style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
