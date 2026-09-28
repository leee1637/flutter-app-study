part of 'auth_provider.dart';

/// Состояние авторизации описано иерархией классов («сумма-тип»), а не набором
/// флагов `_isLoading` / `_error` / `_user`.
///
/// Так невозможно забыть обработать состояние, ошибка всегда едет вместе
/// с текстом, а `AuthSuccess` несёт данные — экрану не нужно делать
/// второй запрос, чтобы узнать, кто вошёл.
abstract class AuthState {
  const AuthState();
}

/// Ещё проверяется сохранённая сессия.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Идёт запрос к сети.
class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final UserModel user;

  const AuthSuccess({required this.user});
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});
}
