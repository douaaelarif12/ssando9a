import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../budget/presentation/dashboard_controller.dart';
import '../../budget/presentation/providers/budget_providers.dart';
import '../data/models/user_model.dart';

final authProvider =
    AsyncNotifierProvider<AuthController, UserModel?>(AuthController.new);

class AuthController extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final ds = ref.read(budgetDsProvider);
    return ds.getCurrentUser();
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final ds = ref.read(budgetDsProvider);

      final user = await ds.login(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );

      state = AsyncData(user);
      ref.invalidate(dashboardProvider);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required int monthlySalaryDh,
    required String householdType,
    required int childrenCount,
  }) async {
    state = const AsyncLoading();

    try {
      final ds = ref.read(budgetDsProvider);

      final user = await ds.registerUser(
        fullName: fullName.trim(),
        email: email.trim().toLowerCase(),
        password: password.trim(),
        monthlySalaryDh: monthlySalaryDh,
        householdType: householdType,
        childrenCount: childrenCount,
      );

      state = AsyncData(user);
       ref.invalidate(dashboardProvider);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> logout() async {
    try {
      final ds = ref.read(budgetDsProvider);

      await ds.logout();

      state = const AsyncData(null);
      ref.invalidate(dashboardProvider);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> updateMonthlySalary({
    required int monthlySalaryDh,
  }) async {
    try {
      final ds = ref.read(budgetDsProvider);

      await ds.updateMonthlySalary(
        monthlySalaryDh: monthlySalaryDh,
      );

      final refreshedUser = await ds.getCurrentUser();
      state = AsyncData(refreshedUser);

      ref.invalidate(dashboardProvider);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> updateProfile({
    required String fullName,
    required String email,
  }) async {
    try {
      final ds = ref.read(budgetDsProvider);

      await ds.updateProfile(
        fullName: fullName,
        email: email,
      );

      final refreshedUser = await ds.getCurrentUser();
      state = AsyncData(refreshedUser);

      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final ds = ref.read(budgetDsProvider);

      await ds.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> sendPasswordResetEmail({required String email}) async {
    try {
      final ds = ref.read(budgetDsProvider);
      await ds.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}