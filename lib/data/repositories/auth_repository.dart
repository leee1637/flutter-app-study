import 'package:warehouse_app/data/models/user_model.dart';

/// Контракт работы с пользователями.
///
/// Экраны знают только этот интерфейс и не знают, откуда приходят данные —
/// из Firebase Auth, из локальной SQLite или из мока в тестах.
abstract class AuthRepository {
  Future<UserModel?> signIn({
    required String email,
    required String password,
  });

  /// Регистрация с автоматическим входом: возвращает уже авторизованного
  /// пользователя либо `null`, если что-то пошло не так.
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
  });

  Future<void> signOut();

  Future<void> resetPassword({required String email});

  /// Текущий пользователь сессии или `null`, если пользователь не залогинен.
  Future<UserModel?> getCurrentUser();

  /// Чтение из сети.
  Future<UserModel?> getUserById(String userId);

  /// Чтение из локального кэша, который наполняет синхронизация.
  /// Нужно для офлайна: сеть недоступна, а показать имя всё равно хочется.
  Future<UserModel?> getCachedUserById(String userId);

  Future<List<UserModel>> getAllUsers();

  Future<bool> isAdmin(String userId);
}
