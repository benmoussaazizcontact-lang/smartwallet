class Validators {
  Validators._();

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'emailRequired';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    if (!ok) return 'emailInvalid';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.length < 8) return 'passwordShort';
    return null;
  }

  static String? requiredName(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 2) return 'nameShort';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'passwordMismatch';
    return password(value);
  }
}
