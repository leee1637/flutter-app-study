import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:warehouse_app/core/constants/app_constants.dart';
import 'package:warehouse_app/data/local/daos/user_dao.dart';
import 'package:warehouse_app/data/local/database_helper.dart';
import 'package:warehouse_app/data/models/user_model.dart';
import 'package:warehouse_app/data/repositories/auth_repository.dart';

/// Реализация [AuthRepository] поверх Firebase Auth + Firestore.
///
/// Firebase Auth умеет хранить только email/пароль/uid, поэтому бизнес-поля
/// (имя, роль) лежат в отдельной коллекции `users`, а ключом документа служит uid.
///
/// Локальный [UserDao] используется только как кэш чтения: его наполняет
/// `SyncManager`, и он позволяет показывать имя пользователя без сети.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserDao _userDao = UserDao(DatabaseHelper());

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  @override
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) return null;

      return await getUserById(firebaseUser.uid);
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyMessage(e));
    } on FirebaseException catch (e) {
      throw Exception('Ошибка базы данных: ${e.message}');
    }
  }

  @override
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Не удалось создать пользователя');
      }

      await firebaseUser.updateDisplayName(name);

      final user = UserModel(
        id: firebaseUser.uid,
        name: name,
        email: email,
        // Первый пользователь в системе становится администратором,
        // чтобы склад не остался без возможности заводить товары.
        role: await _resolveRole(),
        createdAt: DateTime.now(),
      );

      await _users.doc(user.id).set(user.toMap());

      // Сразу входим: регистрация = создание аккаунта + автологин,
      // пользователю не нужно ещё раз вводить пароль.
      return await signIn(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyMessage(e));
    } on FirebaseException catch (e) {
      throw Exception('Ошибка базы данных: ${e.message}');
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return getUserById(firebaseUser.uid);
  }

  @override
  Future<UserModel?> getUserById(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<UserModel?> getCachedUserById(String userId) {
    return _userDao.getUserById(userId);
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _users.get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<bool> isAdmin(String userId) async {
    final user = await getUserById(userId);
    return user?.role == AppConstants.adminRole;
  }

  /// Роль для нового пользователя: `admin`, если в системе ещё никого нет,
  /// иначе `user`. Проверка идёт по локальному кэшу, а по облаку — только
  /// когда кэш пуст (первый запуск на устройстве).
  Future<String> _resolveRole() async {
    if (!AppConstants.firstRegisteredUserIsAdmin) return AppConstants.userRole;
    try {
      final snapshot = await _users.limit(1).get();
      if (snapshot.docs.isEmpty) return AppConstants.adminRole;
    } on FirebaseException {
      return AppConstants.userRole;
    }
    return AppConstants.userRole;
  }

  /// Человеческие тексты ошибок Firebase Auth.
  ///
  /// `invalid-credential` Firebase отдаёт и для несуществующего email, и для
  /// неверного пароля — специально, чтобы нельзя было перебором выяснить,
  /// какие email зарегистрированы.
  String _friendlyMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Некорректный email';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Неверный email или пароль';
      case 'email-already-in-use':
        return 'Пользователь с таким email уже зарегистрирован';
      case 'weak-password':
        return 'Пароль слишком слабый, нужно минимум 6 символов';
      case 'network-request-failed':
        return 'Нет доступа к сети';
      case 'too-many-requests':
        return 'Слишком много попыток, попробуйте позже';
      default:
        return e.message ?? 'Ошибка авторизации';
    }
  }
}
