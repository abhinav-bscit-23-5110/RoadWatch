import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Status Badge - Shows report status with semantic colors
class StatusBadge extends StatelessWidget {
  final String status;
  final EdgeInsets padding;
  final TextStyle? textStyle;

  const StatusBadge({
    required this.status,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.textStyle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = AppTheme.getStatusBgColor(status, isDark: isDark);
    final textColor = AppTheme.getStatusTextColor(status, isDark: isDark);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: isDark
            ? Border.all(color: textColor.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Text(
        status,
        style:
            textStyle ??
            TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
      ),
    );
  }
}

/// Severity Badge - Shows issue severity with semantic colors
class SeverityBadge extends StatelessWidget {
  final String severity;
  final EdgeInsets padding;
  final TextStyle? textStyle;

  const SeverityBadge({
    required this.severity,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.textStyle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppTheme.getSeverityColor(severity, isDark: isDark);
    final backgroundColor = AppTheme.getSeverityBgColor(
      severity,
      isDark: isDark,
    );

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: isDark
            ? Border.all(color: textColor.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Text(
        severity,
        style:
            textStyle ??
            TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
      ),
    );
  }
}
