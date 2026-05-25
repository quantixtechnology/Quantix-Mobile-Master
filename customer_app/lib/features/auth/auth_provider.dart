import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthService get _service => ref.read(authServiceProvider);

  Future<void> restoreSession() async {
    state = state.copyWith(isRestoring: true);
    final user = await _service.restoreSession();
    state = state.copyWith(
      isRestoring: false,
      isAuthenticated: user != null,
      user: user,
    );
  }

  Future<void> requestEmailOtp(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sessionToken = await _service.requestEmailOtp(email);
      state = state.copyWith(
        isLoading: false,
        pendingSessionToken: sessionToken,
        pendingEmail: email.trim(),
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> verifyOtp(String code) async {
    final sessionToken = state.pendingSessionToken;
    if (sessionToken == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _service.verifyOtp(sessionToken, code);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        clearPendingSession: true,
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

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
