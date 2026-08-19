import 'package:flutter/material.dart';

class AppStrings {
  static String currentLang = 'tr'; // 'tr' veya 'en'

  static final Map<String, Map<String, String>> _localizedValues = {
    'tr': {
      'loginTitle': 'Bilgi Yönetim Sistemi',
      'loginSubtitle': 'Size WhatsApp üzerinden iletilen kullanıcı adı ve şifrenizle giriş yapınız.',
      'emailHint': 'E-Posta / Kullanıcı Adı',
      'passwordHint': 'Şifre',
      'loginButton': 'Giriş Yap',
      'forgotPassword': 'Şifremi Unuttum',
      'welcome': 'Hoş Geldiniz',
      'teacherPortal': 'Öğretmen Paneli',
      'studentPortal': 'Öğrenci Paneli',
      'parentPortal': 'Veli Portalı',
      'adminPortal': 'Yönetici Paneli',
      'mySchedule': 'Ders Programım',
      'myStudents': 'Öğrencilerim',
      'createRequest': 'Talep Oluştur',
      'myProfile': 'Profilim',
      'logout': 'Çıkış Yap',
      'changeLanguage': 'Dil Seçeneği / Language',
      'joinZoom': 'Canlı Derse Katıl (Zoom)',
      'completeLesson': 'Dersi Tamamladım',
    },
    'en': {
      'loginTitle': 'Management System',
      'loginSubtitle': 'Please log in with the credentials sent via WhatsApp.',
      'emailHint': 'Email / Username',
      'passwordHint': 'Password',
      'loginButton': 'Log In',
      'forgotPassword': 'Forgot Password',
      'welcome': 'Welcome',
      'teacherPortal': 'Teacher Portal',
      'studentPortal': 'Student Portal',
      'parentPortal': 'Parent Portal',
      'adminPortal': 'Admin Portal',
      'mySchedule': 'My Schedule',
      'myStudents': 'My Students',
      'createRequest': 'Create Request',
      'myProfile': 'My Profile',
      'logout': 'Log Out',
      'changeLanguage': 'Language Settings',
      'joinZoom': 'Join Live Class (Zoom)',
      'completeLesson': 'Mark Lesson Complete',
    },
  };

  static final Map<String, String> _trToEnMap = {
    'Bilgi Yönetim Sistemi': 'Management System',
    'Size WhatsApp üzerinden iletilen kullanıcı adı ve şifrenizle giriş yapınız.': 'Please log in with the credentials sent via WhatsApp.',
    'E-Posta / Kullanıcı Adı': 'Email / Username',
    'Şifre': 'Password',
    'Giriş Yap': 'Log In',
    'Hoş Geldiniz': 'Welcome',
    'Öğretmen Paneli': 'Teacher Portal',
    'Öğrenci Paneli': 'Student Portal',
    'Veli Portalı': 'Parent Portal',
    'Yönetici Paneli': 'Admin Portal',
    'Ders Programım': 'My Schedule',
    'Öğrencilerim': 'My Students',
    'Talep Oluştur': 'Create Request',
    'Profilim': 'My Profile',
    'Ders Programı': 'Schedule',
    'Gelişim & Notlar': 'Progress & Notes',
    'Ödeme & IBAN': 'Payment & IBAN',
    'Öğretmen': 'Teacher',
    'Çıkış Yap': 'Log Out',
    'Ders:': 'Class:',
    'Saat:': 'Time:',
    'Veli Tel:': 'Parent Phone:',
    'Ders Notu ve Değerlendirme...': 'Class Feedback Notes...',
    'Ders Feedbacki': 'Class Feedback',
    'İptal': 'Cancel',
    'Gönder': 'Submit',
    'Kaydet': 'Save',
    'Planlandı': 'Planned',
    'Dersi Tamamladım': 'Mark Lesson Complete',
    'Canlı Derse Katıl (Zoom)': 'Join Live Class',
    'Canlı Derse Katıl': 'Join Live Class',
    'Seviye:': 'Level:',
    'İşlenen Kitap:': 'Covered Book:',
    'Son Ünite:': 'Current Unit:',
    'Geçmiş Gelişim Notları:': 'Past Progress Feedback Notes:',
    'Konu:': 'Subject:',
    'Tarihli Gelişim Notu / Feedback Ekle': 'Add Dated Progress Feedback',
    'Kitap, Ünite & Seviye Güncelle': 'Update Book, Unit & Level',
    'Henüz gelişim notu eklenmedi.': 'No progress notes added yet.',
    'Şifremi Değiştir': 'Change Password',
    'Mevcut Şifreniz': 'Current Password',
    'Yeni Şifre': 'New Password',
    'Yeni Şifre (Tekrar)': 'Confirm New Password',
    'Şifreyi Güncelle': 'Update Password',
    'Yeni şifreler eşleşmiyor!': 'New passwords do not match!',
    'Şifreniz Firebase üzerinde kalıcı olarak güncellendi!': 'Your password has been updated on Firebase!',
    '1. Hesap Oluşturma': '1. Create Accounts',
    '2. Öğretmenler & Program': '2. Teachers & Schedule',
    '3. Öğrenciler & Raporlar': '3. Students & Reports',
    '4. Talepler & Onaylar': '4. Requests & Approvals',
    '5. Canlı Ders Takvimi': '5. Master Schedule',
  };

  /// Hem Kod Adlarını ('loginTitle') Hem De Doğrudan Türkçe Metinleri Çeviren Akıllı Metot
  static String get(String key) {
    if (_localizedValues[currentLang]?.containsKey(key) ?? false) {
      return _localizedValues[currentLang]![key]!;
    }
    if (_localizedValues['tr']?.containsKey(key) ?? false) {
      final String trText = _localizedValues['tr']![key]!;
      if (currentLang == 'en') {
        return _trToEnMap[trText] ?? trText;
      }
      return trText;
    }
    return tr(key);
  }

  static String tr(String text) {
    if (currentLang == 'tr') return text;
    return _trToEnMap[text] ?? text;
  }
}

/// Helper utility for responsive font scaling, padding, and layout breakpoints.
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1050;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1050;

  /// Returns a responsive font size based on screen width.
  static double fontSize(BuildContext context, double baseSize) {
    final double width = MediaQuery.of(context).size.width;
    double scale = 1.0;
    if (width < 400) {
      scale = 0.78;
    } else if (width < 650) {
      scale = 0.85;
    } else if (width < 950) {
      scale = 0.92;
    }

    final double minSize = baseSize * 0.72;
    return (baseSize * scale).clamp(minSize, baseSize);
  }

  /// Returns responsive EdgeInsets padding.
  static EdgeInsets padding(
    BuildContext context, {
    double desktop = 24.0,
    double tablet = 16.0,
    double mobile = 12.0,
  }) {
    final double width = MediaQuery.of(context).size.width;
    if (width < 650) {
      return EdgeInsets.all(mobile);
    } else if (width < 1050) {
      return EdgeInsets.all(tablet);
    }
    return EdgeInsets.all(desktop);
  }
}
