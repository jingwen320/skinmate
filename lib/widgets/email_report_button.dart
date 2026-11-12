import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EmailReportButton extends StatefulWidget {
  final dynamic scanId;
  final Color primaryColor;

  const EmailReportButton({
    super.key, 
    required this.scanId,
    this.primaryColor = const Color(0xFF91462E), // Defaults to your SkinMate brown
  });

  @override
  State<EmailReportButton> createState() => _EmailReportButtonState();
}

class _EmailReportButtonState extends State<EmailReportButton> {
  bool _isSending = false;

  Future<void> _handleSendEmail() async {
    setState(() => _isSending = true);

    final response = await ApiService.sendEmailReport(widget.scanId);

    setState(() => _isSending = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Action completed.'),
          backgroundColor: response['status'] == 'success' ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: _isSending ? null : _handleSendEmail,
        icon: _isSending 
          ? SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(strokeWidth: 2, color: widget.primaryColor),
            )
          : Icon(Icons.email_outlined, color: widget.primaryColor),
        label: Text(
          _isSending ? "SENDING REPORT..." : "SEND COPY TO EMAIL",
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans', 
            fontWeight: FontWeight.bold, 
            color: widget.primaryColor, 
            letterSpacing: 0.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: widget.primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }
}