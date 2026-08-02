import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../widgets/student/student_feedback_tab.dart';
import '../widgets/student/student_profile_tab.dart';
import '../widgets/student/student_schedule_tab.dart';
import '../widgets/student/student_zoom_tab.dart';

class StudentDashboardScreen extends StatefulWidget {
  final String studentName;
  final String? studentEmail;

  const StudentDashboardScreen({
    super.key,
    required this.studentName,
    this.studentEmail,
  });

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthRepository _authRepository = AuthRepository();

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandOrange = Color(0xFFFF7A59);
  static const Color brandYellow = Color(0xFFFFD43B);
  static const Color brandDark = Color(0xFF2C3E50);

  Map<String, dynamic>? _studentProfileData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStudentProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentProfile() async {
    final String emailOrUid = widget.studentEmail ?? _authRepository.currentUser?.email ?? '';
    if (emailOrUid.isNotEmpty) {
      final doc = await _authRepository.getUserProfile(emailOrUid);
      if (doc.exists && mounted) {
        setState(() {
          _studentProfileData = doc.data();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String cleanEmail = widget.studentEmail ?? _authRepository.currentUser?.email ?? '';
    final String displayName = _studentProfileData?['fullName'] ?? widget.studentName;

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
                        Text('${AppStrings.get("welcome")}, $displayName 👋', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                          child: Text(AppStrings.get('studentPortal'), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),

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

            _buildQuickStats(),

            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: brandPink,
                unselectedLabelColor: Colors.grey,
                indicatorColor: brandPink,
                indicatorWeight: 3,
                tabs: const <Widget>[
                  Tab(icon: Icon(Icons.video_call_rounded), text: 'Dersim & Zoom'),
                  Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Ders Programı'),
                  Tab(icon: Icon(Icons.auto_graph_rounded), text: 'Gelişim & Notlar'),
                  Tab(icon: Icon(Icons.settings_rounded), text: 'Profil & Güvenlik'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  StudentZoomTab(studentProfileData: _studentProfileData),
                  StudentScheduleTab(studentEmail: cleanEmail),
                  StudentFeedbackTab(studentEmail: cleanEmail),
                  StudentProfileTab(studentEmail: cleanEmail, onLanguageChanged: (lang) => setState(() => AppStrings.currentLang = lang)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final String currentBook = _studentProfileData?['currentBook'] ?? 'Kids Box 2';
    final String teacherName = _studentProfileData?['assignedTeacherName'] ?? 'Atanıyor...';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          _buildStatCard('İşlenen Kitap', currentBook, Icons.menu_book_rounded, Colors.green),
          const SizedBox(width: 10),
          _buildStatCard('Öğretmeniniz', teacherName, Icons.person_rounded, Colors.blue),
          const SizedBox(width: 10),
          _buildStatCard('Paket Tipi', 'Bireysel', Icons.star_rounded, Colors.amber),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                  Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: brandDark), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
