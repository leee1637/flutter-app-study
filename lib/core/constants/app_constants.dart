/// Константы приложения: единое место, где живут «магические» строки —
/// имена коллекций Firestore, статусы товара, тексты ошибок.
///
/// Зачем это нужно: строки разбросаны по коду — их пришлось бы искать
/// глазами, а опечатка в имени коллекции или статуса даёт «тихий» баг
/// (запись уходит не туда, UI показывает «Неизвестно»).
class AppConstants {
  static const String appName = 'Warehouse App';

  // --- Firebase ---
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';

  // --- Роли ---
  static const String adminRole = 'admin';
  static const String userRole = 'user';

  /// Первый зарегистрировавшийся пользователь становится администратором.
  ///
  /// Нужно, чтобы склад не остался без возможности заводить товары:
  /// в Firebase Auth нет «первого пользователя», а роль нельзя задать из UI
  /// (иначе любой зарегистрировавшийся назначил бы себя админом).
  ///
  /// ВНИМАНИЕ: проверка «я первый» выполняется на клиенте, поэтому её можно
  /// обойти, если злоумышленник пишет в Firestore напрямую. Для продакшена роль
  /// нужно выдавать через Firebase Custom Claims (Admin SDK) и проверять в
  /// Security Rules. Здесь — учебный вариант: поставьте `false`, если проект
  /// уже заполнен и админ назначен вручную.
  static const bool firstRegisteredUserIsAdmin = true;

  // --- Товары ---
  static const String statusAvailable = 'available';
  static const String statusTaken = 'taken';

  /// Префикс временного идентификатора товара, созданного офлайн.
  /// Позволяет отличить «ещё не залитое в облако» от «уже облачного».
  static const String localIdPrefix = 'local_';

  static bool isLocalId(String id) => id.startsWith(localIdPrefix);

  static String newLocalId() =>
      '$localIdPrefix${DateTime.now().millisecondsSinceEpoch}';

  // --- Внешние сервисы ---
  /// imgbb.com — бесплатный хостинг картинок. Выбран потому, что QR-код
  /// должен вести на ссылку, которую откроет любой браузер.
  /// Ключ бесплатный, для продакшена хранение ключа в коде недопустимо.
  static const String imgbbApiKey = '64e8f0510693f02e98bca6985a4bc67e';
  static const String imgbbUploadEndpoint = 'https://api.imgbb.com/1/upload';
}
