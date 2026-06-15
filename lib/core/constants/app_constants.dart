class AppConstants {
  static const String appName = 'Warehouse App';
  static const String usersCollection = 'users';
  static const String productsCollection = 'products'; // Added missing collection
  static const String adminRole = 'admin';
  static const String userRole = 'user';

  /// Base URL for QR links — opens product page in browser.
  static const String appWebBaseUrl = 'https://dz11-1c536.firebaseapp.com';

  static String productQrUrl(String productId) => '$appWebBaseUrl/qr/$productId';

  /// imgbb.com free image hosting API key.
  /// Get yours free at: https://api.imgbb.com/
  static const String imgbbApiKey = '64e8f0510693f02e98bca6985a4bc67e';

  // Сообщения об ошибках
  static const String emailEmptyError = 'Введите email';
  static const String invalidEmailError = 'Некорректный email';
  static const String passwordEmptyError = 'Введите пароль';
  static const String passwordLengthError = 'Пароль должен быть не менее 6 символов';
}

