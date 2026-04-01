import 'package:flutter/services.dart';

/// Bridges the Android side's `com.expensetracker/share` MethodChannel with
/// the Flutter app. Call [init] once (from HomeScreen.initState), then set
/// [onImageReceived] to handle incoming UPI payment screenshots.
class UpiShareService {
  static const _channel = MethodChannel('com.expensetracker/share');

  /// Called whenever a shared image arrives from an external app (e.g. GPay).
  static void Function(Uint8List bytes)? onImageReceived;

  /// Wires up the MethodChannel handler and also polls for any image that
  /// arrived before Flutter was ready (startup share).
  static Future<void> init() async {
    // Listen for shares that arrive while the app is already running.
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShareReceived') {
        final bytes = call.arguments;
        if (bytes is Uint8List) {
          onImageReceived?.call(bytes);
        } else if (bytes is List) {
          onImageReceived?.call(Uint8List.fromList(bytes.cast<int>()));
        }
      }
    });

    // Poll for any image stored by MainActivity before the engine was ready.
    final pending = await _channel.invokeMethod<dynamic>('getPendingShare');
    if (pending != null) {
      final bytes = pending is Uint8List
          ? pending
          : Uint8List.fromList((pending as List).cast<int>());
      onImageReceived?.call(bytes);
    }
  }

  /// Stops listening (call from HomeScreen.dispose).
  static void dispose() {
    _channel.setMethodCallHandler(null);
    onImageReceived = null;
  }
}
