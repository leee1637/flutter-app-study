import 'package:sqflite/sqflite.dart';
import 'package:warehouse_app/data/local/database_helper.dart';
import 'package:warehouse_app/data/models/user_model.dart';

/// Доступ к таблице `users`. Помимо CRUD умеет отвечать на вопрос
/// «есть ли вообще пользователи» — это нужно, чтобы выдать роль администратора
/// первому зарегистрировавшемуся.
class UserDao {
  final DatabaseHelper dbHelper;

  UserDao(this.dbHelper);

  Future<void> insertUser(UserModel user) async {
    final db = await dbHelper.database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Полная замена содержимого таблицы одной транзакцией.
  ///
  /// Именно транзакция, а не «стереть, потом вставить»: синхронизация
  /// запускается при старте приложения, и если она упадёт посередине,
  /// пользователь останется без локального списка сотрудников.
  Future<void> replaceAll(List<UserModel> users) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('users');
      for (final user in users) {
        await txn.insert(
          'users',
          user.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<UserModel?> getUserById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await dbHelper.database;
    final maps =
        await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await dbHelper.database;
    final maps = await db.query('users');
    return List.generate(maps.length, (i) => UserModel.fromMap(maps[i]));
  }

  /// Первая строка таблицы или `null`, если таблица пуста.
  Future<void> updateUser(UserModel user) async {
    final db = await dbHelper.database;
    await db
        .update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }
}
