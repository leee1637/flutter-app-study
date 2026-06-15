import 'package:warehouse_app/core/constants/app_constants.dart';
import 'package:warehouse_app/data/local/daos/user_dao.dart';
import 'package:warehouse_app/data/local/database_helper.dart';
import 'package:warehouse_app/data/models/user_model.dart';
import 'package:warehouse_app/data/repositories/auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  final UserDao userDao;

  LocalAuthRepository() : userDao = UserDao(DatabaseHelper()); // Update to use constructor instead of instance

  @override
  Future<void> logout() async {
    // Local implementation doesn't require any special logout logic
    // State will be cleared by the AuthNotifier
  }

  @override
  Future<void> register(String name, String email, String password) async {
    final existingUser = await userDao.getUserByEmail(email);
    if (existingUser != null) {
      throw Exception('User with this email already exists');
    }

    final users = await userDao.getAllUsers();
    final role = users.isEmpty
        ? AppConstants.adminRole
        : AppConstants.userRole;

    final newUser = UserModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      email: email,
      role: role,
      createdAt: DateTime.now(),
      password: password,
    );

    await userDao.insertUser(newUser);
  }

  @override
  Future<UserModel?> login(String email, String password) async {
    final user = await userDao.getUserByEmail(email);
    if (user == null || user.password != password) {
      return null;
    }
    return user;
  }

  @override
  Future<bool> isAdmin(String userId) async {
    final user = await userDao.getUserById(userId);
    return user?.role == AppConstants.adminRole;
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    return await userDao.getAllUsers();
  }

  // Added methods

  @override
  Future<UserModel?> getCurrentUser() async {
    // For local storage, we'd need to store current user info
    // This can be implemented with shared preferences or similar
    // For now, returning null
    return null;
  }

  @override
  Future<UserModel?> signIn({required String email, required String password}) async {
    return await login(email, password);
  }

  @override
  Future<UserModel?> signUp({required String email, required String password, required String name}) async {
    await register(name, email, password);
    return await login(email, password);
  }

  @override
  Future<void> signOut() async {
    await logout();
  }

  @override
  Future<void> resetPassword({required String email}) async {
    // For local implementation, could send notification/email if supported
    // For now, just a placeholder
  }

  @override
  // For local repository, this will always be null
  // We're returning null since we're not using Firebase
  get currentUser => null;
}


