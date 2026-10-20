import 'dart:convert';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/app_router.dart';
import '../constants/app_colors.dart';
import '../utils/keys.dart';
import 'auth_service.dart';

/// Top-level background message handler required by Firebase Messaging.
///
/// This function must be outside any class and annotated with `@pragma('vm:entry-point')`
/// so that the Flutter engine can execute it in the background when the app is terminated or paused.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[NotificationService] Background message received: ${message.messageId}');
  debugPrint('[NotificationService] Background message title: ${message.notification?.title}');
  debugPrint('[NotificationService] Background message body: ${message.notification?.body}');
  debugPrint('[NotificationService] Background message data: ${message.data}');
}

/// Unified Service to manage Push Notifications via Firebase Cloud Messaging (FCM)
/// and local heads-up notifications via `flutter_local_notifications`.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _cachedFcmToken;

  /// High importance channel configuration for Android heads-up alerts.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important SkillResy notifications.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Initializes push notification permissions, channels, local notifications,
  /// and listens for foreground, background, and cold-start events.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('[NotificationService] Initializing notification service...');

      // 1. Request user permission (Critical for iOS and Android 13+)
      final settings = await _requestPermissions();
      debugPrint('[NotificationService] Permission authorization status: ${settings.authorizationStatus}');

      // 2. Set iOS foreground presentation options (alert, sound, badge)
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Initialize flutter_local_notifications for Android & iOS foreground display
      await _initializeLocalNotifications();

      // 4. Create high importance notification channel on Android
      await _createNotificationChannel();

      // 5. Setup message listeners (Foreground, Background, and Terminated states)
      _setupMessageHandlers();

      // 6. Listen for FCM token refresh to keep server synced
      _setupTokenRefreshListener();

      // 7. Check if app was launched by tapping a notification from killed state
      await checkInitialMessage();

      // 8. Fetch and cache initial FCM token
      _cachedFcmToken = await getFcmToken();
      print('\n================================================================');
      print('🔥 [SKILLRESY FCM TOKEN] COPY THIS TOKEN FOR TESTING:');
      print('$_cachedFcmToken');
      print('================================================================\n');

      _isInitialized = true;
      debugPrint('[NotificationService] Initialized successfully.');
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] Error initializing notifications: $e');
      debugPrint(stackTrace.toString());
    }
  }

  /// Requests user permission to display notifications.
  ///
  /// - On iOS: The OS controls the popup — it shows only once ever. We still call
  ///   requestPermission() so FCM can get a token if permission was previously granted.
  /// - On Android 12 and below: Permission is auto-granted, no popup.
  /// - On Android 13+: We first check the current status. If already granted or denied,
  ///   we skip the prompt to avoid asking the user on every app startup.
  Future<NotificationSettings> _requestPermissions() async {
    // Check current permission status before prompting
    final currentSettings = await _fcm.getNotificationSettings();
    final status = currentSettings.authorizationStatus;

    debugPrint('[NotificationService] Current permission status: $status');

    // Only show the permission dialog if it has never been determined
    // (i.e. user has not accepted or denied yet)
    if (status == AuthorizationStatus.notDetermined) {
      debugPrint('[NotificationService] Permission not yet determined — requesting from user...');
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      return settings;
    }

    // Permission was already granted or denied — no need to ask again
    debugPrint('[NotificationService] Permission already determined ($status) — skipping prompt.');
    return currentSettings;
  }

  /// Configures local notification plugin settings for Android and iOS.
  Future<void> _initializeLocalNotifications() async {
    // Small icon uses @mipmap/ic_launcher
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onSelectLocalNotification,
    );
  }

  /// Creates Android notification channel to allow heads-up banners on Android 8.0+.
  Future<void> _createNotificationChannel() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// Sets up listeners for incoming messages across Foreground and Background states.
  void _setupMessageHandlers() {
    // 1. FOREGROUND STATE: Triggered when app is active and in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[NotificationService] Foreground notification received: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // 2. BACKGROUND STATE: Triggered when app is minimized and user taps notification in status tray
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[NotificationService] Background notification tapped: ${message.messageId}');
      _handleNotificationClick(message.data);
    });
  }

  /// Checks if app was launched from Terminated / Cold-start state via a notification click.
  Future<void> checkInitialMessage() async {
    try {
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[NotificationService] App launched from killed state via notification: ${initialMessage.messageId}');
        // Allow router and app state to mount before navigating
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 600), () {
            _handleNotificationClick(initialMessage.data);
          });
        });
      }
    } catch (e) {
      debugPrint('[NotificationService] Error checking initial message: $e');
    }
  }

  /// Displays a heads-up local banner notification when a push message arrives in the foreground.
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;

    final title = notification?.title ?? message.data['title'] ?? 'SkillResy';
    final body = notification?.body ?? message.data['body'] ?? '';

    // Android notification details with brand accent color and app icon
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: AppColors.primary,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Callback when a foreground local notification banner is tapped by the user.
  void _onSelectLocalNotification(NotificationResponse response) {
    debugPrint('[NotificationService] Local notification response tapped: ${response.payload}');
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _handleNotificationClick(data);
      } catch (e) {
        _handleNotificationClick({});
      }
    } else {
      _handleNotificationClick({});
    }
  }

  /// Handles role-aware navigation on notification click.
  ///
  /// Prevents cross-role overlapping:
  /// - If user is unauthenticated -> navigate to `/login`
  /// - If user is Candidate (role = 1) -> navigate to Candidate Home (`/home`)
  /// - If user is Student (role = 2) -> navigate to Student Home (`/home`)
  /// - Supports deep linking if target route/type exists in message data.
  void _handleNotificationClick(Map<String, dynamic> data) {
    try {
      final box = GetStorage();
      final userPref = box.read(AppKeys.user);
      final accessToken = box.read(AppKeys.accessToken);

      // If user is not logged in, take them to login screen
      if (userPref == null || accessToken == null || (accessToken as String).isEmpty) {
        debugPrint('[NotificationService] User not logged in, redirecting to login');
        appRouter.go('/login');
        return;
      }

      // Parse current user from storage
      final userMap = jsonDecode(userPref as String);
      final role = userMap['role'] as int? ?? 1;

      debugPrint('[NotificationService] User logged in with role: $role');

      // Check for deep link parameters in payload (e.g. data['type'])
      final type = data['type']?.toString().toLowerCase();

      if (role == 2) {
        // --- STUDENT NAVIGATION ---
        debugPrint('[NotificationService] Navigating to Student dashboard');
        if (type == 'quiz' || type == 'quiz_summary') {
          appRouter.go('/student/quiz-history');
        } else if (type == 'document' || type == 'lecture') {
          appRouter.go('/student/documents');
        } else if (type == 'plan' || type == 'subscription') {
          appRouter.go('/student/plans');
        } else {
          // Default: Student Home
          appRouter.go('/home');
        }
      } else {
        // --- CANDIDATE NAVIGATION (role == 1) ---
        debugPrint('[NotificationService] Navigating to Candidate dashboard');
        if (type == 'interview' || type == 'meeting') {
          appRouter.go('/candidate/interview');
        } else if (type == 'resume') {
          appRouter.go('/candidate/resume');
        } else if (type == 'plan' || type == 'subscription') {
          appRouter.go('/candidate/plans');
        } else {
          // Default: Candidate Home
          appRouter.go('/home');
        }
      }
    } catch (e, stack) {
      debugPrint('[NotificationService] Error handling navigation: $e');
      debugPrint(stack.toString());
      // Fallback safe navigation
      appRouter.go('/home');
    }
  }

  /// Retrieves the device FCM token.
  /// On iOS, waits for APNs token before requesting FCM token to prevent empty tokens.
  Future<String?> getFcmToken() async {
    if (_cachedFcmToken != null && _cachedFcmToken!.isNotEmpty) {
      return _cachedFcmToken;
    }

    try {
      if (Platform.isIOS) {
        // On iOS, wait for APNs device token to be assigned
        String? apnsToken = await _fcm.getAPNSToken();
        int attempts = 0;
        while (apnsToken == null && attempts < 5) {
          await Future.delayed(const Duration(milliseconds: 500));
          apnsToken = await _fcm.getAPNSToken();
          attempts++;
        }
        debugPrint('[NotificationService] iOS APNs Token: $apnsToken');
      }

      final token = await _fcm.getToken();
      _cachedFcmToken = token;
      print('\n🔥 [FCM TOKEN]: $token\n');
      return token;
    } catch (e) {
      debugPrint('[NotificationService] Failed to get FCM token: $e');
      return null;
    }
  }

  /// Listens for token refreshes and keeps the backend synchronized.
  void _setupTokenRefreshListener() {
    _fcm.onTokenRefresh.listen((newToken) async {
      debugPrint('[NotificationService] FCM Token refreshed: $newToken');
      _cachedFcmToken = newToken;
      try {
        final box = GetStorage();
        final accessToken = box.read(AppKeys.accessToken);
        if (accessToken != null && (accessToken as String).isNotEmpty) {
          debugPrint('[NotificationService] Syncing refreshed token with backend...');
          final authService = AuthService();
          final currentPlatform = Platform.isIOS ? 'ios' : 'android';
          String appVersion = '1.0.10';
          try {
            final info = await PackageInfo.fromPlatform();
            appVersion = info.version;
          } catch (_) {}

          await authService.registerDeviceToken(
            token: newToken,
            platform: currentPlatform,
            appVersion: appVersion,
          );
        }
      } catch (e) {
        debugPrint('[NotificationService] Error syncing refreshed token: $e');
      }
    });
  }
}
