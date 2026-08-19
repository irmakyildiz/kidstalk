import 'package:flutter/material.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../widgets/teacher/teacher_homework_tab.dart';
import '../widgets/teacher/teacher_profile_tab_widget.dart';
import '../widgets/teacher/teacher_request_tab.dart' hide TeacherHomeworkTab;
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

  String _displayName = '';
  String _zoomLink = 'https://zoom.us/j/123456789';
  String _selectedCountry = '🇬🇧 United Kingdom';

  @override
  void initState() {
    super.initState();
    _displayName = widget.teacherName;
    _tabController = TabController(length: 5, vsync: this);
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
        final String nameFromDb = (data?['fullName'] ?? data?['name'] ?? '').toString().trim();
        if (nameFromDb.isNotEmpty) {
          _displayName = nameFromDb;
        }
        _selectedCountry = data?['country'] ?? '🇬🇧 United Kingdom';
        _zoomLink = data?['zoomLink'] ?? 'https://zoom.us/j/123456789';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // HEADER BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 40,
                      errorBuilder: (_, __, ___) => const Icon(Icons.school, color: brandPink, size: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Welcome, $_displayName 🌍',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Teacher Portal',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                    tooltip: 'Logout',
                    onPressed: () async {
                      await _authRepository.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            // TAB BAR (5 TABS)
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: brandPink,
                unselectedLabelColor: Colors.grey,
                indicatorColor: brandPink,
                indicatorWeight: 3,
                tabs: const <Widget>[
                  Tab(icon: Icon(Icons.calendar_month_rounded, size: 20), text: 'My Schedule'),
                  Tab(icon: Icon(Icons.school_rounded, size: 20), text: 'My Students'),
                  Tab(icon: Icon(Icons.assignment_outlined, size: 20), text: 'Homework'),
                  Tab(icon: Icon(Icons.edit_note_rounded, size: 20), text: 'Create Request'),
                  Tab(icon: Icon(Icons.person_rounded, size: 20), text: 'My Profile'),
                ],
              ),
            ),

            // TAB VIEWS
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  TeacherScheduleTab(teacherId: widget.teacherId, teacherName: widget.teacherName, zoomLink: _zoomLink),
                  TeacherStudentsTab(teacherId: widget.teacherId, teacherName: widget.teacherName),
                  TeacherHomeworkTab(teacherId: widget.teacherId, teacherName: widget.teacherName),
                  TeacherRequestTab(teacherId: widget.teacherId, teacherName: widget.teacherName),
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
