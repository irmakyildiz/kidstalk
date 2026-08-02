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
  static const Color brandOrange = Color(0xFFFF7A59);
  static const Color brandYellow = Color(0xFFFFD43B);
  static const Color brandDark = Color(0xFF2C3E50);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 850;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // SAĞ ÜST KÖŞE TR 🇹🇷 / ENG 🇬🇧 DİL DEĞİŞTİRİCİ
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, right: 20.0),
                child: _buildLanguageSelector(),
              ),
            ),
            
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: isDesktop ? 1020 : 460),
                    margin: const EdgeInsets.all(20),
                    child: Card(
                      elevation: 12,
                      shadowColor: Colors.black.withOpacity(0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      clipBehavior: Clip.antiAlias,
                      child: isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Expanded(child: _buildHeroSection()),
                                Expanded(child: _buildLoginForm()),
                              ],
                            )
                          : _buildLoginForm(),
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

  /// TR 🇹🇷 / ENG 🇬🇧 DİL DEĞİŞTİRİCİ BUTONU
  Widget _buildLanguageSelector() {
    final bool isTurkish = AppStrings.currentLang == 'tr';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InkWell(
            onTap: () {
              setState(() {
                AppStrings.currentLang = 'tr';
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isTurkish ? brandPink : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '🇹🇷 TR',
                style: TextStyle(
                  color: isTurkish ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () {
              setState(() {
                AppStrings.currentLang = 'en';
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: !isTurkish ? brandPink : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '🇬🇧 ENG',
                style: TextStyle(
                  color: !isTurkish ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[brandPink, brandOrange, brandYellow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.stars_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Kids Talk Online', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            AppStrings.currentLang == 'tr'
                ? 'Online İngilizce\nDers Platformu'
                : 'Online English\nLearning Platform',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.currentLang == 'tr'
                ? 'Öğretmen, Öğrenci ve Veli Bilgilerine Tek Ekrandan Erişin'
                : 'Access Teacher, Student and Parent Portals in One Place',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.95), height: 1.4),
          ),
          const SizedBox(height: 36),
          _buildFeatureItem(Icons.calendar_month_rounded, AppStrings.get('mySchedule')),
          const SizedBox(height: 14),
          _buildFeatureItem(Icons.verified_user_rounded, AppStrings.get('loginSubtitle')),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(36.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 75,
                fit: BoxFit.contain,
                errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                  return const Icon(Icons.school, size: 65, color: brandOrange);
                },
              ),
            ),
            const SizedBox(height: 14),
            Text(
              AppStrings.get('loginTitle'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.get('loginSubtitle'),
              style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              decoration: InputDecoration(
                labelText: AppStrings.get('emailHint'),
                hintText: 'ornek@kidstalk.com',
                prefixIcon: const Icon(Icons.email_outlined, color: brandPink),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) return AppStrings.get('emailHint');
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: InputDecoration(
                labelText: AppStrings.get('passwordHint'),
                prefixIcon: const Icon(Icons.lock_outline, color: brandOrange),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) return AppStrings.get('passwordHint');
                return null;
              },
            ),
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppStrings.get('forgotPassword'))),
                  );
                },
                child: Text(AppStrings.get('forgotPassword'), style: const TextStyle(color: brandPink, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 20),

            Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[brandPink, brandOrange, brandYellow],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: <BoxShadow>[
                  BoxShadow(color: brandPink.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(AppStrings.get('loginButton'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final credential = await _authRepository.loginWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final user = credential.user;
      if (user != null && mounted) {
        final String userEmail = user.email ?? _emailController.text.trim().toLowerCase();

        // KULLANICI E-POSTASI İLE VERİTABANI PROFİLİ OKUNUR (VELİ / ÖĞRENCİ / ÖĞRETMEN):
        final profileDoc = await _authRepository.getUserProfile(userEmail);
        final String role = profileDoc.data()?['role'] ?? 'student';
        final String fullName = profileDoc.data()?['fullName'] ?? 'Kullanıcı';

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (BuildContext context) => HomeScreen(
                role: role,
                fullName: fullName,
                email: userEmail,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
