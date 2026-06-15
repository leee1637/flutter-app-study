import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warehouse_app/data/models/user_model.dart';
import 'package:warehouse_app/data/repositories/auth_repository.dart';
import 'package:warehouse_app/data/repositories/firebase_auth_repository.dart';

part 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>(
  (ref) => AuthStateNotifier(ref),
);

class AuthStateNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthStateNotifier(this._ref) : super(AuthInitial()) {
    _init();
  }

  void _init() async {
    final authRepo = _ref.read(authRepositoryProvider);
    final user = await authRepo.getCurrentUser();

    if (user != null) {
      state = AuthSuccess(user: user);
    } else {
      state = AuthUnauthenticated();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
      state = AuthLoading();

    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final result = await authRepo.signIn(email: email, password: password);

      if (result != null) {
        state = AuthSuccess(user: result);
        return true;
      } else {
        state = const AuthFailure(message: 'Authentication failed');
        return false;
  }
    } catch (e) {
      state = AuthFailure(message: e.toString());
      return false;
    }
  }

  Future<bool> signUp({required String email, required String password, required String name}) async {
    state = AuthLoading();

    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final result = await authRepo.signUp(
        email: email,
        password: password,
        name: name,
      );

      if (result != null) {
        state = AuthSuccess(user: result);
        return true;
      } else {
        state = const AuthFailure(message: 'Sign up failed');
        return false;
  }
    } catch (e) {
      state = AuthFailure(message: e.toString());
      return false;
}
  }

  Future<void> signOut() async {
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      await authRepo.signOut();
      state = AuthUnauthenticated();
    } catch (e) {
      state = AuthFailure(message: e.toString());
    }
  }

  Future<bool> resetPassword({required String email}) async {
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      await authRepo.resetPassword(email: email);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getIdToken() async {
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      fb_auth.User? firebaseUser = authRepo.currentUser;

      if (firebaseUser != null) {
        fb_auth.IdTokenResult tokenResult = await firebaseUser.getIdTokenResult();
        return tokenResult.token;
      }
      return null;
    } catch (e) {
      throw Exception("Failed to get ID token: $e");
    }
  }
}

