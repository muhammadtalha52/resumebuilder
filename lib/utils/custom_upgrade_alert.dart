import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skillresy/constants/app_colors.dart';
import 'dart:io' show Platform;

class CustomUpgradeAlert extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;

  const CustomUpgradeAlert({
    required this.child,
    this.navigatorKey,
    super.key,
  });
  
  @override
  State<CustomUpgradeAlert> createState() => _CustomUpgradeAlertState();
}

class _CustomUpgradeAlertState extends State<CustomUpgradeAlert> {
  bool _shouldDisplay = false;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      // Fetch instantly for testing, but in production this can be cached
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 1), 
      ));
      
      // Default value before fetching
      await remoteConfig.setDefaults(const {
        'min_app_version': '1.0.0',
      });
      
      await remoteConfig.fetchAndActivate();

      final minVersion = remoteConfig.getString('min_app_version');
      if (minVersion.isEmpty) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isVersionLower(currentVersion, minVersion)) {
        setState(() {
          _shouldDisplay = true;
        });
      }
    } catch (e) {
      debugPrint('Error checking remote config version: $e');
    }
  }

  // Helper to compare versions like 1.0.5 vs 1.0.6
  bool _isVersionLower(String current, String minimum) {
    List<int> currentParts = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    List<int> minParts = minimum.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      int c = i < currentParts.length ? currentParts[i] : 0;
      int m = i < minParts.length ? minParts[i] : 0;
      if (c < m) return true;
      if (c > m) return false;
    }
    return false;
  }

  void _launchStore() async {
    final String url = Platform.isAndroid 
      ? 'https://play.google.com/store/apps/details?id=com.skillresy.app'
      : 'https://apps.apple.com/us/app/skillresy/id6755155918';
      
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldDisplay) {
      return Stack(
        textDirection: TextDirection.ltr,
        children: [
          IgnorePointer(
            ignoring: true,
            child: widget.child,
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icons/logo-fox-on-top.png',
                      height: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Update Required',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'A new version of SkillResy is available. Please update to continue using the app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _launchStore,
                        child: const Text('Update', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return widget.child;
  }
}
