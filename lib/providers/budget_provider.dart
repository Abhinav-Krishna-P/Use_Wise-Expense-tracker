import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget_model.dart';
import '../services/api_service.dart';

class BudgetProvider extends ChangeNotifier {
  BudgetPlan? _activePlan;
  bool _isLoading = false;
  List<Map<String, dynamic>>? _generatedPlans;

  BudgetPlan? get activePlan => _activePlan;
  bool get isLoading => _isLoading;
  bool get hasPlan => _activePlan != null;
  List<Map<String, dynamic>>? get generatedPlans => _generatedPlans;

  BudgetProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        loadActivePlan();
      } else {
        _activePlan = null;
        _generatedPlans = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  /// Loads the active budget plan from the backend.
  Future<void> loadActivePlan() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.get('/budget/active');
      final raw = data['activePlan'];
      if (raw != null && raw is Map<String, dynamic>) {
        _activePlan = BudgetPlan.fromJson(raw);
      } else {
        _activePlan = null;
      }
    } catch (e) {
      debugPrint('[BudgetProvider] loadActivePlan error: $e');
      _activePlan = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sends onboarding data to the backend, which stores it in Firestore
  /// and calls Gemini to generate 3 personalised budget plans.
  Future<List<Map<String, dynamic>>> generatePlans({
    required double monthlyIncome,
    required List<FixedExpense> fixedExpenses,
    required Map<String, String> questionAnswers,
    required String additionalInfo,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.post('/budget/generate-plans', {
        'monthlyIncome': monthlyIncome,
        'fixedExpenses': fixedExpenses.map((e) => e.toJson()).toList(),
        'questionAnswers': questionAnswers,
        'additionalInfo': additionalInfo,
      });

      final rawPlans = data['plans'] as List<dynamic>;
      _generatedPlans = rawPlans
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList();
      return _generatedPlans!;
    } catch (e) {
      debugPrint('[BudgetProvider] generatePlans error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sends the selected plan to the backend which saves it as the
  /// active budget plan in Firestore.
  Future<void> implementPlan(Map<String, dynamic> plan) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.post('/budget/implement', {
        'plan': plan,
      });

      final raw = data['activePlan'];
      if (raw != null && raw is Map<String, dynamic>) {
        _activePlan = BudgetPlan.fromJson(raw);
      }
      _generatedPlans = null;
    } catch (e) {
      debugPrint('[BudgetProvider] implementPlan error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes the active budget plan via the backend.
  Future<void> deleteBudgetPlan() async {
    try {
      await ApiService.delete('/budget/active');
      _activePlan = null;
      notifyListeners();
    } catch (e) {
      debugPrint('[BudgetProvider] deleteBudgetPlan error: $e');
    }
  }
}
