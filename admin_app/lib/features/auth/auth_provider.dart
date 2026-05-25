import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';

class AdminAuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthService get _service => ref.read(authServiceProvider);

  Future<void> restoreSession() async {
    state = state.copyWith(isRestoring: true);
    final user = await _service.restoreSession();
    state = state.copyWith(
      isRestoring: false,
      isAuthenticated: user != null && user.role == UserRole.admin,
      user: user,
    );
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _service.loginWithPassword(
        email: email,
        password: password,
        role: UserRole.admin,
      );
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AuthState(isRestoring: false);
  }
}

final adminAuthProvider =
    NotifierProvider<AdminAuthNotifier, AuthState>(AdminAuthNotifier.new);
