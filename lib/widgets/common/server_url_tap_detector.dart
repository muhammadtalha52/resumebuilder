import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/endpoint_headers.dart';

/// Helper function to log and display the current server base URL.
void showServerBaseUrl(BuildContext context) {
  final message = ApiEndpoints.formattedServerBaseUrl;

  // Print in console
  debugPrint('====================================');
  debugPrint('CURRENT BASE URL: $message');
  debugPrint('====================================');

  // Show in SnackBar
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.dns_rounded, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 4),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Widget that triggers [showServerBaseUrl] when tapped 7 times within 2 seconds.
class ServerUrlTapDetector extends StatefulWidget {
  final Widget child;
  final int requiredTaps;
  final Duration resetDuration;

  const ServerUrlTapDetector({
    super.key,
    required this.child,
    this.requiredTaps = 7,
    this.resetDuration = const Duration(seconds: 2),
  });

  @override
  State<ServerUrlTapDetector> createState() => _ServerUrlTapDetectorState();
}

class _ServerUrlTapDetectorState extends State<ServerUrlTapDetector> {
  int _tapCount = 0;
  DateTime? _lastTap;

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTap == null || now.difference(_lastTap!) > widget.resetDuration) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    _lastTap = now;

    if (_tapCount >= widget.requiredTaps) {
      _tapCount = 0;
      showServerBaseUrl(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: widget.child,
    );
  }
}
