import 'package:cloud_firestore/cloud_firestore.dart';
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

  static const Color brandPink = Color(0xFFFF3366);
  static const Color brandOrange = Color(0xFFFF6F43);
  static const Color brandYellow = Color(0xFFFFB800);
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
    final String cleanEmail = (widget.studentEmail ?? _authRepository.currentUser?.email ?? '').trim().toLowerCase();
    final String displayName = (_studentProfileData?['fullName'] ?? widget.studentName).toString().trim();
    final String parentName = (_studentProfileData?['parentName'] ?? '').toString().trim();
    final String teacherName = (_studentProfileData?['assignedTeacherName'] ?? _studentProfileData?['teacherName'] ?? 'Robin').toString().trim();
    final String currentBook = (_studentProfileData?['currentBook'] ?? 'Kids Box (1-Welcome)').toString().trim();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // HEADER BAR (GRADIENT)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                        Text(
                          'Hoş Geldiniz, Sayın ${parentName.isNotEmpty ? parentName : displayName}',
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                          child: const Text('Veli & Öğrenci Portalı', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),

                  // AKTİF ÖĞRENCİ SEÇİCİ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.people_alt_rounded, color: Color(0xFFFF5286), size: 16),
                        const SizedBox(width: 6),
                        const Text('Aktif Öğrenci: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brandDark)),
                        const Icon(Icons.face_rounded, color: Color(0xFFFF7A59), size: 16),
                        const SizedBox(width: 4),
                        Text(displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brandDark)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

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

            // TOP STUDENT INFO BANNER (MATCHING SCREENSHOT 1, 2, 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFDDE5), width: 1.2),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: brandPink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Öğrenci: $displayName • Öğretmen: $teacherName',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE1F5FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Kitap: $currentBook',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0984E3)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4 TABS (DERS PROGRAMI, ÖDEVLER, GELİŞİM & NOTLAR, ÖDEME & IBAN)
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: cleanEmail.isNotEmpty
                  ? FirebaseFirestore.instance.collection('homeworks').where('studentId', isEqualTo: cleanEmail).snapshots()
                  : FirebaseFirestore.instance.collection('homeworks').snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                int unreadCount = 0;
                for (final d in docs) {
                  final data = d.data();
                  final bool isRead = data['isRead'] as bool? ?? false;
                  if (!isRead) {
                    unreadCount++;
                  }
                }

                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1.0)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: brandPink,
                    unselectedLabelColor: const Color(0xFF757575),
                    indicatorColor: brandPink,
                    indicatorWeight: 3,
                    tabs: <Widget>[
                      const Tab(
                        icon: Icon(Icons.calendar_month_rounded, size: 20),
                        child: Text('Ders Programı', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      Tab(
                        icon: Badge(
                          isLabelVisible: unreadCount > 0,
                          label: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                          backgroundColor: Colors.redAccent,
                          child: const Icon(Icons.assignment_rounded, size: 20),
                        ),
                        child: const Text('Ödevler', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const Tab(
                        icon: Icon(Icons.auto_awesome_rounded, size: 20),
                        child: Text('Gelişim & Notlar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const Tab(
                        icon: Icon(Icons.credit_card_rounded, size: 20),
                        child: Text('Ödeme & IBAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  StudentScheduleTab(studentEmail: cleanEmail),
                  StudentHomeworkTab(studentEmail: cleanEmail, studentName: displayName),
                  StudentFeedbackTab(studentEmail: cleanEmail),
                  StudentProfileTab(
                    studentEmail: cleanEmail,
                    studentProfileData: _studentProfileData,
                    onLanguageChanged: (lang) => setState(() => AppStrings.currentLang = lang),
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
