import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class WhatsAppSendResult {
  final bool isSuccess;
  final String? errorMessage;
  final String formattedPhone;

  const WhatsAppSendResult({
    required this.isSuccess,
    this.errorMessage,
    required this.formattedPhone,
  });
}

class WhatsAppService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static Map<String, String>? _cachedSettings;
  static DateTime? _lastSettingsFetch;

  /// Firestore'dan kayıtlı WhatsApp API ayarlarını çeker (Hafıza önbellekli)
  static Future<Map<String, String>> getSettings({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedSettings != null &&
        _lastSettingsFetch != null &&
        DateTime.now().difference(_lastSettingsFetch!).inMinutes < 10) {
      return _cachedSettings!;
    }

    try {
      final doc = await _db.collection('system_settings').doc('whatsapp').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final String inst = (data['instanceId'] as String? ?? '').trim();
        final String tok = (data['token'] as String? ?? '').trim();
        _cachedSettings = {
          'instanceId': inst,
          'token': tok,
          'provider': (data['provider'] as String? ?? 'ultramsg').trim(),
        };
        _lastSettingsFetch = DateTime.now();
        return _cachedSettings!;
      }
    } catch (_) {}

    _cachedSettings = {'instanceId': '', 'token': '', 'provider': 'ultramsg'};
    _lastSettingsFetch = DateTime.now();
    return _cachedSettings!;
  }

  /// WhatsApp API ayarlarını kaydeder
  static Future<void> saveSettings({required String instanceId, required String token}) async {
    _cachedSettings = {
      'instanceId': instanceId.trim(),
      'token': token.trim(),
      'provider': 'ultramsg',
    };
    _lastSettingsFetch = DateTime.now();

    await _db.collection('system_settings').doc('whatsapp').set({
      'instanceId': instanceId.trim(),
      'token': token.trim(),
      'provider': 'ultramsg',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Telefon numarasını uluslararası formata dönüştürür (örn: +90532... -> 90532..., 0532... -> 90532...)
  static String formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) return '';

    if (cleaned.startsWith('00')) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = '90${cleaned.substring(1)}';
    } else if (cleaned.length == 10 && cleaned.startsWith('5')) {
      cleaned = '90$cleaned';
    }
    return cleaned;
  }

  /// Gün ismini cihazın canlı tarihine göre "14 Ağustos Cuma" formatına çevirir
  static String formatFullDate(String dayName) {
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = Monday, ..., 7 = Sunday

    int targetWeekday = currentWeekday;
    final d = dayName.trim().toLowerCase();
    if (d.contains('pazartesi') || d.contains('mon')) {
      targetWeekday = 1;
    } else if (d.contains('salı') || d.contains('sali') || d.contains('tue')) {
      targetWeekday = 2;
    } else if (d.contains('çarşamba') || d.contains('carsamba') || d.contains('wed')) {
      targetWeekday = 3;
    } else if (d.contains('perşembe') || d.contains('persembe') || d.contains('thu')) {
      targetWeekday = 4;
    } else if (d.contains('cumartesi') || d.contains('sat')) {
      targetWeekday = 6;
    } else if (d.contains('cuma') || d.contains('fri')) {
      targetWeekday = 5;
    } else if (d.contains('pazar') || d.contains('sun')) {
      targetWeekday = 7;
    }

    final diff = targetWeekday - currentWeekday;
    final targetDate = now.add(Duration(days: diff));

    const monthsTr = <String>[
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    const daysTr = <String>[
      'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'
    ];

    final dayNum = targetDate.day;
    final monthName = monthsTr[targetDate.month - 1];
    final dayOfWeek = daysTr[targetDate.weekday - 1];

    return '$dayNum $monthName $dayOfWeek';
  }

  /// Öğrenci ve veli hesap giriş bilgileri mesajını hazırlar
  static String buildStudentAccountMessage({
    required String parentName,
    required String studentName,
    required String username,
    required String password,
  }) {
    return '''Sayın $parentName,

Öğrencimiz $studentName için Kids Talk Online platformu hesabınız oluşturulmuştur.

Giriş Bilgileriniz:
Kullanıcı Adı: $username
Şifre: $password
Giriş Paneli: https://kidstalk.online/lms

Sisteme giriş yaparak size özel hazırlanan ders programınızı, öğretmen bilgilerinizi ve ödevlerinizi takip edebilirsiniz.

Kids Talk Online Ekibi''';
  }

  /// Öğretmen hesap giriş bilgileri mesajını hazırlar
  static String buildTeacherAccountMessage({
    required String teacherName,
    required String username,
    required String password,
  }) {
    return '''Dear $teacherName,

Your teacher account on the Kids Talk Online platform has been created.

Login Credentials:
Username / ID: $username
Password: $password
Portal: https://kidstalk.online/lms

Kids Talk Online Team''';
  }

  /// Mesaj metnini hazırlar
  static String buildLessonMessage({
    required String studentName,
    required String day,
    required String time,
    required String zoomLink,
    bool isDemo = false,
  }) {
    final String cleanZoom = zoomLink.trim().isEmpty ? 'https://zoom.us' : zoomLink.trim();
    String startTime = time.trim();
    if (startTime.contains('-')) {
      startTime = startTime.split('-').first.trim();
    }

    final String fullDateStr = formatFullDate(day);
    final String lessonTypeTitle = isDemo ? 'İngilizce demo dersi' : 'İngilizce dersi';

    return '''Sayın Velimiz,

Çocuğunuz $studentName için $lessonTypeTitle $fullDateStr günü saat $startTime’da başlayacaktır. Derse katılmak için aşağıdaki linki kullanabilirsiniz:

$cleanZoom

Ders başlamadan birkaç dakika önce giriş yapmanızı rica ederiz. Herhangi bir giriş koduna ihtiyaç yoktur, ders saati geldiğinde öğretmenimiz giriş izni verecektir.

Teşekkürler,
Kids Talk Online Ekibi''';
  }

  /// UltraMsg API üzerinden tekil WhatsApp mesajını ARKA PLANDA gönderir
  static Future<WhatsAppSendResult> sendSingleMessageDetailed({
    required String phone,
    required String message,
  }) async {
    final settings = await getSettings();
    final String instanceId = settings['instanceId'] ?? '';
    final String token = settings['token'] ?? '';

    return sendSingleMessageWithConfig(
      phone: phone,
      message: message,
      instanceId: instanceId,
      token: token,
    );
  }

  /// Hızlı, konfigürasyonu önceden yüklenmiş ve HTTP Client yeniden kullanan gönderim
  static Future<WhatsAppSendResult> sendSingleMessageWithConfig({
    required String phone,
    required String message,
    required String instanceId,
    required String token,
    http.Client? client,
  }) async {
    final String formattedPhone = formatPhoneNumber(phone);
    if (formattedPhone.isEmpty || formattedPhone.length < 7) {
      return const WhatsAppSendResult(
        isSuccess: false,
        errorMessage: 'Geçersiz telefon numarası. Lütfen veli numarasını kontrol edin.',
        formattedPhone: '',
      );
    }

    if (instanceId.isEmpty || token.isEmpty) {
      return WhatsAppSendResult(
        isSuccess: false,
        errorMessage: 'WhatsApp API ayarları (Instance ID veya Token) tanımlanmamış. Lütfen Yönetim Panelinden API ayarlarını kaydediniz.',
        formattedPhone: formattedPhone,
      );
    }

    final httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;
    String? lastError;

    // 1. YÖNTEM: UltraMsg Form-UrlEncoded POST
    try {
      final url = Uri.parse('https://api.ultramsg.com/$instanceId/messages/chat');
      final response = await httpClient.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'token': token,
          'to': formattedPhone,
          'body': message,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic resData = jsonDecode(response.body);
        if (resData is Map) {
          if (resData['sent'] == 'true' || resData['sent'] == true || resData['id'] != null || resData['message'] == 'ok') {
            return WhatsAppSendResult(isSuccess: true, formattedPhone: formattedPhone);
          }
          if (resData['error'] != null) {
            lastError = resData['error'].toString();
          }
        }
      } else {
        try {
          final dynamic resData = jsonDecode(response.body);
          if (resData is Map && resData['error'] != null) {
            lastError = resData['error'].toString();
          }
        } catch (_) {
          lastError = 'API yanıt kodu: ${response.statusCode}';
        }
      }
    } catch (e) {
      lastError = e.toString();
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }

    return WhatsAppSendResult(
      isSuccess: false,
      errorMessage: lastError ?? 'WhatsApp mesaj gönderimi başarısız oldu.',
      formattedPhone: formattedPhone,
    );
  }

  /// Basit boolean döndüren arka plan gönderim metodu
  static Future<bool> sendSingleMessage({
    required String phone,
    required String message,
  }) async {
    final result = await sendSingleMessageDetailed(phone: phone, message: message);
    return result.isSuccess;
  }

  /// Kullanıcı manuel olarak WhatsApp Web açmak isterse çağrılacak fonksiyon
  static Future<bool> openWhatsAppDirect(String phone, String message) async {
    final String cleanPhone = formatPhoneNumber(phone);
    final String encodedMsg = Uri.encodeComponent(message);
    final Uri uri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMsg');

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
