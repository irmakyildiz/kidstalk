import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../widgets/teacher/teacher_profile_tab_widget.dart';
import '../widgets/teacher/teacher_request_tab.dart';
import '../widgets/teacher/teacher_schedule_tab.dart';
import '../widgets/teacher/teacher_students_tab.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const TeacherDashboardScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthRepository _authRepository = AuthRepository();

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandOrange = Color(0xFFFF7A59);
  static const Color brandYellow = Color(0xFFFFD43B);

  String _selectedCountry = '🇬🇧 United Kingdom';
  String _zoomLink = 'https://zoom.us/j/123456789';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTeacherProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherProfile() async {
    final doc = await _authRepository.getUserProfile(widget.teacherId);
    if (doc.exists && mounted) {
      final data = doc.data();
      setState(() {
        _selectedCountry = data?['country'] as String? ?? '🇬🇧 United Kingdom';
        _zoomLink = data?['zoomLink'] as String? ?? 'https://zoom.us/j/123456789';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String flag = _selectedCountry.split(' ').first;

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
                        Text('${AppStrings.tr("Hoş Geldiniz")}, ${widget.teacherName} $flag', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                          child: Text(AppStrings.tr('Öğretmen Paneli'), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
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
                        await _authRepository.updateUserLanguage(widget.teacherId, newLang);
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

            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: brandPink,
                unselectedLabelColor: Colors.grey,
                indicatorColor: brandPink,
                indicatorWeight: 3,
                tabs: <Widget>[
                  Tab(icon: const Icon(Icons.calendar_month_rounded), text: AppStrings.tr('Ders Programım')),
                  Tab(icon: const Icon(Icons.school_rounded), text: AppStrings.tr('Öğrencilerim')),
                  Tab(icon: const Icon(Icons.edit_note_rounded), text: AppStrings.tr('Talep Oluştur')),
                  Tab(icon: const Icon(Icons.person_rounded), text: AppStrings.tr('Profilim')),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  TeacherScheduleTab(teacherId: widget.teacherId, teacherName: widget.teacherName, zoomLink: _zoomLink),
                  TeacherStudentsTab(teacherName: widget.teacherName),
                  const TeacherRequestTab(),
                  TeacherProfileTabWidget(
                    teacherId: widget.teacherId,
                    teacherName: widget.teacherName,
                    currentCountry: _selectedCountry,
                    currentZoomLink: _zoomLink,
                    onProfileSaved: (country, zoom) => setState(() {
                      _selectedCountry = country;
                      _zoomLink = zoom;
                    }),
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
