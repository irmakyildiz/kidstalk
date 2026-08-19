import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/security_helper.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  static const List<String> adminEmails = <String>[
    'aybuke@kidstalkonline.com',
    'admin@kidstalk.com',
    'admin@kidstalkonline.com',
    'irmakyildiz2007@gmail.com',
    'irmakyildiz',
  ];

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// E-posta veya Kullanıcı Adı ve Şifre ile Giriş Yapma
  Future<UserCredential> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final String cleanInput = email.trim().toLowerCase().replaceAll(' ', '');
      String authEmail = cleanInput;

      if (!cleanInput.contains('@')) {
        // 1. Önce doğrudan doküman ID'si kullanıcı adı olan kayda bakılır
        final DocumentSnapshot<Map<String, dynamic>> userDoc =
            await _firestore.collection('users').doc(cleanInput).get();

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          authEmail = (data['authEmail'] as String?) ?? (data['email'] as String?) ?? '$cleanInput@kidstalk.online';
        } else {
          // 2. Bulunamazsa 'username' alanına göre sorgulanır
          final QuerySnapshot<Map<String, dynamic>> queryUsername = await _firestore
              .collection('users')
              .where('username', isEqualTo: cleanInput)
              .limit(1)
              .get();

          if (queryUsername.docs.isNotEmpty) {
            final data = queryUsername.docs.first.data();
            authEmail = (data['authEmail'] as String?) ?? (data['email'] as String?) ?? '$cleanInput@kidstalk.online';
          } else {
            // 3. Bulunamazsa 'studentUsername' alanına göre sorgulanır
            final QuerySnapshot<Map<String, dynamic>> queryStudent = await _firestore
                .collection('users')
                .where('studentUsername', isEqualTo: cleanInput)
                .limit(1)
                .get();

            if (queryStudent.docs.isNotEmpty) {
              final data = queryStudent.docs.first.data();
              authEmail = (data['authEmail'] as String?) ?? (data['email'] as String?) ?? '$cleanInput@kidstalk.online';
            } else {
              authEmail = '$cleanInput@kidstalk.online';
            }
          }
        }
      }

      final UserCredential credential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: authEmail,
        password: password.trim(),
      );

      // Başarılı girişte Firestore dokümanında güvenli SHA-256 hash'i sakla
      if (!cleanInput.contains('@')) {
        try {
          await _firestore.collection('users').doc(cleanInput).set({
            'passwordHash': SecurityHelper.hashPassword(password),
          }, SetOptions(merge: true));
        } catch (_) {}
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Esnek Kullanıcı Profil Getirici (UID, Kullanıcı Adı veya E-Posta İle Sorgular)
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uidOrEmail) async {
    final String cleanId = uidOrEmail.trim().toLowerCase().replaceAll(' ', '');

    // 1. Önce Doküman ID'si alan kayda bakılır
    final DocumentSnapshot<Map<String, dynamic>> docById =
        await _firestore.collection('users').doc(cleanId).get();

    if (docById.exists) {
      final data = docById.data();
      if (data != null && data.containsKey('preferredLanguage')) {
        AppStrings.currentLang = data['preferredLanguage'] ?? 'tr';
      }
      return docById;
    }

    // 2. 'username' alanına göre sorgulanır
    final QuerySnapshot<Map<String, dynamic>> queryUsername = await _firestore
        .collection('users')
        .where('username', isEqualTo: cleanId)
        .limit(1)
        .get();

    if (queryUsername.docs.isNotEmpty) {
      final doc = queryUsername.docs.first;
      if (doc.data().containsKey('preferredLanguage')) {
        AppStrings.currentLang = doc.data()['preferredLanguage'] ?? 'tr';
      }
      return doc;
    }

    // 3. 'email' alanına göre sorgulanır
    final QuerySnapshot<Map<String, dynamic>> queryEmail = await _firestore
        .collection('users')
        .where('email', isEqualTo: cleanId)
        .limit(1)
        .get();

    if (queryEmail.docs.isNotEmpty) {
      final doc = queryEmail.docs.first;
      if (doc.data().containsKey('preferredLanguage')) {
        AppStrings.currentLang = doc.data()['preferredLanguage'] ?? 'tr';
      }
      return doc;
    }

    // 4. 'authEmail' alanına göre sorgulanır
    final QuerySnapshot<Map<String, dynamic>> queryAuthEmail = await _firestore
        .collection('users')
        .where('authEmail', isEqualTo: cleanId)
        .limit(1)
        .get();

    if (queryAuthEmail.docs.isNotEmpty) {
      final doc = queryAuthEmail.docs.first;
      if (doc.data().containsKey('preferredLanguage')) {
        AppStrings.currentLang = doc.data()['preferredLanguage'] ?? 'tr';
      }
      return doc;
    }

    // 5. 'studentUsername' alanına göre sorgulanır
    final QuerySnapshot<Map<String, dynamic>> queryStudent = await _firestore
        .collection('users')
        .where('studentUsername', isEqualTo: cleanId)
        .limit(1)
        .get();

    if (queryStudent.docs.isNotEmpty) {
      final doc = queryStudent.docs.first;
      if (doc.data().containsKey('preferredLanguage')) {
        AppStrings.currentLang = doc.data()['preferredLanguage'] ?? 'tr';
      }
      return doc;
    }

    // 6. E-Posta adresinin @ öncesi kullanıcı adı köküne göre sorgulanır (örn: robyn@kidstalk.online -> robyn)
    if (cleanId.contains('@')) {
      final String prefix = cleanId.split('@').first;
      final DocumentSnapshot<Map<String, dynamic>> docByPrefix =
          await _firestore.collection('users').doc(prefix).get();
      if (docByPrefix.exists) {
        final data = docByPrefix.data();
        if (data != null && data.containsKey('preferredLanguage')) {
          AppStrings.currentLang = data['preferredLanguage'] ?? 'tr';
        }
        return docByPrefix;
      }

      final QuerySnapshot<Map<String, dynamic>> queryPrefix = await _firestore
          .collection('users')
          .where('username', isEqualTo: prefix)
          .limit(1)
          .get();

      if (queryPrefix.docs.isNotEmpty) {
        final doc = queryPrefix.docs.first;
        if (doc.data().containsKey('preferredLanguage')) {
          AppStrings.currentLang = doc.data()['preferredLanguage'] ?? 'tr';
        }
        return doc;
      }
    }

    return docById;
  }

  /// Kullanıcının Dil Tercihini Veritabanına Kaydeder
  Future<void> updateUserLanguage(String emailOrUid, String lang) async {
    AppStrings.currentLang = lang;
    final String cleanId = emailOrUid.trim().toLowerCase();

    try {
      await _firestore.collection('users').doc(cleanId).set({
        'preferredLanguage': lang,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Kullanıcının Şifresini Firebase Auth ve Firestore Üzerinde Kalıcı Günceller (2 Aşamalı Doğrulama)
  Future<void> updateUserPassword({
    required String userEmail,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final String cleanNew = newPassword.trim();
    final String cleanConf = confirmPassword.trim();

    if (cleanNew.isEmpty || cleanConf.isEmpty) {
      throw 'Lütfen yeni şifreyi ve doğrulamasını giriniz.';
    }
    if (cleanNew != cleanConf) {
      throw 'Yeni şifreler birbiriyle eşleşmiyor!';
    }
    if (cleanNew.length < 6) {
      throw 'Şifreniz en az 6 karakter olmalıdır.';
    }

    final String cleanId = userEmail.trim().toLowerCase().replaceAll(' ', '');

    // 1. Firebase Auth Üzerinde Güncelle (Mevcut oturum açmış kullanıcı varsa)
    final User? user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        await user.updatePassword(cleanNew);
      } catch (e) {
        print('Firebase updatePassword error: $e');
      }
    }

    // 2. Firestore Dokümanında ve ilgili tüm kullanıcı kayıtlarında şifreyi güncelle
    final Map<String, dynamic> updateData = {
      'password': cleanNew,
      'rawPassword': cleanNew,
      'passwordHash': SecurityHelper.hashPassword(cleanNew),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // a) Doğrudan cleanId dokümanı:
    await _firestore.collection('users').doc(cleanId).set(updateData, SetOptions(merge: true));

    // b) Eşleşen email, authEmail, username kayıtları:
    try {
      final queries = await Future.wait([
        _firestore.collection('users').where('email', isEqualTo: cleanId).get(),
        _firestore.collection('users').where('authEmail', isEqualTo: cleanId).get(),
        _firestore.collection('users').where('username', isEqualTo: cleanId).get(),
        _firestore.collection('users').where('studentUsername', isEqualTo: cleanId).get(),
      ]);

      final batch = _firestore.batch();
      for (final q in queries) {
        for (final doc in q.docs) {
          batch.set(doc.reference, updateData, SetOptions(merge: true));
        }
      }
      await batch.commit();
    } catch (_) {}
  }

  /// Kullanıcı Adı veya E-Posta İle Şifre Sıfırlama Bağlantısı Gönderir
  Future<String> sendPasswordReset({required String identifier}) async {
    final String rawInput = identifier.trim();
    final String cleanInput = rawInput.toLowerCase().replaceAll(' ', '');

    if (cleanInput.isEmpty) {
      throw 'Lütfen kullanıcı adınızı veya e-posta adresinizi giriniz.';
    }

    String targetEmail = '';

    if (cleanInput.contains('@')) {
      targetEmail = cleanInput;
    } else {
      // 1. Önce kullanıcı profilinden e-posta bul
      final profileDoc = await getUserProfile(rawInput);
      if (profileDoc.exists && profileDoc.data() != null) {
        final data = profileDoc.data()!;
        targetEmail = (data['linkedParentEmail'] as String?) ??
            (data['parentEmail'] as String?) ??
            (data['email'] as String?) ??
            (data['authEmail'] as String?) ??
            '';
      }

      // 2. Bulunamadıysa 'fullName' alanına göre sorgula
      if (targetEmail.isEmpty) {
        final queryFullName = await _firestore
            .collection('users')
            .where('fullName', isEqualTo: rawInput)
            .limit(1)
            .get();

        if (queryFullName.docs.isNotEmpty) {
          final data = queryFullName.docs.first.data();
          targetEmail = (data['linkedParentEmail'] as String?) ??
              (data['parentEmail'] as String?) ??
              (data['email'] as String?) ??
              (data['authEmail'] as String?) ??
              '';
        }
      }

      if (targetEmail.isEmpty || targetEmail.endsWith('@kidstalk.online')) {
        throw 'Bu kullanıcı hesabı için tanımlı gerçek bir veli e-posta adresi bulunamadı. Lütfen doğrudan e-posta adresinizi giriniz veya yöneticiniz ile iletişime geçiniz.';
      }
    }

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: targetEmail.trim());
      return targetEmail.trim();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        throw 'Kullanıcı bulunamadı. Lütfen size tanımlanan kullanıcı adını veya veli e-postasını girdiğinizden emin olun.';
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Şifre sıfırlama talebi iletilemedi: $e';
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Kullanıcı adı veya şifre yanlış.';
      case 'user-not-found':
      case 'invalid-email':
        return 'Kullanıcı Bulunamadı';
      case 'email-already-in-use':
        return 'Bu kullanıcı adı veya e-posta adresi zaten kullanımda.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter kullanın.';
      default:
        return 'Kullanıcı adı veya şifre yanlış.';
    }
  }
}
