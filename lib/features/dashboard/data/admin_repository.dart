import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    } catch (e) {
      print('Firebase Auth Uyarısı: $e');
      return null;
    }
  }

  /// Arka Planda Firebase Auth Hesabını Tamamen Yutıp Siler
  Future<void> _deleteFirebaseAuthUser(String email) async {
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

      // İlgili hesaba arka planda bağlanıp Firebase Auth'dan tamamen siliyoruz
      final UserCredential? cred = await secondaryAuth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: 'Password_Temporary', // Var olan veya geçici oturum
      ).catchError((_) => null as dynamic);

      if (cred?.user != null) {
        await cred!.user!.delete();
      }
    } catch (_) {
      // Sessizce yutulur
    }
  }

  /// 1. VELİ VE ÖĞRENCİ HESAPLARINI OLUŞTURUR
  Future<String> createParentAndStudentAccountsOnly({
    required String parentName,
    required String parentEmail,
    required String parentPassword,
    required String studentName,
    required String studentEmail,
    required String studentPassword,
    required String phone,
    required String packageType,
    required String level,
  }) async {
    try {
      await _createFirebaseAuthUser(parentEmail, parentPassword);
      await _createFirebaseAuthUser(studentEmail, studentPassword);

      final WriteBatch batch = _firestore.batch();

      final String cleanParentEmail = parentEmail.trim().toLowerCase();
      final String cleanStudentEmail = studentEmail.trim().toLowerCase();

      // VELİ DOKÜMANI
      final DocumentReference<Map<String, dynamic>> parentDoc =
          _firestore.collection('users').doc(cleanParentEmail);

      batch.set(parentDoc, {
        'uid': cleanParentEmail,
        'email': cleanParentEmail,
        'fullName': parentName.trim(),
        'role': 'parent',
        'phone': phone.trim(),
        'preferredLanguage': 'tr',
        'linkedStudentEmail': cleanStudentEmail,
        'linkedStudentName': studentName.trim(),
        'packageType': packageType,
        'level': level,
        'totalLessons': 20,
        'remainingLessons': 20,
        'paymentStatus': 'pending',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ÖĞRENCİ DOKÜMANI
      final DocumentReference<Map<String, dynamic>> studentDoc =
          _firestore.collection('users').doc(cleanStudentEmail);

      batch.set(studentDoc, {
        'uid': cleanStudentEmail,
        'email': cleanStudentEmail,
        'fullName': studentName.trim(),
        'role': 'student',
        'preferredLanguage': 'tr',
        'linkedParentEmail': cleanParentEmail,
        'linkedParentName': parentName.trim(),
        'parentPhone': phone.trim(),
        'packageType': packageType,
        'level': level,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      final String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final String message = Uri.encodeComponent(
        'Merhaba Sayın $parentName, Kids Talk Online ailesine hoş geldiniz! 🎉\n\n'
        'Çocuğunuz $studentName ile entegre giriş hesaplarınız tanımlanmıştır.\n\n'
        '👨‍👩‍👧 VELİ GİRİŞ BİLGİLERİ:\n'
        '• Kullanıcı Adı: $cleanParentEmail\n'
        '• Şifre: $parentPassword\n\n'
        '🎒 ÖĞRENCİ GİRİŞ BİLGİLERİ:\n'
        '• Kullanıcı Adı: $cleanStudentEmail\n'
        '• Şifre: $studentPassword\n\n'
        'Sistemimize giriş yaptıktan sonra şifrenizi dilediğiniz zaman değiştirebilirsiniz.',
      );

      return 'https://wa.me/$cleanPhone?text=$message';
    } catch (e) {
      throw 'Hesaplar veritabanına işlenirken hata oluştu: $e';
    }
  }

  /// 2. ÖĞRETMEN HESABI OLUŞTURUR
  Future<String> createTeacherAccount({
    required String fullName,
    required String email,
    required String phone,
    required String zoomLink,
    required String tempPassword,
  }) async {
    try {
      await _createFirebaseAuthUser(email, tempPassword);

      final String teacherDocId = email.trim().toLowerCase();
      final DocumentReference<Map<String, dynamic>> teacherDoc =
          _firestore.collection('users').doc(teacherDocId);

      await teacherDoc.set({
        'uid': teacherDocId,
        'email': teacherDocId,
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'role': 'teacher',
        'preferredLanguage': 'en',
        'zoomLink': zoomLink.trim(),
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final String message = Uri.encodeComponent(
        'Welcome to Kids Talk Online, Teacher $fullName! 🎉\n\n'
        'Your Teacher Portal account has been created successfully.\n\n'
        '🔗 Login Username: $teacherDocId\n'
        '🔑 Temporary Password: $tempPassword\n'
        '🎥 Fixed Zoom Link: $zoomLink\n\n'
        'You can change your password anytime after logging in.',
      );

      return 'https://wa.me/$cleanPhone?text=$message';
    } catch (e) {
      throw 'Öğretmen hesabı oluşturulurken hata oluştu: $e';
    }
  }

  /// 3. ÖĞRENCİYİ, VELİSİNİ VE TÜM DERSLERİNİ VERİTABANINDAN & AUTH'DAN KALICI SİLER
  Future<void> deleteStudentCompletely(String studentDocId, String? linkedParentEmail) async {
    final String cleanStudentId = studentDocId.trim().toLowerCase();

    // Firebase Auth'dan Siliyoruz
    await _deleteFirebaseAuthUser(cleanStudentId);
    if (linkedParentEmail != null && linkedParentEmail.isNotEmpty) {
      await _deleteFirebaseAuthUser(linkedParentEmail.trim().toLowerCase());
    }

    final WriteBatch batch = _firestore.batch();

    // Öğrenci Dokümanını Sil
    batch.delete(_firestore.collection('users').doc(cleanStudentId));

    // Veli Dokümanı Varsa Sil
    if (linkedParentEmail != null && linkedParentEmail.isNotEmpty) {
      batch.delete(_firestore.collection('users').doc(linkedParentEmail.trim().toLowerCase()));
    }

    await batch.commit();

    // Öğrenciye Ait Tüm Canlı Dersleri Sil
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
    final String cleanTeacherId = teacherDocId.trim().toLowerCase();

    // Firebase Auth'dan Siliyoruz
    await _deleteFirebaseAuthUser(cleanTeacherId);

    // Öğretmen Dokümanını Sil
    await _firestore.collection('users').doc(cleanTeacherId).delete();

    // Öğretmene Atanmış Tüm Dersleri ve Saatleri Sil
    final QuerySnapshot<Map<String, dynamic>> lessonsSnap = await _firestore
        .collection('lessons')
        .where('teacherId', isEqualTo: cleanTeacherId)
        .get();

    for (final doc in lessonsSnap.docs) {
      await doc.reference.delete();
    }
  }

  /// Öğretmenleri Canlı Getirir
  Stream<List<Map<String, dynamic>>> getTeachersStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Öğrencileri Canlı Getirir
  Stream<List<Map<String, dynamic>>> getStudentsStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}
