import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../widgets/parent/parent_feedback_tab.dart';
import '../widgets/parent/parent_payment_tab.dart';
import '../widgets/parent/parent_schedule_tab.dart';
import '../widgets/parent/parent_teacher_zoom_tab.dart';

class ParentDashboardScreen extends StatefulWidget {
  final String parentName;
  final String? parentEmail;

  const ParentDashboardScreen({
    super.key,
    required this.parentName,
    this.parentEmail,
  });

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthRepository _authRepository = AuthRepository();

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandOrange = Color(0xFFFF7A59);
  static const Color brandYellow = Color(0xFFFFD43B);
  static const Color brandDark = Color(0xFF2C3E50);

  Map<String, dynamic>? _parentProfileData;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadParentProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadParentProfile() async {
    final String emailOrUid = widget.parentEmail ?? _authRepository.currentUser?.email ?? '';
    if (emailOrUid.isNotEmpty) {
      final doc = await _authRepository.getUserProfile(emailOrUid);
      if (doc.exists && mounted) {
        setState(() {
          _parentProfileData = doc.data();
          _isLoadingProfile = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingProfile = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = _parentProfileData?['fullName'] ?? widget.parentName;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[brandPink, brandOrange, brandYellow],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Image.asset('assets/images/logo.png', height: 38, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.school, color: brandPink, size: 28)),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('${AppStrings.get("welcome")}, Sayın $displayName', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                          child: Text(AppStrings.get('parentPortal'), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),

                  DropdownButton<String>(
                    value: AppStrings.currentLang,
                    dropdownColor: Colors.white,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.language_rounded, color: Colors.white),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(value: 'tr', child: Text('🇹🇷 TR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DropdownMenuItem(value: 'en', child: Text('🇬🇧 ENG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                    onChanged: (String? newLang) async {
                      if (newLang != null) {
                        setState(() => AppStrings.currentLang = newLang);
                        final String email = widget.parentEmail ?? _authRepository.currentUser?.email ?? '';
                        if (email.isNotEmpty) {
                          await _authRepository.updateUserLanguage(email, newLang);
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 8),

                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 26),
                    onPressed: () async {
                      await _authRepository.signOut();
                      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
                    },
                  ),
                ],
              ),
            ),

            _buildChildSummaryCard(),

            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: brandPink,
                unselectedLabelColor: Colors.grey,
                indicatorColor: brandPink,
                indicatorWeight: 3,
                tabs: const <Widget>[
                  Tab(icon: Icon(Icons.family_restroom_rounded), text: 'Öğretmen'),
                  Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Ders Programı'),
                  Tab(icon: Icon(Icons.auto_graph_rounded), text: 'Gelişim & Notlar'),
                  Tab(icon: Icon(Icons.credit_card_rounded), text: 'Ödeme & IBAN'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  ParentTeacherZoomTab(parentProfileData: _parentProfileData),
                  ParentScheduleTab(parentProfileData: _parentProfileData),
                  ParentFeedbackTab(parentProfileData: _parentProfileData),
                  ParentPaymentTab(parentProfileData: _parentProfileData),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildSummaryCard() {
    if (_isLoadingProfile) return const LinearProgressIndicator(color: brandPink);

    final String studentName = _parentProfileData?['linkedStudentName'] ?? 'Öğrenciniz';
    final String currentBook = _parentProfileData?['currentBook'] ?? 'Kids Box 2';
    final String currentUnit = _parentProfileData?['currentUnit'] ?? 'Unit 1 - Welcome';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: brandPink.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: brandPink.withOpacity(0.2)),
        ),
        child: Row(
          children: <Widget>[
            const CircleAvatar(radius: 22, backgroundColor: brandPink, child: Icon(Icons.child_care_rounded, color: Colors.white, size: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Öğrenci: $studentName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: brandDark)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Text('Kitap: $currentBook ($currentUnit)', style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
