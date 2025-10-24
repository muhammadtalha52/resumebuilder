import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/url_launcher_utils.dart';

/// Screen that redirects to external legal URLs
/// This screen opens the URL and immediately pops back
class LegalRedirectScreen extends StatefulWidget {
  final String type; // 'privacy' or 'terms'

  const LegalRedirectScreen({super.key, required this.type});

  @override
  State<LegalRedirectScreen> createState() => _LegalRedirectScreenState();
}

class _LegalRedirectScreenState extends State<LegalRedirectScreen> {
  @override
  void initState() {
    super.initState();
    _launchUrl();
  }

  Future<void> _launchUrl() async {
    // Small delay to ensure context is ready
    await Future.delayed(const Duration(milliseconds: 100));

    bool launched = false;
    if (widget.type == 'privacy') {
      launched = await UrlLauncherUtils.launchPrivacyPolicy();
    } else if (widget.type == 'terms') {
      launched = await UrlLauncherUtils.launchTermsOfUse();
    }

    // Pop back after launching (or if launch failed)
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a minimal loading indicator while redirecting
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
