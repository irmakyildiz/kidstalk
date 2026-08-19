import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityHelper {
  // Projeye özel gizli kriptografik tuz (Salt)
  static const String _appSalt = 'KidsTalk_Online_Secure_Salt_2026!#*';

  /// Verilen şifreyi SHA-256 + Salt ile tek yönlü karmaşık hash metnine dönüştürür
  static String hashPassword(String password) {
    final String trimmed = password.trim();
    if (trimmed.isEmpty) return '';

    // Şifreyi tuz ile birleştirip SHA-256 hash üretir
    final List<int> bytes = utf8.encode('$_appSalt:$trimmed:$_appSalt');
    final Digest digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Kullanıcının girdiği şifreyi kayıtlı hash ile karşılaştırır
  static bool verifyPassword(String inputPassword, String storedHash) {
    if (inputPassword.trim().isEmpty || storedHash.trim().isEmpty) return false;
    return hashPassword(inputPassword) == storedHash.trim();
  }

  /// Şifrenin en az 6 karakter olup olmadığını doğrular
  static bool isPasswordValid(String password) {
    return password.trim().length >= 6;
  }

  /// Şifre kuralı hata mesajını döndürür (en az 6 karakter)
  static String? validatePassword(String password) {
    final String trimmed = password.trim();
    if (trimmed.isEmpty) {
      return 'Şifre alanı boş bırakılamaz.';
    }
    if (trimmed.length < 6) {
      return 'Şifreniz en az 6 karakter olmalıdır.';
    }
    return null;
  }
}
