import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_strings.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  static const List<String> adminEmails = <String>[
    'aybuke@kidstalkonline.com',
    'admin@kidstalk.com',
    'admin@kidstalkonline.com',
  ];

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// E-posta ve Şifre ile Giriş Yapma
  Future<UserCredential> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Esnek Kullanıcı Profil Getirici (UID veya E-Posta İle Sorgular)
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uidOrEmail) async {
    final String cleanId = uidOrEmail.trim().toLowerCase();

    // 1. Önce Doküman ID'si e-posta olan kayda bakar
    final DocumentSnapshot<Map<String, dynamic>> docById =
        await _firestore.collection('users').doc(cleanId).get();

    if (docById.exists) {
      final data = docById.data();
      if (data != null && data.containsKey('preferredLanguage')) {
        AppStrings.currentLang = data['preferredLanguage'] ?? 'tr';
      }
      return docById;
    }

    // 2. Bulamazsa UID ile arar
    final DocumentSnapshot<Map<String, dynamic>> docByUid =
        await _firestore.collection('users').doc(uidOrEmail).get();

    if (docByUid.exists) {
      final data = docByUid.data();
      if (data != null && data.containsKey('preferredLanguage')) {
        AppStrings.currentLang = data['preferredLanguage'] ?? 'tr';
      }
      return docByUid;
    }

    // 3. Bulamazsa 'email' alanına göre koleksiyonu sorgular
    final QuerySnapshot<Map<String, dynamic>> query = await _firestore
        .collection('users')
        .where('email', isEqualTo: cleanId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final data = doc.data();
      if (data.containsKey('preferredLanguage')) {
        AppStrings.currentLang = data['preferredLanguage'] ?? 'tr';
      }
      return doc;
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
    if (newPassword.trim() != confirmPassword.trim()) {
      throw AppStrings.tr('Yeni şifreler eşleşmiyor!');
    }
    if (newPassword.trim().length < 6) {
      throw AppStrings.tr('Şifreniz en az 6 karakter olmalıdır.');
    }

    final String cleanEmail = userEmail.trim().toLowerCase();

    // 1. Firebase Auth Üzerinde Güncelle
    final User? user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        await user.updatePassword(newPassword.trim());
      } catch (e) {
        print('Firebase Auth Şifre Güncelleme Bilgisi: $e');
      }
    }

    // 2. Firestore Dokümanında Kalıcı Sakla
    await _firestore.collection('users').doc(cleanEmail).set({
      'password': newPassword.trim(),
    }, SetOptions(merge: true));
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter kullanın.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi formatı.';
      default:
        return e.message ?? 'Bir hata oluştu.';
    }
  }
}
