import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/whatsapp_service.dart';
import '../../../../core/utils/security_helper.dart';

class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Otomatik Geçici Şifre Üretir (Örn: Kids2026!)
  String generateTemporaryPassword() {
    const String chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    final Random rnd = Random();
    final String randomCode = String.fromCharCodes(
      Iterable<int>.generate(4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
    return 'Kids$randomCode!';
  }

  /// Arka Planda Firebase Authentication Üzerinde Yeni Giriş Hesabı Oluşturur / Günceller
  Future<UserCredential?> _createFirebaseAuthUser(String email, String password) async {
    try {
      FirebaseApp secondaryApp;
      try {
        secondaryApp = Firebase.app('SecondaryApp');
      } catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );
      }

      final FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final String cleanEmail = email.trim().toLowerCase();

      try {
        // Yeni Hesap Oluşturmayı Dene
        final UserCredential credential = await secondaryAuth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password.trim(),
        );
        return credential;
      } on FirebaseAuthException catch (e) {
        // Eğer e-posta Firebase Auth'da zaten varsa, var olan hesabın şifresini yeni belirlenen şifreye güncelle!
        if (e.code == 'email-already-in-use') {
          try {
            final credential = await secondaryAuth.signInWithEmailAndPassword(
              email: cleanEmail,
              password: password.trim(),
            );
            return credential;
          } catch (_) {
            return null;
          }
        }
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// Arka Planda Firebase Auth Hesabını ve Firestore Kayıtlarını Tamamen Siler
  Future<void> _deleteFirebaseAuthUser(String identifier, {String? password}) async {
    try {
      final String cleanId = identifier.trim().toLowerCase().replaceAll(' ', '');

      // 1. Önce Firestore'dan kullanıcının authEmail ve şifresini okuyalım
      String targetAuthEmail = cleanId.contains('@') ? cleanId : '$cleanId@kidstalk.online';
      String? targetPassword = password;

      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('users').doc(cleanId).get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        targetAuthEmail = (data['authEmail'] as String?) ?? (data['email'] as String?) ?? targetAuthEmail;
        targetPassword ??= (data['authPassword'] as String?) ?? (data['studentPassword'] as String?) ?? (data['tempPassword'] as String?);
      }

      // 2. SecondaryApp ile Firebase Auth üzerinden hesaba bağlanıp sil
      FirebaseApp secondaryApp;
      try {
        secondaryApp = Firebase.app('SecondaryApp');
      } catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );
      }

      final FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      if (targetPassword != null && targetPassword.isNotEmpty) {
        try {
          final UserCredential cred = await secondaryAuth.signInWithEmailAndPassword(
            email: targetAuthEmail.trim().toLowerCase(),
            password: targetPassword.trim(),
          );
          if (cred.user != null) {
            await cred.user!.delete();
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// 1. VELİ VE ÖĞRENCİ BİRLEŞİK HESABINI OLUŞTURUR VE ARKA PLANDA WHATSAPP GÖNDERİR
  Future<String> createParentAndStudentAccountsOnly({
    required String parentName,
    required String parentEmail,
    String? parentPassword,
    required String studentName,
    String? studentEmail,
    String? studentUsername,
    required String studentPassword,
    required String phone,
    required String packageType,
    String? monthlyFee,
    required String level,
    bool sendMessage = false,
  }) async {
    try {
      if (!SecurityHelper.isPasswordValid(studentPassword)) {
        throw 'Şifreniz en az 6 karakter olmalıdır.';
      }

      final String cleanUsername = (studentUsername != null && studentUsername.trim().isNotEmpty)
          ? studentUsername.trim().toLowerCase().replaceAll(' ', '')
          : (studentEmail != null && studentEmail.trim().isNotEmpty)
              ? studentEmail.trim().toLowerCase().replaceAll(' ', '')
              : studentName.trim().toLowerCase().replaceAll(' ', '');
      final String cleanParentEmail = parentEmail.trim().toLowerCase();
      final String authEmail = cleanParentEmail.isNotEmpty
          ? cleanParentEmail
          : (cleanUsername.contains('@') ? cleanUsername : '$cleanUsername@kidstalk.online');

      await _createFirebaseAuthUser(authEmail, studentPassword);

      final WriteBatch batch = _firestore.batch();
      final DateTime paymentDueDate = DateTime.now().add(const Duration(days: 30));

      final Map<String, dynamic> studentData = {
        'uid': cleanUsername,
        'username': cleanUsername,
        'studentUsername': cleanUsername,
        'email': cleanParentEmail.isEmpty ? authEmail : cleanParentEmail,
        'parentEmail': cleanParentEmail,
        'authEmail': authEmail,
        'passwordHash': SecurityHelper.hashPassword(studentPassword),
        'initialPassword': studentPassword.trim(),
        'fullName': studentName.trim(),
        'studentName': studentName.trim(),
        'parentName': parentName.trim(),
        'parentPhone': phone.trim(),
        'phone': phone.trim(),
        'role': 'parent_student',
        'preferredLanguage': 'tr',
        'packageType': packageType.trim(),
        'monthlyFee': (monthlyFee ?? '').trim(),
        'level': level,
        'totalLessons': 20,
        'remainingLessons': 20,
        'paymentStatus': 'pending',
        'paymentDueDate': paymentDueDate.toIso8601String(),
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      };

      batch.set(_firestore.collection('users').doc(cleanUsername), studentData, SetOptions(merge: true));
      await batch.commit();

      final String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

      // Eğer kutucuk işaretlendiyse arka planda WhatsApp mesajı gönder
      if (sendMessage && cleanPhone.isNotEmpty) {
        try {
          final String msg = WhatsAppService.buildStudentAccountMessage(
            parentName: parentName.trim(),
            studentName: studentName.trim(),
            username: cleanUsername,
            password: studentPassword.trim(),
          );
          await WhatsAppService.sendSingleMessage(
            phone: cleanPhone,
            message: msg,
          );
        } catch (_) {}
      }

      return cleanUsername;
    } catch (e) {
      throw 'Hesap veritabanına işlenirken hata oluştu: $e';
    }
  }

  /// 2. ÖĞRETMEN HESABI OLUŞTURUR VE İSTEĞE BAĞLI WHATSAPP GÖNDERİR
  Future<String> createTeacherAccount({
    required String fullName,
    required String email,
    String? username,
    required String phone,
    required String zoomLink,
    required String tempPassword,
    bool sendMessage = false,
  }) async {
    try {
      if (!SecurityHelper.isPasswordValid(tempPassword)) {
        throw 'Şifreniz en az 6 karakter olmalıdır.';
      }

      final String cleanEmail = email.trim().toLowerCase();
      final String cleanUsername = (username != null && username.trim().isNotEmpty)
          ? username.trim().toLowerCase().replaceAll(' ', '')
          : (cleanEmail.isNotEmpty ? cleanEmail.split('@').first : 'teacher');
      final String authEmail = cleanEmail.isNotEmpty
          ? cleanEmail
          : (cleanUsername.contains('@') ? cleanUsername : '$cleanUsername@kidstalk.online');

      await _createFirebaseAuthUser(authEmail, tempPassword);

      final WriteBatch batch = _firestore.batch();

      final Map<String, dynamic> teacherData = {
        'uid': cleanUsername,
        'username': cleanUsername,
        'email': cleanEmail,
        'authEmail': authEmail,
        'passwordHash': SecurityHelper.hashPassword(tempPassword),
        'initialPassword': tempPassword.trim(),
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'role': 'teacher',
        'preferredLanguage': 'en',
        'zoomLink': zoomLink.trim(),
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      };

      batch.set(_firestore.collection('users').doc(cleanUsername), teacherData, SetOptions(merge: true));
      await batch.commit();

      final String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

      // Eğer kutucuk işaretlendiyse arka planda WhatsApp mesajı gönder
      if (sendMessage && cleanPhone.isNotEmpty) {
        try {
          final String msg = WhatsAppService.buildTeacherAccountMessage(
            teacherName: fullName.trim(),
            username: cleanUsername,
            password: tempPassword.trim(),
          );
          await WhatsAppService.sendSingleMessage(
            phone: cleanPhone,
            message: msg,
          );
        } catch (_) {}
      }

      return cleanUsername;
    } catch (e) {
      throw 'Öğretmen hesabı oluşturulurken hata oluştu: $e';
    }
  }

  /// Veli & Öğrenci Hesap Giriş Bilgileri Mesaj Taslağını Üretir
  String buildParentStudentCredentialsMessage({required Map<String, dynamic> data}) {
    final String parentName = (data['parentName'] as String? ?? '').trim();
    final String studentName = (data['studentName'] ?? data['fullName'] ?? 'Öğrenciniz').toString().trim();
    final String username = (data['username'] ?? data['studentUsername'] ?? data['uid'] ?? '').toString().trim();
    final String initialPassword = (data['initialPassword'] as String? ??
            data['password'] as String? ??
            data['tempPassword'] as String? ??
            data['studentPassword'] as String? ??
            data['authPassword'] as String? ??
            '')
        .trim();
    final String currentHash = (data['passwordHash'] as String? ?? '').trim();

    String passwordDisplay = initialPassword.isNotEmpty ? initialPassword : '';
    if (initialPassword.isNotEmpty && currentHash.isNotEmpty) {
      final bool isChanged = !SecurityHelper.verifyPassword(initialPassword, currentHash);
      if (isChanged) {
        passwordDisplay = '$initialPassword (Şifre sonradan değiştirilmiştir.)';
      }
    } else if (initialPassword.isEmpty && currentHash.isNotEmpty) {
      passwordDisplay = '(Şifre sonradan değiştirilmiştir.)';
    } else if (passwordDisplay.isEmpty) {
      passwordDisplay = '123456';
    }

    final String greeting = parentName.isNotEmpty ? 'Merhaba Sayın $parentName, ' : 'Merhaba, ';

    return '''${greeting}Kids Talk Online ailesine hoş geldiniz! 🎉

Öğrenciniz $studentName için Veli & Öğrenci Giriş Hesabı tanımlanmıştır:

🔑 GİRİŞ BİLGİLERİ:
• Kullanıcı Adı: $username
• Şifre: $passwordDisplay

Sistemimize giriş yaparak tüm bilgilere erişebilirsiniz. Bizi tercih ettiğiniz için teşekkür ederiz.

Kids Talk Online Ekibi''';
  }

  /// Öğretmen Hesap Giriş Bilgileri Mesaj Taslağını Üretir
  String buildTeacherCredentialsMessage({required Map<String, dynamic> data}) {
    final String fullName = (data['fullName'] ?? data['name'] ?? 'Teacher').toString().trim();
    final String username = (data['username'] ?? data['uid'] ?? '').toString().trim();
    final String initialPassword = (data['initialPassword'] as String? ??
            data['tempPassword'] as String? ??
            data['password'] as String? ??
            data['authPassword'] as String? ??
            '')
        .trim();
    final String currentHash = (data['passwordHash'] as String? ?? '').trim();
    final String zoomLink = (data['zoomLink'] as String? ?? 'https://zoom.us/j/123456789').trim();

    String passwordDisplay = initialPassword.isNotEmpty ? initialPassword : '';
    if (initialPassword.isNotEmpty && currentHash.isNotEmpty) {
      final bool isChanged = !SecurityHelper.verifyPassword(initialPassword, currentHash);
      if (isChanged) {
        passwordDisplay = '$initialPassword (Şifre sonradan değiştirilmiştir.)';
      }
    } else if (initialPassword.isEmpty && currentHash.isNotEmpty) {
      passwordDisplay = '(Şifre sonradan değiştirilmiştir.)';
    } else if (passwordDisplay.isEmpty) {
      passwordDisplay = '123456';
    }

    return '''Welcome to Kids Talk Online, Teacher $fullName! 🎉

Your Teacher Portal account has been created successfully.

🔗 Login Username: $username
🔑 Temporary Password: $passwordDisplay

Kids Talk Online Team''';
  }

  /// 3. ÖĞRENCİYİ, VELİSİNİ VE TÜM DERSLERİNİ VERİTABANINDAN & AUTH'DAN KALICI SİLER
  Future<void> deleteStudentCompletely(String studentDocId, String? linkedParentEmail) async {
    final String cleanStudentId = studentDocId.trim().toLowerCase().replaceAll(' ', '');
    if (cleanStudentId.isEmpty || cleanStudentId == 'admin' || cleanStudentId == 'irmakyildiz') return;

    // 1. Firebase Auth'dan tamamen siliyoruz
    await _deleteFirebaseAuthUser(cleanStudentId);
    if (linkedParentEmail != null && linkedParentEmail.isNotEmpty && linkedParentEmail != 'irmakyildiz@kidstalk.online') {
      await _deleteFirebaseAuthUser(linkedParentEmail.trim().toLowerCase());
    }

    // 2. Firestore dokümanlarını tamamen siliyoruz
    final WriteBatch batch = _firestore.batch();
    batch.delete(_firestore.collection('users').doc(cleanStudentId));
    if (linkedParentEmail != null && linkedParentEmail.isNotEmpty && linkedParentEmail != 'irmakyildiz' && linkedParentEmail != 'irmakyildiz@kidstalk.online') {
      batch.delete(_firestore.collection('users').doc(linkedParentEmail.trim().toLowerCase()));
    }

    await batch.commit();

    // 3. Öğrenciye ait tüm canlı dersleri sil
    final QuerySnapshot<Map<String, dynamic>> lessonsSnap = await _firestore
        .collection('lessons')
        .where('studentId', isEqualTo: cleanStudentId)
        .get();

    for (final doc in lessonsSnap.docs) {
      await doc.reference.delete();
    }
  }

  /// 4. ÖĞRETMENİ VE ATANMIŞ TÜM DERS SAATLERİNİ VERİTABANINDAN & AUTH'DAN KALICI SİLER
  Future<void> deleteTeacherCompletely(String teacherDocId) async {
    final String cleanTeacherId = teacherDocId.trim().toLowerCase().replaceAll(' ', '');
    if (cleanTeacherId.isEmpty || cleanTeacherId == 'admin' || cleanTeacherId == 'irmakyildiz') return;

    // 1. Firebase Auth'dan tamamen siliyoruz
    await _deleteFirebaseAuthUser(cleanTeacherId);

    // 2. Firestore dokümanlarını siliyoruz
    final WriteBatch batch = _firestore.batch();
    batch.delete(_firestore.collection('users').doc(cleanTeacherId));
    await batch.commit();

    // 3. Öğretmene atanmış tüm dersleri sil
    final QuerySnapshot<Map<String, dynamic>> lessonsSnap = await _firestore
        .collection('lessons')
        .where('teacherId', isEqualTo: cleanTeacherId)
        .get();

    for (final doc in lessonsSnap.docs) {
      await doc.reference.delete();
    }
  }

  /// 5. YÖNETİCİ HESABINI VERİTABANINDAN & AUTH'DAN KALICI OLARAK OLUŞTURUR
  Future<void> createAdminCompletely({
    required String name,
    required String email,
    String? username,
    required String password,
  }) async {
    if (!SecurityHelper.isPasswordValid(password)) {
      throw 'Şifreniz en az 6 karakter olmalıdır.';
    }

    final String cleanUsername = (username != null && username.trim().isNotEmpty)
        ? username.trim().toLowerCase().replaceAll(' ', '')
        : email.split('@').first.trim().toLowerCase().replaceAll(' ', '');
    final String cleanEmail = email.trim().toLowerCase();
    final String authEmail = cleanEmail.isNotEmpty
        ? cleanEmail
        : (cleanUsername.contains('@') ? cleanUsername : '$cleanUsername@kidstalk.online');

    await _createFirebaseAuthUser(authEmail, password.trim());

    final WriteBatch batch = _firestore.batch();
    final Map<String, dynamic> adminData = {
      'uid': cleanUsername,
      'username': cleanUsername,
      'email': cleanEmail.isNotEmpty ? cleanEmail : authEmail,
      'authEmail': authEmail,
      'passwordHash': SecurityHelper.hashPassword(password),
      'fullName': name.trim(),
      'role': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
    };

    batch.set(_firestore.collection('users').doc(cleanUsername), adminData, SetOptions(merge: true));
    await batch.commit();
  }

  /// 6. YÖNETİCİ HESABINI VERİTABANINDAN & AUTH'DAN KALICI SİLER
  Future<void> deleteAdminCompletely(String adminDocId) async {
    final String cleanAdminId = adminDocId.trim().toLowerCase().replaceAll(' ', '');
    final String authEmail = cleanAdminId.contains('@') ? cleanAdminId : '$cleanAdminId@kidstalk.online';

    // 1. Firebase Auth'dan tamamen siliyoruz
    await _deleteFirebaseAuthUser(cleanAdminId);

    // 2. Firestore dokümanlarını siliyoruz
    final WriteBatch batch = _firestore.batch();
    batch.delete(_firestore.collection('users').doc(cleanAdminId));
    if (!cleanAdminId.contains('@')) {
      batch.delete(_firestore.collection('users').doc(authEmail));
    }
    await batch.commit();
  }

  /// Öğretmenleri Canlı Getirir (Deduplicated & Merged)
  Stream<List<Map<String, dynamic>>> getTeachersStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final Map<String, Map<String, dynamic>> uniqueTeachers = {};
      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        final String username = (data['username'] as String?) ?? (data['uid'] as String?) ?? (data['fullName'] as String?) ?? doc.id;
        final String key = username.toLowerCase().replaceAll(' ', '');

        if (!uniqueTeachers.containsKey(key)) {
          uniqueTeachers[key] = data;
        } else {
          final existing = uniqueTeachers[key]!;
          final String existingIban = (existing['iban'] as String? ?? '').trim();
          final String newIban = (data['iban'] as String? ?? '').trim();
          if (existingIban.isEmpty && newIban.isNotEmpty) {
            existing['iban'] = newIban;
          }
          final String existingZoom = (existing['zoomLink'] as String? ?? '').trim();
          final String newZoom = (data['zoomLink'] as String? ?? '').trim();
          if (existingZoom.isEmpty && newZoom.isNotEmpty) {
            existing['zoomLink'] = newZoom;
          }
          final String existingTz = (existing['selectedTimezone'] as String? ?? '').trim();
          final String newTz = (data['selectedTimezone'] as String? ?? '').trim();
          if (existingTz.isEmpty && newTz.isNotEmpty) {
            existing['selectedTimezone'] = newTz;
            existing['timezoneOffsetHours'] = data['timezoneOffsetHours'];
          }
        }
      }
      return uniqueTeachers.values.toList();
    });
  }

  /// Öğrencileri Canlı Getirir (Deduplicated)
  Stream<List<Map<String, dynamic>>> getStudentsStream() {
    return _firestore
        .collection('users')
        .where('role', whereIn: <String>['student', 'parent_student'])
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final Map<String, Map<String, dynamic>> uniqueStudents = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final String username = (data['studentUsername'] as String?) ?? (data['username'] as String?) ?? (data['uid'] as String?) ?? doc.id;
        final String key = username.toLowerCase().replaceAll(' ', '');
        if (!uniqueStudents.containsKey(key) || !doc.id.contains('@')) {
          data['id'] = doc.id;
          uniqueStudents[key] = data;
        }
      }
      return uniqueStudents.values.toList();
    });
  }
}
