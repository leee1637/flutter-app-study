import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:warehouse_app/core/constants/app_constants.dart';
import 'package:warehouse_app/data/models/user_model.dart';
import 'package:warehouse_app/data/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn? _googleSignIn;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseAuthRepository() : _googleSignIn = GoogleSignIn();

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn?.signOut();
    } catch (e) {
      print('Warning: Error during sign out: $e');
    }
  }

  @override
  Future<UserModel?> login(String email, String password) async {
    try {
      print('Попытка входа с email: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        print('❌ ОШИБКА: Пользователь не найден');
        return null;
      }
      print('✅ УСПЕШНЫЙ ВХОД! UID: ${credential.user?.uid}');
      final user = await _userFromFirestore(credential.user!.uid);
      print('✅ ДАННЫЕ ИЗ БАЗЫ: ${user?.toMap()}');
      return user;
    } on FirebaseAuthException catch (e) {
      print('❌ ОШИБКА АВТОРИЗАЦИИ: ${e.code} | ${e.message}');
      throw Exception('${e.message}');
    } catch (e) {
      print('❌ НЕИЗВЕСТНАЯ ОШИБКА: $e');
      throw Exception('$e');
    }
  }

  @override
  Future<void> register(String name, String email, String password) async {
    try {
      print('Попытка регистрации: $email ($name)');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        print('✅ УСПЕШНАЯ РЕГИСТРАЦИЯ! UID: ${userCredential.user!.uid}');
        final user = UserModel(
          id: userCredential.user!.uid,
          name: name,
          email: email,
          role: AppConstants.userRole,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .set(user.toMap());
        print('✅ ДАННЫЕ ПОЛЬЗОВАТЕЛЯ СОХРАНЕНЫ В БАЗЕ');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ ОШИБКА РЕГИСТРАЦИИ: ${e.code} | ${e.message}');
      throw Exception('${e.message}');
    } catch (e) {
      print('❌ НЕИЗВЕСТНАЯ ОШИБКА РЕГИСТРАЦИИ: $e');
      throw Exception('$e');
    }
  }

  @override
  Future<bool> isAdmin(String userId) async {
    final user = await _userFromFirestore(userId);
    return user?.role == AppConstants.adminRole;
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    final snapshot =
        await _firestore.collection(AppConstants.usersCollection).get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
}

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await _userFromFirestore(user.uid);
    }
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
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> _userFromFirestore(String uid) async {
    final doc =
        await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap({...doc.data()!, 'id': doc.id});
  }
}

