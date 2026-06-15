import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warehouse_app/data/local/daos/user_dao.dart';
import 'package:warehouse_app/data/local/database_helper.dart';

final userNameProvider = FutureProvider.family<String?, String>((ref, userId) async {
  final user = await UserDao(DatabaseHelper()).getUserById(userId);
  return user?.name;
});

