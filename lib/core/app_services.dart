import 'package:warehouse_app/data/sync/sync_manager.dart';
import 'package:warehouse_app/data/local/database_helper.dart';

class AppServices {
  static SyncManager? syncManager;

  static Future<void> clearAllData() async {
    // Clear local database
    await DatabaseHelper().clearDatabase();

    // Reset sync manager reference if needed
    syncManager = null;
  }

  static Future<void> resetDatabase() async {
    await DatabaseHelper().resetDatabase();
    syncManager = null;
  }
}

