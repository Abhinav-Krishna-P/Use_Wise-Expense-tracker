import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/spending_limit_model.dart';
import '../services/api_service.dart';

class SpendingLimitProvider extends ChangeNotifier {
  SpendingLimitConfig? _config;
  bool _isLoading = false;

  SpendingLimitConfig? get config => _config;
  bool get isLoading => _isLoading;
  bool get hasLimits => _config != null && _config!.limits.isNotEmpty;
  List<SpendingLimitItem> get limits => _config?.limits ?? [];

  SpendingLimitProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        loadLimits();
      } else {
        _config = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  /// Fetches the current spending limits from the backend (with auto-renewal).
  Future<void> loadLimits() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.get('/spending-limits');
      final raw = data['config'];
      if (raw != null && raw is Map<String, dynamic>) {
        _config = SpendingLimitConfig.fromJson(raw);
      } else {
        _config = null;
      }
    } catch (e) {
      debugPrint('[SpendingLimitProvider] loadLimits error: $e');
      _config = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new spending limits configuration.
  Future<void> createLimits({
    required List<Map<String, dynamic>> limits,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.post('/spending-limits', {
        'limits': limits,
      });
      final raw = data['config'];
      if (raw != null && raw is Map<String, dynamic>) {
        _config = SpendingLimitConfig.fromJson(raw);
      }
    } catch (e) {
      debugPrint('[SpendingLimitProvider] createLimits error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the existing spending limits configuration.
  Future<void> updateLimits({
    List<Map<String, dynamic>>? limits,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = <String, dynamic>{};
      if (limits != null) body['limits'] = limits;

      final data = await ApiService.patch('/spending-limits', body);
      final raw = data['config'];
      if (raw != null && raw is Map<String, dynamic>) {
        _config = SpendingLimitConfig.fromJson(raw);
      }
    } catch (e) {
      debugPrint('[SpendingLimitProvider] updateLimits error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes the spending limits configuration.
  Future<void> deleteLimits() async {
    try {
      await ApiService.delete('/spending-limits');
      _config = null;
      notifyListeners();
    } catch (e) {
      debugPrint('[SpendingLimitProvider] deleteLimits error: $e');
    }
  }
}
