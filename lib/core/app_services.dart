import 'package:warehouse_app/data/sync/sync_manager.dart';

/// Глобальный сервисный локатор.
///
/// Существует, чтобы [SyncManager] (который создаётся в `main`) был доступен
/// репозиториям без прокидывания через цепочку Riverpod-провайдеров —
/// иначе возник бы циклический импорт/зависимость.
class AppServices {
  static SyncManager? syncManager;
}
