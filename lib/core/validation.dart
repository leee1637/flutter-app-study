class Validation {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email обязателен';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Введите корректный Email';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Имя обязательно';
    }
    if (value.length < 2) {
      return 'Имя должно содержать хотя бы 2 символа';
    }
    return null;
  }

  static String? validatePassword(String? value, {bool isRequired = false}) {
    if (value == null || value.isEmpty) {
      if (isRequired) {
        return 'Пароль обязателен';
      }
      return null;
    }
    if (value.length < 6) {
      return 'Пароль должен быть не менее 6 символов';
    }
    return null;
  }
}