import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthService get _service => ref.read(authServiceProvider);

  Future<void> restoreSession() async {
    if (kDebugMode) {
      await Future.delayed(const Duration(milliseconds: 600));
      state = state.copyWith(
        isRestoring: false,
        isAuthenticated: true,
        user: const UserModel(
          id: 'CUS-BUS-202605-0001-TEST001',
          name: 'Mukhtar Test User',
          phone: '9999999999',
          email: 'mukhtarkhan143@gmail.com',
          role: UserRole.customer,
          businessId: 'cmpgku3um004rkyxmuvk8k5a1',
        ),
      );
      return;
    }
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
      final devOtp = await _service.requestEmailOtp(email);
      state = state.copyWith(
        isLoading: false,
        pendingEmail: email.trim(),
        devOtp: devOtp,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> verifyOtp(String code) async {
    final email = state.pendingEmail;
    if (email == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _service.verifyOtp(email, code);
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
