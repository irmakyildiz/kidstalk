import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../widgets/student/student_feedback_tab.dart';
import '../widgets/student/student_profile_tab.dart';
import '../widgets/student/student_schedule_tab.dart';

class ParentDashboardScreen extends StatefulWidget {
  final String parentEmail;
  final String parentName;
  final String? loggedInStudentId;
  final String? initialStudentId;

  const ParentDashboardScreen({
    super.key,
    required this.parentEmail,
    required this.parentName,
    this.loggedInStudentId,
    this.initialStudentId,
  });

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthRepository _authRepository = AuthRepository();

  String? _activeStudentId;
  String _activeStudentName = '';
  String _assignedTeacher = '';
  String _currentBook = '';
  Map<String, dynamic>? _activeStudentData;
  List<Map<String, dynamic>> _siblings = [];

  static const Color brandPink = Color(0xFFFF3366);
  static const Color brandOrange = Color(0xFFFF6F43);
  static const Color brandYellow = Color(0xFFFFB800);
  static const Color brandDark = Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSiblingsAndActiveStudent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSiblingsAndActiveStudent() async {
    String searchEmail = widget.parentEmail.trim().toLowerCase();
    final String targetStudentId = (widget.loggedInStudentId ?? widget.initialStudentId ?? searchEmail).trim().toLowerCase();

    // 1. Eğer bir öğrenci kullanıcı adı veya kimliği ile giriş yapılmışsa, o öğrencinin veli e-postasını bulalım:
    if (targetStudentId.isNotEmpty) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(targetStudentId).get();
      if (userDoc.exists) {
        final uData = userDoc.data() ?? {};
        final pEmail = (uData['parentEmail'] ?? uData['linkedParentEmail'] ?? '').toString().trim().toLowerCase();
        if (pEmail.isNotEmpty) {
          searchEmail = pEmail;
        }
      }
    }

    // 2. Tüm öğrencileri tarayıp aynı veli e-postasına (parentEmail) sahip olan tüm kardeşleri bulalım:
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', whereIn: ['student', 'parent_student'])
        .get();

    final matched = snap.docs.where((doc) {
      final data = doc.data();
      final pEmail = (data['parentEmail'] ?? data['email'] ?? '').toString().toLowerCase().trim();
      final linkedEmail = (data['linkedParentEmail'] ?? '').toString().toLowerCase().trim();
      final docId = doc.id.toLowerCase().trim();
      return pEmail == searchEmail || linkedEmail == searchEmail || docId == searchEmail || (searchEmail.isEmpty && docId == targetStudentId);
    }).map((doc) => {'id': doc.id, ...doc.data()}).toList();

    if (matched.isEmpty && targetStudentId.isNotEmpty) {
      final singleDoc = await FirebaseFirestore.instance.collection('users').doc(targetStudentId).get();
      if (singleDoc.exists) {
        matched.add({'id': singleDoc.id, ...singleDoc.data()!});
      }
    }

