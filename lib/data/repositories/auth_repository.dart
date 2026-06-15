import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:warehouse_app/data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> login(String email, String password);
  Future<void> register(String name, String email, String password);
  Future<bool> isAdmin(String userId);
  Future<void> logout();  // Added missing method
  Future<List<UserModel>> getAllUsers(); // Added missing method
  Future<UserModel?> getCurrentUser();
  Future<UserModel?> signIn({required String email, required String password});
  Future<UserModel?> signUp({required String email, required String password, required String name});
  Future<void> signOut();
  Future<void> resetPassword({required String email});
  fb_auth.User? get currentUser;
}

