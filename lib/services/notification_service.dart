import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('[NotificationService] background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const AndroidNotificationChannel _generalChannel = AndroidNotificationChannel(
    'expense_tracker_general',
    'Expense Updates',
    description: 'UPI capture and general account notifications.',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel _summaryChannel = AndroidNotificationChannel(
    'expense_tracker_summaries',
    'Daily Summaries',
    description: 'Morning, midday, and day-end spending summaries.',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel _limitsChannel = AndroidNotificationChannel(
    'expense_tracker_limits',
    'Budget Alerts',
    description: 'Spending limit and overflow alerts.',
    importance: Importance.max,
  );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _pushEnabled = false;
  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<void> initialize() async {
    if (_initialized) return;

    await _initializeLocalNotifications();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteTap(initialMessage);
    }

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) async {
      if (!_pushEnabled || FirebaseAuth.instance.currentUser == null) return;
      await _registerToken(token);
    });

    _initialized = true;
  }

  Future<bool> enablePushNotifications() async {
    await initialize();

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!granted) {
      _pushEnabled = false;
      return false;
    }

    _pushEnabled = true;
    await syncTokenWithBackend();
    return true;
  }

  Future<void> syncTokenWithBackend() async {
    await initialize();
    if (!_pushEnabled || FirebaseAuth.instance.currentUser == null) return;

    final token = await _messaging.getToken();
    if (token == null || token.trim().isEmpty) return;
    await _registerToken(token);
  }

  Future<void> unregisterCurrentToken() async {
    await initialize();

    final token = await _messaging.getToken();
    if (token == null || token.trim().isEmpty || FirebaseAuth.instance.currentUser == null) {
      _pushEnabled = false;
      return;
    }

    await ApiService.post('/auth/notification-token/remove', {'token': token});
    _pushEnabled = false;
  }

  void setPushNotificationsEnabled(bool enabled) {
    _pushEnabled = enabled;
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
  }

  Future<void> _registerToken(String token) async {
    await ApiService.post('/auth/notification-token', {
      'token': token,
      'platform': _platformName,
    });
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@drawable/widget_wallet_icon');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: _handleLocalTap,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_generalChannel);
    await androidPlugin?.createNotificationChannel(_summaryChannel);
    await androidPlugin?.createNotificationChannel(_limitsChannel);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final channelId = message.data['channelId'] ?? _generalChannel.id;
    final channel = _resolveChannel(channelId);

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/widget_wallet_icon',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleRemoteTap(RemoteMessage message) {
    debugPrint('[NotificationService] remote tap payload: ${message.data}');
  }

  void _handleLocalTap(NotificationResponse response) {
    debugPrint('[NotificationService] local tap payload: ${response.payload}');
  }

  AndroidNotificationChannel _resolveChannel(String channelId) {
    switch (channelId) {
      case 'expense_tracker_summaries':
        return _summaryChannel;
      case 'expense_tracker_limits':
        return _limitsChannel;
      case 'expense_tracker_general':
      default:
        return _generalChannel;
    }
  }

  String get _platformName {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}