    if (mounted) {
      setState(() {
        _siblings = matched;
        
        // Giriş yapan öğrenciyi veya ilk öğrenciyi seç
        Map<String, dynamic>? selected;
        if (targetStudentId.isNotEmpty) {
          try {
            selected = matched.firstWhere((s) => s['id'].toString().toLowerCase() == targetStudentId);
          } catch (_) {}
        }
        selected ??= matched.isNotEmpty ? matched.first : null;

        if (selected != null) {
          _activeStudentId = selected['id'];
          _activeStudentName = selected['fullName'] ?? selected['studentName'] ?? selected['name'] ?? 'Öğrenci';
          _assignedTeacher = selected['assignedTeacherName'] ?? selected['teacherName'] ?? 'Robin';
          _currentBook = selected['currentBook'] ?? 'Kids Box';
          _activeStudentData = selected;
        }
      });
    }
  }

  void _switchStudent(Map<String, dynamic> student) {
    setState(() {
      _activeStudentId = student['id'];
      _activeStudentName = student['fullName'] ?? student['studentName'] ?? student['name'] ?? 'Öğrenci';
      _assignedTeacher = student['assignedTeacherName'] ?? student['teacherName'] ?? 'Robin';
      _currentBook = student['currentBook'] ?? 'Kids Box';
      _activeStudentData = student;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String resolvedParentName = (_activeStudentData?['parentName'] != null &&
            _activeStudentData!['parentName'].toString().trim().isNotEmpty &&
            _activeStudentData!['parentName'].toString().trim() != 'Belirtilmedi')
        ? _activeStudentData!['parentName'].toString().trim()
        : (widget.parentName.isNotEmpty ? widget.parentName : (_activeStudentName.isNotEmpty ? _activeStudentName : 'Veli'));

    final String targetLookupId = (_activeStudentId ?? widget.loggedInStudentId ?? widget.parentEmail).trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // HEADER BAR (GRADIENT)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFFFF3366), Color(0xFFFF6F43), Color(0xFFFFB800)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
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
                      Text('Hoş Geldiniz, Sayın $resolvedParentName', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                        child: const Text('Veli & Öğrenci Portalı', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // AKTİF ÖĞRENCİ SEÇİCİ (KARDEŞLER)
                  if (_siblings.length > 1)
                    PopupMenuButton<Map<String, dynamic>>(
                      onSelected: _switchStudent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      offset: const Offset(0, 50),
                      itemBuilder: (context) {
                        return _siblings.map((s) {
                          final name = s['fullName'] ?? s['studentName'] ?? s['name'] ?? s['id'];
                          final isSelected = s['id'] == _activeStudentId;
                          return PopupMenuItem<Map<String, dynamic>>(
                            value: s,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.grey.shade200 : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: <Widget>[
                                  const Text('🧒 ', style: TextStyle(fontSize: 16)),
                                  Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                                ],
                              ),
                            ),
                          );
                        }).toList();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text('👥 Aktif Öğrenci: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: brandDark)),
                            const Text('🧒 ', style: TextStyle(fontSize: 14)),
                            Text(_activeStudentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: brandDark)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down_rounded, color: brandPink, size: 20),
                          ],
                        ),
                      ),
                    )
                  else if (_activeStudentName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Text('👥 Aktif Öğrenci: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: brandDark)),
                          const Text('🧒 ', style: TextStyle(fontSize: 14)),
                          Text(_activeStudentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: brandDark)),
                        ],
                      ),
                    ),

                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                    tooltip: 'Çıkış Yap',
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

            // SUB-HEADER: ÖĞRENCİ VE KİTAP BİLGİ KARTI
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F3),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFDDE5), width: 1.2),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: brandPink, shape: BoxShape.circle),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Öğrenci: $_activeStudentName • Öğretmen: $_assignedTeacher',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1F5FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Kitap: $_currentBook',
                            style: const TextStyle(color: Color(0xFF0984E3), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // TAB BAR
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: TabBar(
                controller: _tabController,
                labelColor: brandPink,
                unselectedLabelColor: Colors.grey,
                indicatorColor: brandPink,
                indicatorWeight: 3,
                tabs: const <Widget>[
                  Tab(icon: Icon(Icons.calendar_month_rounded, size: 20), text: 'Ders Programı'),
                  Tab(icon: Icon(Icons.assignment_outlined, size: 20), text: 'Ödevler'),
                  Tab(icon: Icon(Icons.auto_awesome_rounded, size: 20), text: 'Gelişim & Notlar'),
                  Tab(icon: Icon(Icons.credit_card_rounded, size: 20), text: 'Ödeme & IBAN'),
                ],
              ),
            ),

            // TAB VIEWS
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  StudentScheduleTab(studentEmail: targetLookupId),
                  StudentHomeworkTab(studentEmail: targetLookupId, studentName: _activeStudentName),
                  StudentFeedbackTab(studentEmail: targetLookupId),
                  StudentProfileTab(
                    studentEmail: targetLookupId,
                    studentProfileData: _activeStudentData,
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
