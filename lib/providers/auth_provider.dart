import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  String? _currencyCode;
  String? _currencySymbol;
  bool _profileLoaded = false;
  bool _upiAutoCapture = false;
  String _upiCaptureMode = 'manual'; // 'auto' | 'manual'
  bool _pushNotificationsEnabled = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  String get currencyCode => _currencyCode ?? 'USD';
  String get currencySymbol => _currencySymbol ?? '\$';
  bool get hasSelectedCurrency => _currencyCode != null;
  bool get profileLoaded => _profileLoaded;
  bool get upiAutoCapture => _upiAutoCapture;
  String get upiCaptureMode => _upiCaptureMode;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;

  AuthProvider() {
    _user = _authService.currentUser;

    if (_user != null) {
      _authService.syncWithBackend(_user!);
      _loadUserProfile();
    }

    _authService.authStateChanges.listen((User? user) {
      final wasNull = _user == null;
      _user = user;
      notifyListeners();

      if (user != null && wasNull) {
        _authService.syncWithBackend(user);
        _loadUserProfile();
      } else if (user == null) {
        _currencyCode = null;
        _currencySymbol = null;
        _profileLoaded = false;
        _pushNotificationsEnabled = false;
        NotificationService.instance.setPushNotificationsEnabled(false);
      }
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final data = await ApiService.get('/auth/me');
      final userDoc = data['user'] as Map<String, dynamic>?;
      final settings = userDoc?['settings'] as Map<String, dynamic>?;
      _currencyCode = settings?['currencyCode'] as String?;
      _currencySymbol = settings?['currencySymbol'] as String?;
      _upiAutoCapture = settings?['upiAutoCapture'] == true;
      _upiCaptureMode = (settings?['upiCaptureMode'] as String?) ?? 'manual';
      _pushNotificationsEnabled = settings?['pushNotifications'] == true;
      NotificationService.instance.setPushNotificationsEnabled(_pushNotificationsEnabled);
      if (_pushNotificationsEnabled && _user != null) {
        await NotificationService.instance.syncTokenWithBackend();
      }

    } catch (e) {
      debugPrint('[AuthProvider] loadUserProfile error: $e');
    }
    _profileLoaded = true;
    notifyListeners();
  }

  void setCurrency({required String code, required String symbol}) {
    _currencyCode = code;
    _currencySymbol = symbol;
    notifyListeners();
  }

  void setUpiAutoCapture(bool value) {
    _upiAutoCapture = value;
    notifyListeners();
  }

  void setUpiCaptureMode(String mode) {
    _upiCaptureMode = mode;
    notifyListeners();
  }

  void setPushNotificationsEnabled(bool value) {
    _pushNotificationsEnabled = value;
    NotificationService.instance.setPushNotificationsEnabled(value);
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle();
      _user = user;
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e, stackTrace) {
      debugPrint('🔴 Google Sign-In error: $e');
      debugPrint('🔴 Stack trace: $stackTrace');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      _user = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.createUserWithEmailAndPassword(
        email,
        password,
        fullName,
      );
      if (user != null) {
        // Email registration should not keep an active session.
        await _authService.signOut();
      }
      _user = null;
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await NotificationService.instance.unregisterCurrentToken();
    } catch (e) {
      debugPrint('[AuthProvider] unregister token error: $e');
    }
    await _authService.signOut();
    _user = null;
    _pushNotificationsEnabled = false;
    NotificationService.instance.setPushNotificationsEnabled(false);
    notifyListeners();
  }
}
