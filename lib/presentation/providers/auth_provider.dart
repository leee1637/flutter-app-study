import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warehouse_app/data/models/user_model.dart';
import 'package:warehouse_app/data/repositories/auth_repository.dart';
import 'package:warehouse_app/data/repositories/firebase_auth_repository.dart';

part 'auth_state.dart';

/// Зависимость: реализация контракта авторизации. Замена одной строки
/// меняет весь источник правды (Firebase ↔ локальная БД ↔ мок в тестах).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Состояние авторизации приложения.
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>(
  (ref) => AuthStateNotifier(ref),
);

/// Объект-команда: наружу методы (`signIn`, `signOut`), внутрь — `state`.
///
/// UI никогда не присваивает `state` напрямую — только вызывает методы,
/// поэтому переходы состояния собраны в одном месте.
class AuthStateNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthStateNotifier(this._ref) : super(const AuthInitial()) {
    _init();
  }

  /// Проверка сохранённой сессии при запуске приложения.
  void _init() async {
    try {
      final user = await _ref.read(authRepositoryProvider).getCurrentUser();
      state =
          user != null ? AuthSuccess(user: user) : const AuthUnauthenticated();
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  /// Возвращает `true`, если вход удался. UI использует результат, чтобы
  /// показать SnackBar, а само состояние нужно всем подписчикам.
  Future<bool> signIn({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final user = await _ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          );

      if (user == null) {
        state = const AuthFailure(message: 'Неверный email или пароль');
        return false;
      }

      state = AuthSuccess(user: user);
      return true;
    } catch (e) {
      state = AuthFailure(message: e.toString());
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _ref.read(authRepositoryProvider).signUp(
            email: email,
            password: password,
            name: name,
          );

      if (user == null) {
        state = const AuthFailure(message: 'Не удалось зарегистрироваться');
        return false;
      }

      state = AuthSuccess(user: user);
      return true;
    } catch (e) {
      state = AuthFailure(message: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _ref.read(authRepositoryProvider).signOut();
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthFailure(message: e.toString());
    }
  }

  Future<bool> resetPassword({required String email}) async {
    try {
      await _ref.read(authRepositoryProvider).resetPassword(email: email);
      return true;
    } catch (e) {
      state = AuthFailure(message: e.toString());
      return false;
    }
  }

  /// Текущий пользователь или `null`, если он не авторизован.
  UserModel? get currentUser {
    final current = state;
    return current is AuthSuccess ? current.user : null;
  }
}
