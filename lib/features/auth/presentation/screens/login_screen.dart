import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../dashboard/presentation/screens/home_screen.dart';
import '../../data/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthRepository _authRepository = AuthRepository();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandOrange = Color(0xFFFF9F43);
  static const Color brandYellow = Color(0xFFFFD43B);
  static const Color brandDark = Color(0xFF2C3E50);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String input = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      final credential = await _authRepository.loginWithEmailAndPassword(
        email: input,
        password: password,
      );

      // Profil arama: Önce kullanıcının girdiği kullanıcı adı/email ile, sonra credential.user?.email ile
      DocumentSnapshot<Map<String, dynamic>> profileDoc = await _authRepository.getUserProfile(input);
      if (!profileDoc.exists && credential.user?.email != null) {
        profileDoc = await _authRepository.getUserProfile(credential.user!.email!);
      }
      if (!profileDoc.exists && credential.user?.uid != null) {
        profileDoc = await _authRepository.getUserProfile(credential.user!.uid);
      }

      Map<String, dynamic> profile = profileDoc.data() ?? <String, dynamic>{};

      // Gerekirse users koleksiyonunda kapsamlı eşleşme kontrolü
      if (profile.isEmpty) {
        final snap = await FirebaseFirestore.instance.collection('users').get();
        final cleanInput = input.toLowerCase().replaceAll(' ', '');
        for (final doc in snap.docs) {
          final data = doc.data();
          final dId = doc.id.toLowerCase();
          final uName = (data['username'] ?? '').toString().toLowerCase();
          final stUName = (data['studentUsername'] ?? '').toString().toLowerCase();
          final eMail = (data['email'] ?? '').toString().toLowerCase();
          final aMail = (data['authEmail'] ?? '').toString().toLowerCase();
          final pMail = (data['parentEmail'] ?? '').toString().toLowerCase();

          if (dId == cleanInput || uName == cleanInput || stUName == cleanInput ||
              eMail == cleanInput || aMail == cleanInput || pMail == cleanInput) {
            profileDoc = doc;
            profile = data;
            break;
          }
        }
      }

      String role = (profile['role'] as String? ?? '').toLowerCase().trim();
      if (role.isEmpty) {
        if (AuthRepository.adminEmails.contains(input.toLowerCase()) ||
            AuthRepository.adminEmails.contains(credential.user?.email?.toLowerCase() ?? '')) {
          role = 'admin';
        } else if (profile.containsKey('zoomLink') || profile.containsKey('bankAccount') || profile.containsKey('iban')) {
          role = 'teacher';
        } else {
          role = 'student';
        }
      }

      final String name = (profile['fullName'] ?? profile['name'] ?? profile['parentName'] ?? input).toString();
      final String email = (profile['email'] ?? credential.user?.email ?? input).toString();
      final String exactId = profileDoc.id.isNotEmpty ? profileDoc.id : (profile['username'] ?? profile['uid'] ?? input);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            role: role,
            fullName: name,
            email: email,
            loggedInStudentId: exactId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final bool isTr = AppStrings.currentLang == 'tr';
    final TextEditingController resetEmailController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isTr ? 'Şifremi Unuttum' : 'Forgot Password',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: brandDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              isTr
                  ? 'Lütfen sistemde kayıtlı e-posta adresinizi veya kullanıcı adınızı giriniz. Sıfırlama bağlantısı iletilecektir.'
                  : 'Please enter your registered username or email address. A reset link will be sent.',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              decoration: InputDecoration(
                labelText: isTr ? 'Kullanıcı Adı veya E-Posta' : 'Username or Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isTr ? 'İptal' : 'Cancel', style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandPink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final input = resetEmailController.text.trim();
              if (input.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isTr ? 'Lütfen kullanıcı adı veya e-posta giriniz.' : 'Please enter username or email.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isTr
                        ? 'Şifre sıfırlama talebiniz yöneticiye iletildi. Lütfen yöneticiniz ile iletişime geçiniz.'
                        : 'Your password reset request has been submitted to the admin.',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(isTr ? 'Gönder' : 'Send', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final bool isDesktop = screenWidth >= 950;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0, right: 28.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      GestureDetector(
                        onTap: () => setState(() => AppStrings.currentLang = 'tr'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppStrings.currentLang == 'tr' ? brandPink : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '🇹🇷 TR',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppStrings.currentLang == 'tr' ? Colors.white : brandDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() => AppStrings.currentLang = 'en'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppStrings.currentLang == 'en' ? brandPink : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '🇬🇧 ENG',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppStrings.currentLang == 'en' ? Colors.white : brandDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 16,
                    vertical: isDesktop ? 24 : 16,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1160 : 500,
                      minHeight: isDesktop ? 580 : 0,
                    ),
                    child: Card(
                      elevation: 20,
                      shadowColor: brandPink.withOpacity(0.12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      clipBehavior: Clip.antiAlias,
                      child: isDesktop
                          ? IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Expanded(flex: 5, child: _buildHeroSection(isDesktop)),
                                  Expanded(flex: 5, child: _buildLoginForm(isDesktop)),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                _buildMobileBanner(),
                                _buildLoginForm(isDesktop),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileBanner() {
    final bool isTr = AppStrings.currentLang == 'tr';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[brandPink, brandOrange, brandYellow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              height: 40,
              errorBuilder: (_, __, ___) => const Icon(Icons.school, color: brandPink, size: 36),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'KIDS TALK ONLINE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isTr ? 'YÖNETİM VE BİLGİ SİSTEMİ' : 'MANAGEMENT & INFORMATION SYSTEM',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isDesktop) {
    final bool isTr = AppStrings.currentLang == 'tr';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 52),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[brandPink, brandOrange, brandYellow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Image.asset(
              'assets/images/logo.png',
              height: 64,
              errorBuilder: (_, __, ___) => const Icon(Icons.school, color: brandPink, size: 54),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.stars_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text('Kids Talk Online', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'KIDS TALK ONLINE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isTr ? 'YÖNETİM VE BİLGİ SİSTEMİ' : 'MANAGEMENT & INFORMATION SYSTEM',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isTr
                ? 'İngilizce dersinize dair tüm bilgilerinize tek yerden erişin.'
                : 'Access all information regarding your English classes from one place.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 36),

          _buildHeroFeature(
            Icons.calendar_month_rounded,
            isTr ? 'Size Özel Hazırlanan Ders Programınıza Hızlı Erişim' : 'Fast Access to Your Personalized Class Schedule',
          ),
          const SizedBox(height: 16),
          _buildHeroFeature(
            Icons.verified_user_rounded,
            isTr ? 'Size İletilen Kullanıcı Adı ve Şifre İle Giriş Yapın' : 'Log in with the username and password provided to you.',
          ),
        ],
      ),
    );
  }

  Widget _buildHeroFeature(IconData icon, String text) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isDesktop) {
    final bool isTr = AppStrings.currentLang == 'tr';

    return Container(
      color: const Color(0xFFFFF7F8),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 54.0 : 28.0,
        vertical: isDesktop ? 48.0 : 32.0,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/images/logo.png',
              height: isDesktop ? 68 : 52,
              errorBuilder: (_, __, ___) => const Icon(Icons.school, color: brandPink, size: 48),
            ),
            const SizedBox(height: 14),
            Text(
              isTr ? 'Giriş Yap' : 'Log In',
              style: TextStyle(
                fontSize: isDesktop ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: brandDark,
              ),
            ),
            SizedBox(height: isDesktop ? 36 : 24),

            TextFormField(
              controller: _emailController,
              style: const TextStyle(fontSize: 14, color: brandDark),
              decoration: InputDecoration(
                labelText: isTr ? 'Kullanıcı Adı' : 'Username',
                labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 13),
                floatingLabelStyle: const TextStyle(color: Color(0xFF8B2B43), fontSize: 12, fontWeight: FontWeight.bold),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                prefixIcon: const Icon(Icons.person_outline_rounded, color: brandPink, size: 22),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: isDesktop ? 16 : 14, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF7A7A7A), width: 1.0)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF7A7A7A), width: 1.0)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF8B2B43), width: 1.5)),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? (isTr ? 'Lütfen kullanıcı adınızı giriniz' : 'Please enter your username') : null,
            ),
            SizedBox(height: isDesktop ? 20 : 16),

            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              style: const TextStyle(fontSize: 14, color: brandDark),
              decoration: InputDecoration(
                labelText: isTr ? 'Şifre' : 'Password',
                labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 13),
                floatingLabelStyle: const TextStyle(color: Color(0xFF8B2B43), fontSize: 12, fontWeight: FontWeight.bold),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: brandOrange, size: 22),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey,
                    size: 22,
                  ),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: isDesktop ? 16 : 14, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF7A7A7A), width: 1.0)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF7A7A7A), width: 1.0)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF8B2B43), width: 1.5)),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? (isTr ? 'Lütfen şifrenizi giriniz' : 'Please enter your password') : null,
              onFieldSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: Text(
                  isTr ? 'Şifremi Unuttum' : 'Forgot Password',
                  style: const TextStyle(color: brandPink, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            SizedBox(height: isDesktop ? 20 : 16),

            SizedBox(
              width: double.infinity,
              height: isDesktop ? 50 : 46,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFFFF3366), Color(0xFFFF6F43), Color(0xFFFFB800)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: brandPink.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          isTr ? 'Giriş Yap' : 'Log In',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isDesktop ? 16 : 15),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
